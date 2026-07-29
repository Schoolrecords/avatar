-- ============================================================
-- AVATAR — XÓA DỮ LIỆU HỌC SINH (DEMO) CỦA 2 CƠ SỞ
--   • Diễn Liên = coso_id 0
--   • Diễn Hoa  = coso_id 9
--
-- GIỮ NGUYÊN: Diễn Đồng (coso_id 8) và MỌI cơ sở khác;
--             giáo viên, lớp, chấm công GV, thu–chi thủ công, tài khoản.
--
-- Phạm vi xóa: học sinh + điểm danh của các em + phiếu thu học phí
--              (tự sinh) của các em ở 2 cơ sở trên.
--
-- ⚠️ THAO TÁC NÀY KHÔNG HOÀN TÁC ĐƯỢC.
--    Làm 2 BƯỚC: chạy KHỐI 1 (xem trước) → đúng rồi mới chạy KHỐI 2.
-- ============================================================


-- ┌──────────────────────────────────────────────────────────┐
-- │ KHỐI 1 — XEM TRƯỚC (chỉ ĐẾM, KHÔNG xóa gì). Chạy khối này │
-- │ trước. Bôi đen từ đây tới hết KHỐI 1 rồi bấm Run.          │
-- └──────────────────────────────────────────────────────────┘
select 'HS sẽ xóa — Diễn Liên (0) + Diễn Hoa (9)' as muc,
       count(*) as so_dong from public.hoc_vien where coso_id in (0, 9)
union all
select 'Điểm danh HS sẽ xóa', count(*) from public.diem_danh_hv where coso_id in (0, 9)
union all
select 'Phiếu thu học phí (của HS) sẽ xóa',
       count(*) from public.so_quy where coso_id in (0, 9) and hv_id is not null
union all
select '>>> GIỮ NGUYÊN — HS Diễn Đồng (8)',
       count(*) from public.hoc_vien where coso_id = 8;

-- Xem thử 20 học sinh của 2 cơ sở sắp xóa (đối chiếu cho chắc là dữ liệu ảo):
select coso_id, ten, lop_id
  from public.hoc_vien
 where coso_id in (0, 9)
 order by coso_id, ten
 limit 20;


-- ┌──────────────────────────────────────────────────────────┐
-- │ KHỐI 2 — XÓA THẬT. CHỈ chạy sau khi KHỐI 1 đúng như ý.    │
-- │ Bôi đen từ dòng delete đầu tiên tới hết rồi bấm Run.      │
-- └──────────────────────────────────────────────────────────┘
delete from public.so_quy       where coso_id in (0, 9) and hv_id is not null;  -- phiếu thu HP tự sinh của các em
delete from public.diem_danh_hv where coso_id in (0, 9);                        -- điểm danh của các em
delete from public.hoc_vien     where coso_id in (0, 9);                        -- học sinh (dữ liệu demo)

-- (TÙY CHỌN) Nếu muốn xóa LUÔN trạng thái đối soát/chốt các ca và chấm công GV
--  của 2 cơ sở này (mặc định GIỮ theo yêu cầu) — bỏ dấu -- đầu 2 dòng dưới:
--   delete from public.duyet_diem_danh where coso_id in (0, 9);
--   delete from public.cham_cong_gv    where coso_id in (0, 9);


-- ============================================================
-- XONG. Vào web bấm Ctrl+F5 → số liệu Diễn Liên & Diễn Hoa về sạch;
-- Diễn Đồng và các cơ sở khác giữ nguyên. Mai nhập HS thật từ Excel.
-- ============================================================
