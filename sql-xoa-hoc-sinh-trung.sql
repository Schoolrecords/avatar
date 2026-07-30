-- ============================================================
-- AVATAR — DỌN HỌC SINH BỊ NHẬP TRÙNG (up file Excel 2 lần)
--
-- Cách nhận trùng: CÙNG cơ sở + CÙNG họ tên (bỏ khoảng trắng dư, không
--   phân biệt chữ hoa/thường) + CÙNG ngày sinh.
-- Bản GIỮ LẠI: ưu tiên bản đã có điểm danh / phiếu thu / đã đóng tiền;
--   nếu ngang nhau thì giữ bản NHẬP TRƯỚC (id nhỏ nhất).
-- Bản XÓA: các bản dư còn lại + điểm danh + phiếu thu của chính bản đó.
--
-- ⚠️ KHÔNG HOÀN TÁC ĐƯỢC. Chạy KHỐI 1 xem trước → đúng rồi mới chạy KHỐI 2.
-- 💡 Cách dễ hơn: làm ngay trên app — trang Học sinh → "Chọn nhiều"
--    → "Chọn N bản trùng" → "Xóa". File SQL này chỉ là phương án dự phòng.
-- ============================================================


-- ┌────────────────────────────────────────────────────────────┐
-- │ KHỐI 1 — XEM TRƯỚC (chỉ xem, KHÔNG xóa gì).                │
-- │ Bôi đen từ chữ "with" tới dấu ; cuối khối rồi bấm Run.      │
-- └────────────────────────────────────────────────────────────┘
with norm as (
  select hv.id, hv.coso_id, hv.lop_id, hv.ten, hv.ns,
         coalesce(hv.so_tien_dong,0) as so_tien_dong,
         lower(regexp_replace(btrim(hv.ten), '\s+', ' ', 'g')) as ten_k,
         coalesce(btrim(hv.ns), '')                            as ns_k
    from public.hoc_vien hv
), dd as (select hv_id, count(*) n from public.diem_danh_hv group by hv_id
), tq as (select hv_id, count(*) n from public.so_quy where hv_id is not null group by hv_id
), xh as (
  select n.*, coalesce(dd.n,0) as so_diem_danh, coalesce(tq.n,0) as so_phieu_thu,
         count(*)      over (partition by n.coso_id, n.ten_k, n.ns_k) as so_ban,
         row_number()  over (partition by n.coso_id, n.ten_k, n.ns_k
                             order by (coalesce(dd.n,0)+coalesce(tq.n,0)
                                       + case when n.so_tien_dong>0 then 1 else 0 end) desc,
                                      n.id asc) as thu_tu
    from norm n
    left join dd on dd.hv_id = n.id
    left join tq on tq.hv_id = n.id
)
select case when thu_tu = 1 then '✅ GIỮ LẠI' else '❌ SẼ XÓA' end as ket_qua,
       coso_id, lop_id, ten, ns, so_ban as so_ban_ghi,
       so_diem_danh, so_phieu_thu, so_tien_dong, id
  from xh
 where so_ban > 1
 order by coso_id, ten_k, ns_k, thu_tu;
-- ↑ Đọc kết quả: mỗi nhóm tên có 1 dòng "GIỮ LẠI", các dòng "SẼ XÓA" là bản dư.
--   Nếu cột so_diem_danh / so_phieu_thu / so_tien_dong của dòng SẼ XÓA đều = 0
--   thì xóa hoàn toàn an toàn. Nếu có số > 0 → xem lại, đừng xóa vội.


-- ┌────────────────────────────────────────────────────────────┐
-- │ KHỐI 2 — XÓA THẬT. Chỉ chạy khi KHỐI 1 đã đúng như ý.       │
-- │ Bôi đen TOÀN BỘ khối này (từ "with" tới dấu ;) rồi bấm Run. │
-- └────────────────────────────────────────────────────────────┘
with norm as (
  select hv.id, hv.coso_id, coalesce(hv.so_tien_dong,0) as so_tien_dong,
         lower(regexp_replace(btrim(hv.ten), '\s+', ' ', 'g')) as ten_k,
         coalesce(btrim(hv.ns), '')                            as ns_k
    from public.hoc_vien hv
), dd as (select hv_id, count(*) n from public.diem_danh_hv group by hv_id
), tq as (select hv_id, count(*) n from public.so_quy where hv_id is not null group by hv_id
), xh as (
  select n.id,
         count(*)     over (partition by n.coso_id, n.ten_k, n.ns_k) as so_ban,
         row_number() over (partition by n.coso_id, n.ten_k, n.ns_k
                            order by (coalesce(dd.n,0)+coalesce(tq.n,0)
                                      + case when n.so_tien_dong>0 then 1 else 0 end) desc,
                                     n.id asc) as thu_tu
    from norm n
    left join dd on dd.hv_id = n.id
    left join tq on tq.hv_id = n.id
), can_xoa as (
  select id from xh where so_ban > 1 and thu_tu > 1        -- các bản dư
), x1 as (
  delete from public.so_quy        where hv_id in (select id from can_xoa) returning 1
), x2 as (
  delete from public.diem_danh_hv  where hv_id in (select id from can_xoa) returning 1
), x3 as (
  delete from public.hoc_vien      where id    in (select id from can_xoa) returning 1
)
select (select count(*) from x3) as hoc_sinh_da_xoa,
       (select count(*) from x2) as diem_danh_da_xoa,
       (select count(*) from x1) as phieu_thu_da_xoa;


-- ┌────────────────────────────────────────────────────────────┐
-- │ KHỐI 3 — KIỂM TRA LẠI (chạy sau KHỐI 2, phải ra 0 dòng).    │
-- └────────────────────────────────────────────────────────────┘
select coso_id,
       lower(regexp_replace(btrim(ten), '\s+', ' ', 'g')) as ten_k,
       coalesce(btrim(ns), '') as ns_k,
       count(*) as con_trung
  from public.hoc_vien
 group by 1, 2, 3
having count(*) > 1
 order by con_trung desc;


-- ============================================================
-- XONG. Vào web bấm Ctrl+F5 (điện thoại: kéo xuống làm mới).
--
-- LƯU Ý: khối trên chỉ gộp các bản có NGÀY SINH GIỐNG NHAU (kể cả cùng
-- để trống). Nếu một bản có ngày sinh mà bản kia trống thì SQL cố tình
-- KHÔNG xóa — thà bỏ sót hơn xóa oan. Trường hợp đó anh dùng nút
-- "Chọn N bản trùng" trên app (app nhận diện thoáng hơn), hoặc xóa tay
-- từng em ở trang Học sinh.
-- ============================================================
