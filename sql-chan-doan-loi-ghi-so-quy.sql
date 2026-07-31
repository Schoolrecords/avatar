-- ============================================================
-- AVATAR — CHẨN ĐOÁN lỗi: "new row violates row-level security policy for table so_quy"
-- (không ghi nhận được tiền học phí / không lưu được phiếu thu – chi)
--
-- FILE NÀY CHỈ ĐỌC — không sửa, không xóa gì cả. Chạy bao nhiêu lần cũng an toàn.
-- Cách chạy: Supabase → SQL Editor → dán cả file → Run → xem lần lượt các bảng kết quả.
-- ============================================================

-- ---------- 1) CÁC TÀI KHOẢN & PHÂN QUYỀN ----------
-- Cột role PHẢI là đúng một trong: admin (quản trị chuỗi) · owner (lễ tân cơ sở) · teacher (giáo viên).
-- Lễ tân phải có coso_id trỏ đúng cơ sở mình; role viết hoa, viết sai hay để trống đều bị chặn ghi.
select
  p.id,
  p.ho_ten,
  u.email,
  p.role,
  p.coso_id,
  c.ten                                       as ten_co_so,
  case
    when p.role is null                       then '⚠ CHƯA phân quyền → bị chặn mọi thao tác ghi'
    when p.role not in ('admin','owner','teacher') then '⚠ VAI TRÒ LẠ → bị chặn ghi sổ quỹ'
    when p.role = 'owner' and p.coso_id is null    then '⚠ Lễ tân CHƯA gắn cơ sở → bị chặn ghi sổ quỹ'
    when p.role = 'owner' and c.id is null         then '⚠ coso_id trỏ tới cơ sở KHÔNG tồn tại'
    when p.role = 'teacher'                        then 'Giáo viên — không được ghi sổ quỹ (đúng thiết kế)'
    else 'OK'
  end                                          as danh_gia
from public.profiles p
left join auth.users u on u.id = p.id
left join public.co_so c on c.id = p.coso_id
order by p.role, p.coso_id;

-- ---------- 2) DANH SÁCH CƠ SỞ (xem có 2 cơ sở TRÙNG TÊN không) ----------
-- Trùng tên rất dễ nhầm: app hiện "Diễn Đồng" ở cả hai chỗ nhưng thực ra là hai mã khác nhau,
-- lễ tân mã này sẽ không ghi được cho học sinh mã kia.
select
  c.id, c.ten, c.dc,
  count(*) over (partition by lower(btrim(c.ten))) as so_co_so_cung_ten,
  (select count(*) from public.hoc_vien h where h.coso_id = c.id)  as so_hoc_sinh,
  (select count(*) from public.profiles p where p.coso_id = c.id)  as so_tai_khoan
from public.co_so c
order by c.id;

-- ---------- 3) KỲ SỔ QUỸ ĐÃ CHỐT (đã chốt = khóa, không ai ghi thêm được) ----------
select k.id, k.coso_id, c.ten as ten_co_so, k.ky, k.chot_at, k.ghi_chu
from public.chot_so_quy k
left join public.co_so c on c.id = k.coso_id
order by k.ky desc, k.coso_id;

-- ---------- 4) HỌC SINH CÓ CƠ SỞ LỆCH VỚI LỚP ĐANG HỌC ----------
-- Em hiện ở lớp thuộc cơ sở A nhưng hồ sơ lại ghi cơ sở B → lễ tân một trong hai bên
-- sẽ không thu tiền được cho em. Đây là lỗi DỮ LIỆU, cần sửa lại cho khớp.
select
  h.id as hv_id, h.ten as hoc_sinh, h.ph as phu_huynh,
  h.coso_id  as co_so_ghi_trong_ho_so, ch.ten as ten_co_so_ho_so,
  l.id as lop_id, l.lop as ten_lop,
  l.coso_id  as co_so_cua_lop,        cl.ten as ten_co_so_lop
from public.hoc_vien h
join public.lop_hoc l on l.id = h.lop_id
left join public.co_so ch on ch.id = h.coso_id
left join public.co_so cl on cl.id = l.coso_id
where h.coso_id is distinct from l.coso_id
order by h.ten;

-- ---------- 5) HỌC SINH KHÔNG GẮN CƠ SỞ ----------
select id, ten, ph, lop_id, coso_id
from public.hoc_vien
where coso_id is null
order by ten;

-- ---------- 6) CÁC KHÓA HÀNG (RLS) ĐANG ÁP DỤNG CHO SỔ QUỸ ----------
-- Đúng chuẩn: mỗi lệnh (select/insert/update/delete) chỉ có ĐÚNG MỘT policy tên so_quy_*.
select policyname, cmd, qual as dieu_kien_doc, with_check as dieu_kien_ghi
from pg_policies
where schemaname = 'public' and tablename = 'so_quy'
order by cmd, policyname;

-- ============================================================
-- ĐỌC KẾT QUẢ:
--   • Bảng 1 có dòng ⚠  → sửa cột role / coso_id của tài khoản đó cho đúng.
--   • Bảng 2 có so_co_so_cung_ten > 1 → hai cơ sở trùng tên, kiểm tra tài khoản lễ tân
--     đang gắn mã nào và học sinh thuộc mã nào.
--   • Bảng 3 có dòng đúng cơ sở + đúng tháng đang ghi → kỳ đã chốt, cần Quản trị mở khóa
--     (trong app: Thu – Chi → chọn kỳ & cơ sở → 🔓 Mở khóa kỳ).
--   • Bảng 4 / 5 có dòng → dữ liệu học sinh lệch cơ sở; sửa cho khớp lớp em đang học, ví dụ:
--        update public.hoc_vien h set coso_id = l.coso_id
--          from public.lop_hoc l where l.id = h.lop_id and h.coso_id is distinct from l.coso_id;
--     (chỉ chạy khi đã xem bảng 4 và thấy đúng là lỗi nhập liệu)
--   • Bảng 6 thiếu policy insert/update/delete → chạy lại sql-giai-doan-5-thu-chi.sql.
--   • Tất cả đều bình thường → nguyên nhân là PHIÊN ĐĂNG NHẬP hết hạn trên máy đang dùng:
--     đăng xuất, tải lại trang rồi đăng nhập lại.
-- ============================================================
