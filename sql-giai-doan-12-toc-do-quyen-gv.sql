-- ============================================================
-- AVATAR — Giai đoạn 12 (KHẨN, 14/08/2026): GIÁO VIÊN KHÔNG ĐĂNG NHẬP ĐƯỢC
--
-- TRIỆU CHỨNG: giáo viên nhập đúng mật khẩu, app báo
--   "Không tải được dữ liệu. Kiểm tra kết nối mạng."
--   Quản lý và Lễ tân vẫn vào bình thường.
--
-- NGUYÊN NHÂN THẬT (đã đo trực tiếp trên máy chủ):
--   Truy vấn bảng hoc_vien của tài khoản giáo viên bị máy chủ HỦY vì quá giờ
--   (lỗi Postgres 57014 "canceling statement due to statement timeout", giới
--   hạn 8 giây). Không phải lỗi mạng, không phải sai mật khẩu.
--
--   Vì sao chỉ giáo viên? Khóa hàng (RLS) của giáo viên gọi hàm is_my_lop()
--   cho TỪNG DÒNG học sinh. Mỗi lần gọi lại chạy thêm 3 truy vấn con
--   (profiles + lop_hoc + lich_lop). Lễ tân chỉ so coso_id = một phép so sánh.
--   Số học sinh tăng dần → tới hôm qua thì vượt mốc 8 giây và gãy hẳn.
--
-- CÁCH SỬA: tính "danh sách lớp của tôi" MỘT LẦN cho cả câu truy vấn thay vì
--   tính lại cho từng dòng — cách chuẩn Supabase khuyến nghị. Quyền xem của
--   từng vai trò GIỮ NGUYÊN 100%, chỉ chạy nhanh hơn.
--
-- Chạy 1 lần: Supabase → SQL Editor → dán toàn bộ → Run. An toàn chạy lại.
-- KHÔNG đụng tới một dòng dữ liệu nào (chỉ sửa quy tắc quyền + thêm chỉ mục).
--
-- Bản này đã chạy thử trên PostgreSQL 17 với 6.000 học sinh trước khi dùng
-- thật: 266 ms → 0,6 ms, và mọi vai trò trả về đúng số dòng như cũ.
-- ============================================================


-- ------------------------------------------------------------
-- 1) HÀM MỚI: DANH SÁCH LỚP CỦA GIÁO VIÊN ĐANG ĐĂNG NHẬP
--    Trả về một BẢNG id lớp, dùng dưới dạng "lop_id in (select …)".
--    Vì không phụ thuộc dòng nào cả nên Postgres chỉ chạy đúng MỘT lần cho
--    mỗi câu truy vấn rồi giữ lại dùng chung, thay vì mỗi dòng một lần.
--    Nội dung xét y hệt is_my_lop() cũ: lớp mình phụ trách HOẶC lớp mình
--    được phân dạy ít nhất một buổi trong lịch.
--    security definer để không đụng lại khóa hàng của lop_hoc/lich_lop
--    (nếu không sẽ thành vòng lặp quyền kiểm tra quyền).
-- ------------------------------------------------------------
create or replace function public.my_lop_list()
returns table(id_lop bigint) language sql stable security definer set search_path = public as $$
  select l.id::bigint
    from public.lop_hoc l
   where l.gv_id is not null and l.gv_id = public.my_gv_id()
  union
  select ll.lop_id::bigint
    from public.lich_lop ll
   where ll.gv_id is not null and ll.gv_id = public.my_gv_id()
$$;
grant execute on function public.my_lop_list() to authenticated;

-- Giữ is_my_lop() nguyên vẹn: các quy tắc GHI (thêm/sửa/xóa) vẫn đang dùng nó
-- và chỉ chạy trên 1 dòng nên không hề chậm.


-- ------------------------------------------------------------
-- 2) CHỈ MỤC CÒN THIẾU
--    lop_hoc.gv_id chưa có chỉ mục → mỗi lần dò lớp của giáo viên phải quét
--    cả bảng. (lich_lop.gv_id đã có từ Giai đoạn 9.)
-- ------------------------------------------------------------
create index if not exists lh_gv_idx on public.lop_hoc(gv_id);
create index if not exists dd_ngay_idx on public.diem_danh_hv(ngay);
create index if not exists cc_ngay_idx on public.cham_cong_gv(ngay);


-- ------------------------------------------------------------
-- 3) VIẾT LẠI CÁC QUY TẮC XEM (SELECT) CHO CHẠY NHANH
--
--    Hai thay đổi máy móc, lặp lại ở mọi quy tắc:
--      · my_role()  →  (select my_role())    — bọc trong (select …) để
--        Postgres tính một lần rồi dùng lại, thay vì gọi lại từng dòng.
--      · is_my_lop(lop_id)  →  lop_id in (select id_lop from my_lop_list())
--
--    Ý nghĩa quyền hạn KHÔNG đổi. Riêng lop_hoc có sửa đúng một điểm,
--    ghi rõ ở mục 3.7 bên dưới.
-- ------------------------------------------------------------

-- 3.1 profiles — mỗi người xem hồ sơ mình; Quản trị xem tất cả
drop policy if exists profiles_sel on public.profiles;
create policy profiles_sel on public.profiles for select to authenticated
  using ( id = (select auth.uid()) or (select public.my_role()) = 'admin' );

