-- ============================================================
-- AVATAR — Giai đoạn 1: SỐ LIỆU THẬT + REALTIME
-- Chạy 1 lần trong Supabase → SQL Editor → New query → Run.
-- An toàn khi chạy lại (không lỗi nếu đã chạy trước đó).
-- ============================================================

-- 1) Thêm cột đánh dấu "đã đóng học phí" cho từng học sinh
alter table public.hoc_vien
  add column if not exists da_dong boolean default false;

-- 2) Bật Realtime cho các bảng dữ liệu sống
--    (để mọi máy tự cập nhật khi một cơ sở lưu thay đổi)
do $$
declare t text;
begin
  foreach t in array array['hoc_vien','so_quy','diem_danh_hv','cham_cong_gv','gv_edits']
  loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when others then
      -- bảng đã nằm trong publication rồi → bỏ qua
      null;
    end;
  end loop;
end $$;

-- ============================================================
-- XONG. Bấm "Run". Sau đó tải lại trang web AVATAR (Ctrl+F5).
-- ============================================================
