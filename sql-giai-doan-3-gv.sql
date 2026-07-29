-- ============================================================
-- AVATAR — Giai đoạn 3 (Bước 1/1 SQL): VAI TRÒ GIÁO VIÊN GIẢNG DẠY
-- GV đăng nhập chỉ: xem lớp mình phụ trách, GHI DANH (chỉ thêm HS),
-- ĐIỂM DANH học sinh. KHÔNG thu tiền, KHÔNG thấy lớp/cơ sở khác.
-- Chạy 1 lần trong SQL Editor -> Run. An toàn chạy lại nhiều lần.
-- (Chạy xong CHƯA thay đổi gì cho tới khi tạo tài khoản GV.)
-- ============================================================

-- 1) profiles: cho phép vai trò 'teacher' + thêm cột gv_id (GV này là ai)
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('admin','owner','teacher'));
alter table public.profiles add column if not exists gv_id int;

-- 2) lop_hoc: nối lớp ↔ giáo viên bằng MÃ (chắc chắn hơn khớp theo tên)
alter table public.lop_hoc add column if not exists gv_id int;

-- 3) Điền sẵn gv_id cho lớp cũ: khớp tên GV trong cùng cơ sở (chỉ ô đang trống)
update public.lop_hoc l
   set gv_id = g.id
  from public.giao_vien g
 where l.gv_id is null
   and g.coso_id = l.coso_id
   and lower(btrim(g.ten)) = lower(btrim(l.gv));

-- 4) Hàm phụ trợ: gv_id của người đang đăng nhập + "lớp này có phải của tôi"
create or replace function public.my_gv_id()
returns int language sql stable security definer set search_path = public as $$
  select gv_id from public.profiles where id = auth.uid()
$$;

create or replace function public.is_my_lop(p_lop_id int)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.lop_hoc
     where id = p_lop_id and gv_id is not null and gv_id = public.my_gv_id()
  )
$$;

-- ============================================================
-- 5) VIẾT LẠI KHÓA HÀNG (RLS) THEO VAI TRÒ
--    admin  : mọi cơ sở
--    owner  : đúng cơ sở của mình (đã thêm điều kiện role='owner' để GV
--             KHÔNG bị thừa hưởng quyền cả cơ sở — nhất là Sổ quỹ)
--    teacher: chỉ lớp mình phụ trách; hoc_vien chỉ XEM + THÊM (không sửa/xóa)
-- ============================================================

-- profiles: mỗi người xem hồ sơ của mình; admin xem được tất cả (để quản lý TK)
drop policy if exists profiles_sel on public.profiles;
create policy profiles_sel on public.profiles for select to authenticated
  using (id = auth.uid() or my_role() = 'admin');

-- ----- hoc_vien: teacher XEM + THÊM lớp mình; KHÔNG sửa/xóa -----
drop policy if exists hoc_vien_sel on public.hoc_vien;
drop policy if exists hoc_vien_ins on public.hoc_vien;
drop policy if exists hoc_vien_upd on public.hoc_vien;
drop policy if exists hoc_vien_del on public.hoc_vien;
create policy hoc_vien_sel on public.hoc_vien for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy hoc_vien_ins on public.hoc_vien for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy hoc_vien_upd on public.hoc_vien for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy hoc_vien_del on public.hoc_vien for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));

-- ----- so_quy: teacher KHÔNG đụng tới -----
drop policy if exists so_quy_sel on public.so_quy;
drop policy if exists so_quy_ins on public.so_quy;
drop policy if exists so_quy_upd on public.so_quy;
drop policy if exists so_quy_del on public.so_quy;
create policy so_quy_sel on public.so_quy for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy so_quy_ins on public.so_quy for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy so_quy_upd on public.so_quy for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy so_quy_del on public.so_quy for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));

-- ----- diem_danh_hv: teacher điểm danh lớp mình (xem/thêm/sửa/xóa lượt điểm) -----
drop policy if exists dd_sel on public.diem_danh_hv;
drop policy if exists dd_ins on public.diem_danh_hv;
drop policy if exists dd_upd on public.diem_danh_hv;
drop policy if exists dd_del on public.diem_danh_hv;
create policy dd_sel on public.diem_danh_hv for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy dd_ins on public.diem_danh_hv for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy dd_upd on public.diem_danh_hv for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy dd_del on public.diem_danh_hv for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));

-- ----- cham_cong_gv: teacher chấm ca dạy lớp mình -----
drop policy if exists cc_sel on public.cham_cong_gv;
drop policy if exists cc_ins on public.cham_cong_gv;
drop policy if exists cc_upd on public.cham_cong_gv;
drop policy if exists cc_del on public.cham_cong_gv;
create policy cc_sel on public.cham_cong_gv for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy cc_ins on public.cham_cong_gv for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy cc_upd on public.cham_cong_gv for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));
create policy cc_del on public.cham_cong_gv for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and is_my_lop(lop_id)));

-- ----- giao_vien: teacher KHÔNG đụng (không sửa hồ sơ GV) -----
drop policy if exists giao_vien_sel on public.giao_vien;
drop policy if exists giao_vien_ins on public.giao_vien;
drop policy if exists giao_vien_upd on public.giao_vien;
drop policy if exists giao_vien_del on public.giao_vien;
create policy giao_vien_sel on public.giao_vien for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy giao_vien_ins on public.giao_vien for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy giao_vien_upd on public.giao_vien for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy giao_vien_del on public.giao_vien for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));

-- ----- lop_hoc: teacher CHỈ XEM lớp mình phụ trách -----
drop policy if exists lop_hoc_sel on public.lop_hoc;
drop policy if exists lop_hoc_ins on public.lop_hoc;
drop policy if exists lop_hoc_upd on public.lop_hoc;
drop policy if exists lop_hoc_del on public.lop_hoc;
create policy lop_hoc_sel on public.lop_hoc for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()) or (my_role()='teacher' and gv_id=my_gv_id()));
create policy lop_hoc_ins on public.lop_hoc for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy lop_hoc_upd on public.lop_hoc for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy lop_hoc_del on public.lop_hoc for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));

-- ----- gv_edits: teacher KHÔNG đụng -----
drop policy if exists gv_sel on public.gv_edits;
drop policy if exists gv_ins on public.gv_edits;
drop policy if exists gv_upd on public.gv_edits;
drop policy if exists gv_del on public.gv_edits;
create policy gv_sel on public.gv_edits for select to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy gv_ins on public.gv_edits for insert to authenticated
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy gv_upd on public.gv_edits for update to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()))
  with check (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));
create policy gv_del on public.gv_edits for delete to authenticated
  using (my_role()='admin' or (my_role()='owner' and coso_id=my_coso()));

-- ============================================================
-- XONG. Bấm Run. (Chưa thấy gì thay đổi là ĐÚNG — tới bước tạo tài
-- khoản GV mới có tác dụng.) Sau đó em gửi tiếp Edge Function + app.
-- ============================================================