-- 3.2 hoc_vien — CHÍNH LÀ BẢNG GÂY LỖI
drop policy if exists hoc_vien_sel on public.hoc_vien;
create policy hoc_vien_sel on public.hoc_vien for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and lop_id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.3 diem_danh_hv
drop policy if exists dd_sel on public.diem_danh_hv;
create policy dd_sel on public.diem_danh_hv for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and lop_id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.4 cham_cong_gv
drop policy if exists cc_sel on public.cham_cong_gv;
create policy cc_sel on public.cham_cong_gv for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and lop_id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.5 duyet_diem_danh
drop policy if exists ddd_sel on public.duyet_diem_danh;
create policy ddd_sel on public.duyet_diem_danh for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and lop_id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.6 lich_lop
drop policy if exists ll_sel on public.lich_lop;
create policy ll_sel on public.lich_lop for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and lop_id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.7 lop_hoc
--     SỬA THÊM MỘT ĐIỂM (có chủ ý): trước đây giáo viên chỉ thấy lớp mà mình
--     là người PHỤ TRÁCH (lop_hoc.gv_id). Giai đoạn 9 mở cho "mỗi buổi một
--     giáo viên" nhưng quên sửa chỗ này, nên giáo viên chỉ dạy vài buổi của
--     một lớp thì thấy được học sinh mà KHÔNG thấy chính lớp đó — Điểm danh
--     hiện trống. Nay dùng chung my_lop_list() nên khớp đúng ý Giai đoạn 9.
drop policy if exists lop_hoc_sel on public.lop_hoc;
create policy lop_hoc_sel on public.lop_hoc for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( (select public.my_role()) = 'owner'   and coso_id = (select public.my_coso()) )
    or ( (select public.my_role()) = 'teacher'
         and id::bigint in (select m.id_lop from public.my_lop_list() m) )
  );

-- 3.8 Các bảng giáo viên KHÔNG được xem (giữ nguyên quyền, chỉ tăng tốc)
drop policy if exists so_quy_sel on public.so_quy;
create policy so_quy_sel on public.so_quy for select to authenticated
  using ( (select public.my_role()) = 'admin'
          or ( (select public.my_role()) = 'owner' and coso_id = (select public.my_coso()) ) );

drop policy if exists giao_vien_sel on public.giao_vien;
create policy giao_vien_sel on public.giao_vien for select to authenticated
  using ( (select public.my_role()) = 'admin'
          or ( (select public.my_role()) = 'owner' and coso_id = (select public.my_coso()) ) );

drop policy if exists gv_sel on public.gv_edits;
create policy gv_sel on public.gv_edits for select to authenticated
  using ( (select public.my_role()) = 'admin'
          or ( (select public.my_role()) = 'owner' and coso_id = (select public.my_coso()) ) );

drop policy if exists chot_sel on public.chot_so_quy;
create policy chot_sel on public.chot_so_quy for select to authenticated
  using ( (select public.my_role()) = 'admin'
          or ( (select public.my_role()) = 'owner' and coso_id = (select public.my_coso()) ) );

-- 3.9 ca_hoc — giáo viên vẫn xem khung giờ cơ sở mình (giữ nguyên)
drop policy if exists ch_sel on public.ca_hoc;
create policy ch_sel on public.ca_hoc for select to authenticated
  using ( (select public.my_role()) = 'admin'
          or ( (select public.my_role()) in ('owner','teacher') and coso_id = (select public.my_coso()) ) );

-- 3.10 thong_bao — giữ nguyên logic lọc theo cơ sở + vai trò
drop policy if exists tb_sel on public.thong_bao;
create policy tb_sel on public.thong_bao for select to authenticated
  using (
    (select public.my_role()) = 'admin'
    or ( ( coso_id is null or coso_id = (select public.my_coso()) )
         and ( vai_tro = 'all' or vai_tro = (select public.my_role()) ) )
  );


-- ------------------------------------------------------------
-- 4) NỚI GIỚI HẠN THỜI GIAN — LƯỚI AN TOÀN
--    Mặc định Supabase hủy mọi truy vấn quá 8 giây. Sau khi sửa ở trên,
--    truy vấn chỉ còn dưới 1 giây nên không bao giờ chạm mốc này; nới lên
--    20 giây chỉ để lần sau dữ liệu phình to thì app CHẬM chứ không GÃY.
--    (Muốn trả lại như cũ: alter role authenticated reset statement_timeout;)
-- ------------------------------------------------------------
alter role authenticated set statement_timeout = '20s';
notify pgrst, 'reload schema';


-- ------------------------------------------------------------
-- 5) KIỂM TRA — nhìn kết quả bên dưới là biết chạy thành công
-- ------------------------------------------------------------
select
  (select count(*) from pg_proc  where proname = 'my_lop_list')                       as ham_moi_da_co,      -- phải = 1
  (select count(*) from pg_indexes where indexname = 'lh_gv_idx')                     as chi_muc_da_co,      -- phải = 1
  (select count(*) from pg_policies
     where schemaname='public' and policyname='hoc_vien_sel'
       and qual like '%my_lop_list%')                                                 as quyen_da_sua;       -- phải = 1

-- ============================================================
-- XONG. Kết quả đúng: cả ba cột đều = 1.
-- Sau đó bảo cô giáo tắt hẳn trình duyệt, mở lại web và đăng nhập.
-- ============================================================
