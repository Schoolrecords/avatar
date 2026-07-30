-- ============================================================
-- AVATAR — Giai đoạn 9: MỖI BUỔI HỌC MỘT GIÁO VIÊN RIÊNG
--
-- Nhu cầu thật từ lễ tân: "1 lớp học 2 buổi, mỗi buổi học với 1 GV khác nhau
-- thì nhập vào lịch như nào ạ? Em phân công cho 2 GV dạy 1 lớp đó rồi ạ, mà
-- lên lịch vẫn không được ạ".
--
-- Trước đây: lop_hoc chỉ có MỘT gv_id, nên phân công người thứ hai là ghi đè
-- mất người thứ nhất. Lịch cũng không ghi được ai dạy buổi nào.
-- Nay: mỗi dòng lịch (lớp + thứ + ca) có gv_id riêng.
--   · Để TRỐNG  = buổi đó do giáo viên phụ trách lớp dạy (như cũ).
--   · Có gv_id  = buổi đó do người này dạy.
--
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại nhiều lần.
-- KHÔNG đụng tới dữ liệu điểm danh, học sinh hay sổ quỹ.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Thêm cột giáo viên cho từng buổi trong lịch
-- ------------------------------------------------------------
alter table public.lich_lop add column if not exists gv_id bigint;
create index if not exists ll_gv_idx on public.lich_lop(gv_id);

-- Cố ý KHÔNG điền sẵn: để trống nghĩa là "theo giáo viên phụ trách lớp".
-- Nhờ vậy sau này đổi giáo viên phụ trách thì mọi buổi chưa phân riêng tự đổi theo.

-- ------------------------------------------------------------
-- 2) Giáo viên phải XEM ĐƯỢC lớp mà mình chỉ dạy MỘT VÀI BUỔI
--
--    is_my_lop() trước đây chỉ xét lop_hoc.gv_id, nên giáo viên thứ hai của
--    lớp sẽ không thấy lớp đó trong Điểm danh / Lịch dạy — dù đã được phân
--    công dạy vài buổi. Nay xét thêm lich_lop.gv_id.
--
--    Hàm này được dùng lại trong RLS của hoc_vien, diem_danh_hv, cham_cong_gv,
--    duyet_diem_danh, lop_hoc, lich_lop — sửa ở đây là mọi nơi có hiệu lực.
-- ------------------------------------------------------------
create or replace function public.is_my_lop(p_lop_id int)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    -- là giáo viên phụ trách lớp
    select 1 from public.lop_hoc
     where id = p_lop_id and gv_id is not null and gv_id = public.my_gv_id()
  ) or exists(
    -- hoặc được phân công dạy ít nhất một buổi của lớp
    select 1 from public.lich_lop
     where lop_id = p_lop_id and gv_id is not null and gv_id = public.my_gv_id()
  )
$$;

-- ------------------------------------------------------------
-- 3) Kiểm tra
-- ------------------------------------------------------------
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='lich_lop' and column_name='gv_id')   as da_co_cot_gv_id,
  (select count(*) from public.lich_lop where gv_id is not null)                      as buoi_da_phan_gv_rieng,
  (select count(*) from public.lich_lop)                                              as tong_so_buoi;

-- ============================================================
-- XONG. Kết quả đúng: da_co_cot_gv_id = 1.
-- (buoi_da_phan_gv_rieng = 0 là bình thường — chưa ai phân riêng buổi nào.)
-- Sau đó tải lại web (Ctrl+F5).
--
-- CÁCH DÙNG: Lịch học → bấm vào lớp → tích các buổi → ở danh sách
-- "Các buổi đã chọn" bên dưới, mỗi buổi chọn giáo viên và phòng riêng.
-- ============================================================
