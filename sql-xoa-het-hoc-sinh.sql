-- ============================================================
-- AVATAR — XÓA HẾT HỌC SINH ĐỂ NHẬP LẠI TỪ ĐẦU
--
-- ✅ GIỮ NGUYÊN: lớp học, giáo viên, cơ sở, tài khoản đăng nhập,
--    chấm công giáo viên, đối soát ca dạy,
--    và các phiếu THU – CHI THỦ CÔNG (phiếu không gắn học sinh).
--
-- ❌ XÓA: toàn bộ học sinh (mọi cơ sở)
--         + điểm danh học sinh
--         + phiếu thu học phí TỰ SINH của học sinh (so_quy có hv_id).
--
-- ⚠️ KHÔNG HOÀN TÁC ĐƯỢC.
-- ============================================================


-- ┌────────────────────────────────────────────────────────────┐
-- │ KHỐI 1 — XEM TRƯỚC (chỉ ĐẾM, KHÔNG xóa gì).                │
-- └────────────────────────────────────────────────────────────┘
select 'Học sinh SẼ XÓA'                       as muc, count(*) as so_dong from public.hoc_vien
union all
select 'Điểm danh học sinh SẼ XÓA',            count(*) from public.diem_danh_hv
union all
select 'Phiếu thu học phí (của HS) SẼ XÓA',    count(*) from public.so_quy where hv_id is not null
union all
select '>>> GIỮ — Lớp học',                    count(*) from public.lop_hoc
union all
select '>>> GIỮ — Giáo viên',                  count(*) from public.giao_vien
union all
select '>>> GIỮ — Phiếu thu/chi thủ công',     count(*) from public.so_quy where hv_id is null
union all
select '>>> GIỮ — Chấm công giáo viên',        count(*) from public.cham_cong_gv;


-- ┌────────────────────────────────────────────────────────────┐
-- │ KHỐI 2 — XÓA THẬT (bôi đen cả 3 lệnh dưới rồi Run).         │
-- └────────────────────────────────────────────────────────────┘
with x1 as (delete from public.so_quy       where hv_id is not null returning 1),
     x2 as (delete from public.diem_danh_hv                         returning 1),
     x3 as (delete from public.hoc_vien                             returning 1)
select (select count(*) from x3) as hoc_sinh_da_xoa,
       (select count(*) from x2) as diem_danh_da_xoa,
       (select count(*) from x1) as phieu_thu_hp_da_xoa;

-- Đánh số học sinh lại từ 1 cho danh sách mới gọn (bảng đang trống nên an toàn)
alter table public.hoc_vien alter column id restart with 1;

-- Kiểm tra lại sau khi xóa
select (select count(*) from public.hoc_vien)                        as con_hoc_sinh,
       (select count(*) from public.diem_danh_hv)                    as con_diem_danh,
       (select count(*) from public.lop_hoc)                         as lop_giu_nguyen,
       (select count(*) from public.giao_vien)                       as gv_giu_nguyen,
       (select count(*) from public.so_quy where hv_id is null)       as phieu_thu_chi_thu_cong_giu_nguyen,
       (select count(*) from public.cham_cong_gv)                     as cham_cong_gv_giu_nguyen;


-- ┌────────────────────────────────────────────────────────────┐
-- │ TÙY CHỌN — chỉ chạy nếu anh muốn dọn LUÔN chấm công GV và    │
-- │ trạng thái đối soát ca dạy (làm lại cả điểm danh từ đầu).    │
-- │ Bình thường KHÔNG cần chạy phần này.                         │
-- └────────────────────────────────────────────────────────────┘
-- delete from public.cham_cong_gv;
-- delete from public.duyet_diem_danh;


-- ============================================================
-- XONG. Vào web bấm Ctrl+F5 (điện thoại: kéo xuống làm mới).
-- Sau đó: Ghi danh → Tải mẫu Excel (cả cơ sở) → điền ĐÚNG cột
-- "Thời gian nhập học" → Nhập Excel.
--
-- LƯU Ý KẾ TOÁN: nếu anh đã CHỐT SỔ tháng nào thì phiếu thu học phí
-- của tháng đó bị xóa theo, con số đã chốt cũ sẽ không còn khớp.
-- Cần thì vào Sổ quỹ → mở khóa và chốt lại kỳ đó.
-- ============================================================
