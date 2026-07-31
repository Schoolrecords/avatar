-- ============================================================
-- AVATAR — GIAI ĐOẠN 11: QUYẾT TOÁN HỌC PHÍ KHI HỌC SINH THÔI HỌC
-- Chạy MỘT LẦN trong Supabase → SQL Editor → New query → Run.
-- An toàn: chỉ THÊM cột, không xóa, không sửa dữ liệu đang có.
-- KHÔNG chạy lại supabase-schema.sql và sql-giai-doan-2.sql.
-- ============================================================

-- Vì sao cần cột này:
--   Học sinh học 4 buổi rồi nghỉ, đã nộp học phí 4 buổi. Nếu vẫn treo học phí
--   CẢ KHÓA thì lớp bị nợ ảo phần em chưa học; nếu ẩn em đi thì tiền đã thu
--   biến mất khỏi bảng tổng phí (trong khi sổ quỹ vẫn có). Cột hoc_phi_chot lưu
--   SỐ PHẢI THU ĐÃ CHỐT tính đến ngày nghỉ — thường đúng bằng số đã đóng.
--   NULL = chưa chốt → app tự hiểu là "thu bao nhiêu, học bấy nhiêu".
alter table public.hoc_vien
  add column if not exists hoc_phi_chot numeric;

comment on column public.hoc_vien.hoc_phi_chot is
  'Học phí phải thu đã chốt khi cho thôi học (quyết toán tính đến ngày nghỉ). NULL = chưa chốt, app lấy đúng số đã đóng.';

-- Kiểm tra: câu dưới phải trả về 1 dòng
select column_name, data_type
from information_schema.columns
where table_schema='public' and table_name='hoc_vien' and column_name='hoc_phi_chot';
