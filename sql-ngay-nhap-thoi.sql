-- ============================================================
-- AVATAR — Thêm Ngày nhập học + Ngày thôi học vào hồ sơ học sinh
-- Dán toàn bộ nội dung này vào Supabase → SQL Editor → bấm "Run".
-- An toàn chạy nhiều lần (dùng IF NOT EXISTS). Không xóa dữ liệu cũ.
-- ============================================================

-- Ngày nhập học (mốc học sinh bắt đầu vào học)
alter table public.hoc_vien add column if not exists ngay_nhap_hoc  date;

-- Ngày thôi học: có giá trị => học sinh đã thôi học (giữ hồ sơ, không xóa)
alter table public.hoc_vien add column if not exists ngay_thoi_hoc  date;

-- Lý do thôi học: Hết khóa / Chuyển trường / Nghỉ hẳn / Khác
alter table public.hoc_vien add column if not exists ly_do_thoi_hoc text;

-- (Phòng trường hợp chưa chạy file cũ) Ngày đóng học phí
alter table public.hoc_vien add column if not exists ngay_dong      date;

-- ============================================================
-- XONG. Bấm "Run". Sau đó vào web bấm Ctrl+F5 để tải lại.
-- ============================================================
