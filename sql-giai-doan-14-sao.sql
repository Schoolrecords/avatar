-- ============================================================
-- GIAI ĐOẠN 14: TÍCH SAO CHO HỌC SINH (16/10/2026)
--
-- Giáo viên chấm 0–3 sao cho từng em ngay trên màn Điểm danh.
-- Sao ghi THẲNG vào dòng điểm danh của buổi đó (bảng diem_danh_hv),
-- KHÔNG tạo bảng mới. Nhờ vậy:
--   · quyền đi theo điểm danh: GV chỉ chấm lớp mình, lễ tân cơ sở mình
--     (các policy dd_sel/dd_ins/dd_upd/dd_del giữ nguyên, không sửa gì);
--   · ca đã CHỐT thì sao cũng bị khóa (is_ca_chot như điểm danh);
--   · sao tính THEO KHÓA tự nhiên: mỗi dòng hoc_vien là một lượt ghi danh,
--     em lên khóa mới có hv_id mới nên sao khóa mới bắt đầu lại từ 0.
--
-- Chạy một lần trong Supabase → SQL Editor. Chạy lại lần hai không sao.
-- Chỉ THÊM cột, không sửa/xóa dữ liệu cũ. App bản cũ bỏ qua cột mới.
-- ============================================================

alter table public.diem_danh_hv add column if not exists sao       smallint not null default 0;
alter table public.diem_danh_hv add column if not exists sao_ly_do text;

-- Chỉ nhận 0..3 sao — chặn ngay ở máy chủ, không trông vào app
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'dd_sao_0_3') then
    alter table public.diem_danh_hv add constraint dd_sao_0_3 check (sao between 0 and 3);
  end if;
end $$;

-- Tra "em này được bao nhiêu sao" (hồ sơ học sinh). Chỉ đánh chỉ mục các
-- dòng CÓ sao nên chỉ mục rất nhỏ. Tra theo lớp đã có sẵn chỉ mục
-- unique (lop_id, ngay, hv_id).
create index if not exists dd_sao_hv_idx on public.diem_danh_hv(hv_id) where sao > 0;

-- Kiểm tra: phải thấy 2 dòng sao / sao_ly_do và số dòng có sao = 0
select column_name, data_type, column_default
  from information_schema.columns
 where table_schema = 'public' and table_name = 'diem_danh_hv' and column_name in ('sao','sao_ly_do');
select count(*) as so_dong_co_sao from public.diem_danh_hv where sao > 0;
