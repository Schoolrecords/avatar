-- ============================================================
-- AVATAR — Giai đoạn 10: ĐÁNH DẤU CƠ SỞ CHÍNH
--
-- Diễn Đồng là điểm chính của chuỗi nên phải luôn đứng ĐẦU ở mọi danh sách:
-- ô Phạm vi, trang Cơ sở, Lịch học, Lớp học, Học sinh, Giáo viên, Báo cáo…
-- và là cơ sở được chọn sẵn khi mở các trang có ô chọn cơ sở.
--
-- Làm bằng DỮ LIỆU (một cột đánh dấu) chứ không sửa cứng trong code — sau này
-- đổi cơ sở chính chỉ cần tích lại trên app, không phải nhờ kỹ thuật.
--
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại nhiều lần.
-- ============================================================

alter table public.co_so add column if not exists chinh boolean default false;

-- Diễn Đồng = mã 8 (mã cơ sở giữ nguyên từ đầu, xem data.js)
update public.co_so set chinh = false where chinh is true and id <> 8;
update public.co_so set chinh = true  where id = 8;

-- ------------------------------------------------------------
-- Kiểm tra
-- ------------------------------------------------------------
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='co_so' and column_name='chinh')  as da_co_cot_chinh,
  (select count(*) from public.co_so where chinh)                                as so_co_so_chinh,
  (select ten from public.co_so where chinh limit 1)                             as ten_co_so_chinh;

-- ============================================================
-- XONG. Kết quả đúng: 1 | 1 | Diễn Đồng
-- Sau đó tải lại web (Ctrl+F5).
--
-- Muốn đổi cơ sở chính sau này: vào app → Cơ sở → bấm vào cơ sở đó →
-- ✏️ Sửa cơ sở → tích "Cơ sở chính". Hệ thống tự bỏ dấu ở cơ sở cũ.
-- ============================================================
