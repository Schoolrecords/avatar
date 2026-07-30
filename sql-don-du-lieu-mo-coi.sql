-- ============================================================
-- AVATAR — DỌN BẢN GHI MỒ CÔI & KHÓA CHẶT Ở TẦNG CSDL
--
-- Vấn đề: xóa học sinh (hoặc xóa lớp) nhưng ĐIỂM DANH của em/lớp đó vẫn nằm
-- lại trong CSDL. Hậu quả: Bảng điều hành vẫn hiện "1/1 có mặt", "Chuyên cần
-- 100%", "1 buổi điểm danh hôm nay" của học sinh KHÔNG CÒN TỒN TẠI.
--
-- File này làm 2 việc:
--   (1) Dọn sạch các bản ghi mồ côi đang có.
--   (2) Thêm KHÓA NGOẠI + ON DELETE CASCADE để từ nay CSDL tự dọn,
--       không phụ thuộc vào app nhớ xóa hay không.
--
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại nhiều lần.
-- KHÔNG đụng tới sổ quỹ (tiền) — xem ghi chú ở mục 4.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Điểm danh của HỌC SINH đã bị xóa
-- ------------------------------------------------------------
delete from public.diem_danh_hv d
 where not exists (select 1 from public.hoc_vien h where h.id = d.hv_id);

-- ------------------------------------------------------------
-- 2) Điểm danh / chấm công / đối soát / lịch của LỚP đã bị xóa
--    (chỉ chạy phần này khi đã có bảng lop_hoc — tức đã chạy Giai đoạn 2)
-- ------------------------------------------------------------
do $$
begin
  if to_regclass('public.lop_hoc') is not null then
    delete from public.diem_danh_hv    x where not exists (select 1 from public.lop_hoc l where l.id = x.lop_id);
    delete from public.cham_cong_gv    x where not exists (select 1 from public.lop_hoc l where l.id = x.lop_id);
    delete from public.duyet_diem_danh x where not exists (select 1 from public.lop_hoc l where l.id = x.lop_id);
    if to_regclass('public.lich_lop') is not null then
      delete from public.lich_lop      x where not exists (select 1 from public.lop_hoc l where l.id = x.lop_id);
    end if;
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) Ca dạy RỖNG: đã tạo trạng thái đối soát nhưng không còn
--    điểm danh học sinh lẫn chấm công giáo viên nào (do đã xóa hết học sinh).
--    Để lại thì mục Đối soát hiện những ca "0/0 có mặt" vô nghĩa.
-- ------------------------------------------------------------
delete from public.duyet_diem_danh z
 where not exists (select 1 from public.diem_danh_hv d where d.lop_id = z.lop_id and d.ngay = z.ngay)
   and not exists (select 1 from public.cham_cong_gv c where c.lop_id = z.lop_id and c.ngay = z.ngay);

-- ------------------------------------------------------------
-- 4) KHÓA NGOẠI: xóa học sinh thì CSDL tự xóa điểm danh của em đó.
--    Từ nay lỗi này KHÔNG THỂ tái diễn, kể cả xóa bằng tay trên dashboard.
--
--    ⚠ CỐ Ý KHÔNG đặt khóa ngoại cho so_quy.hv_id: phiếu thu là CHỨNG TỪ KẾ TOÁN.
--      Nếu cascade, xóa một học sinh sẽ âm thầm xóa cả phiếu thu thuộc kỳ ĐÃ CHỐT SỔ,
--      vượt qua khóa kế toán. App vẫn xóa phiếu có kiểm soát và báo rõ phiếu nào
--      không xóa được.
-- ------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'dd_hv_fk') then
    alter table public.diem_danh_hv
      add constraint dd_hv_fk foreign key (hv_id)
      references public.hoc_vien(id) on delete cascade;
  end if;
end $$;

-- ------------------------------------------------------------
-- 5) Báo cáo kết quả — còn sót bản ghi mồ côi nào không?
--    Cả 3 số phải bằng 0.
-- ------------------------------------------------------------
select
  (select count(*) from public.diem_danh_hv d
     where not exists (select 1 from public.hoc_vien h where h.id = d.hv_id))            as diem_danh_mo_coi,
  (select count(*) from public.duyet_diem_danh z
     where not exists (select 1 from public.diem_danh_hv d where d.lop_id=z.lop_id and d.ngay=z.ngay)
       and not exists (select 1 from public.cham_cong_gv c where c.lop_id=z.lop_id and c.ngay=z.ngay)) as ca_rong,
  (select count(*) from pg_constraint where conname='dd_hv_fk')                          as da_khoa_ngoai;

-- ============================================================
-- XONG. Kết quả đúng phải là: 0 | 0 | 1
-- Sau đó tải lại web (Ctrl+F5).
-- ============================================================
