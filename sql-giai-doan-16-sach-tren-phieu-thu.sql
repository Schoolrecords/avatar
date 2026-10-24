-- ============================================================
-- GIAI ĐOẠN 16: TIỀN SÁCH TRÊN PHIẾU THU (24/10/2026)
--
-- Trung tâm báo: ghi nhận đóng tiền chỉ có học phí, nên phiếu thu
-- (hóa đơn) không có tiền sách; bảng lớp cũng thiếu cột Tiền sách.
--
-- Từ nay phụ huynh nộp học phí + sách một lần → MỘT phiếu thu gộp:
--   · so_tien   : tổng tiền nhận (học phí + sách)
--   · tien_sach : phần tiền sách nằm trong so_tien (cột MỚI)
-- Nộp riêng tiền sách → phiếu hạng mục "Tiền sách" (không cần cột này).
-- App tự lấy học phí đã đóng = so_tien − tien_sach.
--
-- Chạy một lần trong Supabase → SQL Editor. Chạy lại lần hai không sao.
-- Chỉ THÊM một cột (mặc định 0), không sửa/xóa phiếu cũ, không đụng
-- quy tắc quyền (RLS), không đụng bộ đánh số phiếu.
-- ============================================================

alter table public.so_quy add column if not exists tien_sach numeric not null default 0;

-- Kiểm tra: phải thấy 1 dòng tien_sach | numeric | 0
select column_name, data_type, column_default
  from information_schema.columns
 where table_schema = 'public' and table_name = 'so_quy' and column_name = 'tien_sach';
