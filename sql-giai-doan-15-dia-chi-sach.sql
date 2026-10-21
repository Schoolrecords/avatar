-- ============================================================
-- GIAI ĐOẠN 15: ĐỊA CHỈ HỌC SINH + TIỀN SÁCH (22/10/2026)
--
-- Trung tâm cần xuất hóa đơn cho học sinh nên phải có ĐỊA CHỈ,
-- và có thu thêm tiền tài liệu (SÁCH) cho từng lượt ghi danh.
--   · dia_chi   : địa chỉ của em (thông tin nhân thân, như phụ huynh/SĐT)
--   · tien_sach : tiền sách của lượt ghi danh này (mỗi khóa một số)
-- Tiền sách CHỈ GHI ĐỂ IN DANH SÁCH theo mẫu trung tâm
-- (Học phí + Sách = Tổng phí); KHÔNG cộng vào "phải thu / còn nợ".
--
-- Chạy một lần trong Supabase → SQL Editor. Chạy lại lần hai không sao.
-- Chỉ THÊM cột, không sửa/xóa dữ liệu cũ, không đụng quy tắc quyền (RLS):
-- ai xem/sửa được dòng học sinh thì xem/sửa được hai cột này.
-- ============================================================

alter table public.hoc_vien add column if not exists dia_chi   text;
alter table public.hoc_vien add column if not exists tien_sach numeric not null default 0;

-- Kiểm tra: phải thấy 2 dòng dia_chi / tien_sach
select column_name, data_type, column_default
  from information_schema.columns
 where table_schema = 'public' and table_name = 'hoc_vien' and column_name in ('dia_chi','tien_sach');
