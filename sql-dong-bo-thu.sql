-- ============================================================
-- AVATAR — Đồng bộ "đã đóng học phí" với Sổ quỹ thu–chi
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại.
-- Thêm cột liên kết phiếu thu với học sinh (để tự tạo/xóa phiếu,
-- tránh trùng và cho phép hoàn tác khi bỏ đánh dấu đã đóng).
-- ============================================================

alter table public.so_quy
  add column if not exists hv_id bigint;

create index if not exists so_quy_hv_idx on public.so_quy(hv_id);

-- ============================================================
-- XONG. Bấm Run. Sau đó tải lại web (Ctrl+F5).
-- ============================================================
