-- ============================================================
-- AVATAR — Thêm "Số tiền đã đóng" cho học sinh (đóng học phí theo đợt)
-- Học phí (hoc_phi) tính CẢ KHÓA; phụ huynh có thể đóng trước một phần
-- (VD 200.000 / 300.000 trên 600.000). Cột so_tien_dong lưu số đã nộp.
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại.
-- ============================================================

-- 1) Thêm cột số tiền đã đóng
alter table public.hoc_vien
  add column if not exists so_tien_dong numeric default 0;

-- 2) Chuyển dữ liệu cũ: HS trước đây đánh dấu "đã đóng" (da_dong = true)
--    coi như đã đóng ĐỦ = học phí cả khóa. Chỉ cập nhật ô đang trống/0.
update public.hoc_vien
   set so_tien_dong = hoc_phi
 where da_dong is true
   and coalesce(so_tien_dong, 0) = 0;

-- ============================================================
-- XONG. Bấm Run. Sau đó tải lại web (Ctrl+F5).
-- ============================================================
