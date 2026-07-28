-- ============================================================
-- AVATAR — Thêm "Ngày đóng học phí" cho học sinh
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại.
-- ============================================================

alter table public.hoc_vien
  add column if not exists ngay_dong date;

-- ============================================================
-- XONG. Bấm Run. Sau đó tải lại web (Ctrl+F5).
-- ============================================================
