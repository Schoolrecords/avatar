-- ============================================================
-- AVATAR — Thêm "Ngày hợp đồng làm việc" cho hồ sơ giáo viên
-- Dán toàn bộ vào Supabase → SQL Editor → bấm "Run".
-- An toàn chạy nhiều lần (IF NOT EXISTS). Không xóa dữ liệu cũ.
-- ============================================================

-- Bảng giáo viên sống (Giai đoạn 2)
alter table public.giao_vien add column if not exists ngay_hd date;

-- Lớp chỉnh sửa đè lên data.js (khi chưa migrate) — giữ đồng bộ
alter table public.gv_edits  add column if not exists ngay_hd date;

-- ============================================================
-- XONG. Bấm "Run". Sau đó vào web bấm Ctrl+F5 để tải lại.
-- ============================================================
