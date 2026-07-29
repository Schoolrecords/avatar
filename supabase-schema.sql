-- ============================================================
-- AVATAR — Cơ sở dữ liệu Supabase (chạy 1 lần trong SQL Editor)
-- Tạo bảng dữ liệu SỐNG + phân quyền khóa theo cơ sở (RLS)
-- Dữ liệu tĩnh (giáo viên, lớp, học sinh) vẫn nằm ở data.js.
-- coso_id trùng với id cơ sở trong data.js (0..13).
-- ============================================================

-- ---------- 1) BẢNG HỒ SƠ NGƯỜI DÙNG ----------
-- Mỗi tài khoản đăng nhập (auth.users) có 1 dòng ở đây,
-- ghi vai trò (admin = Giám đốc, owner = Lễ tân cơ sở) + cơ sở phụ trách.
create table if not exists public.profiles (
  id       uuid primary key references auth.users(id) on delete cascade,
  ho_ten   text,
  role     text check (role in ('admin','owner')),
  coso_id  int,               -- null với Giám đốc; 0..13 với Lễ tân
  created_at timestamptz default now()
);

-- ---------- 2) BẢNG DỮ LIỆU SỐNG ----------
-- Học viên ghi danh
create table if not exists public.hoc_vien (
  id       bigint generated always as identity primary key,
  ten      text not null,
  ns       text,
  ph       text,
  sdt      text,
  hoc_phi  numeric default 0,          -- học phí CẢ KHÓA
  so_tien_dong numeric default 0,      -- số tiền đã đóng thực tế (có thể đóng một phần)
  lop_id   int  not null,
  coso_id  int  not null,
  mau      boolean default false,     -- học viên mẫu (tạo nhanh để thử)
  created_at timestamptz default now()
);
create index if not exists hoc_vien_lop_idx  on public.hoc_vien(lop_id);
create index if not exists hoc_vien_coso_idx on public.hoc_vien(coso_id);

-- Sổ quỹ thu - chi
create table if not exists public.so_quy (
  id        bigint generated always as identity primary key,
  ngay      date not null,
  loai      text not null check (loai in ('thu','chi')),
  hang_muc  text,
  coso_id   int  not null,
  so_tien   numeric not null default 0,
  noi_dung  text,
  nguoi_lap text,
  created_at timestamptz default now()
);
create index if not exists so_quy_coso_idx on public.so_quy(coso_id);

-- Điểm danh học viên (mỗi HV mỗi buổi 1 dòng)
create table if not exists public.diem_danh_hv (
  id         bigint generated always as identity primary key,
  lop_id     int  not null,
  ngay       date not null,
  hv_id      bigint not null,
  coso_id    int  not null,
  trang_thai text not null,           -- co / muon / phep / vang
  created_at timestamptz default now(),
  unique (lop_id, ngay, hv_id)
);
create index if not exists dd_coso_idx on public.diem_danh_hv(coso_id);

-- Chấm công giáo viên (mỗi lớp mỗi buổi 1 dòng)
create table if not exists public.cham_cong_gv (
  id         bigint generated always as identity primary key,
  lop_id     int  not null,
  ngay       date not null,
  coso_id    int  not null,
  trang_thai text not null,           -- day / nghi / bu
  created_at timestamptz default now(),
  unique (lop_id, ngay)
);
create index if not exists cc_coso_idx on public.cham_cong_gv(coso_id);

-- ---------- 3) HÀM LẤY VAI TRÒ / CƠ SỞ CỦA NGƯỜI ĐANG ĐĂNG NHẬP ----------
-- SECURITY DEFINER để không bị vòng lặp khi kiểm tra quyền.
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.my_coso()
returns int language sql stable security definer set search_path = public as $$
  select coso_id from public.profiles where id = auth.uid()
$$;

-- ---------- 4) TỰ TẠO HỒ SƠ KHI CÓ TÀI KHOẢN MỚI ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, ho_ten)
  values (new.id, coalesce(new.raw_user_meta_data->>'ho_ten', new.email))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- 5) BẬT KHÓA HÀNG (RLS) ----------
alter table public.profiles     enable row level security;
alter table public.hoc_vien     enable row level security;
alter table public.so_quy       enable row level security;
alter table public.diem_danh_hv enable row level security;
alter table public.cham_cong_gv enable row level security;

-- Hồ sơ: mỗi người chỉ đọc hồ sơ của chính mình
drop policy if exists profiles_sel on public.profiles;
create policy profiles_sel on public.profiles
  for select to authenticated using (id = auth.uid());

-- Hàm tiện dụng: điều kiện "được phép trên cơ sở này"
-- admin: mọi cơ sở; owner: đúng cơ sở của mình.
-- (Viết trực tiếp trong từng policy bên dưới.)

-- ----- hoc_vien -----
drop policy if exists hoc_vien_sel on public.hoc_vien;
drop policy if exists hoc_vien_ins on public.hoc_vien;
drop policy if exists hoc_vien_upd on public.hoc_vien;
drop policy if exists hoc_vien_del on public.hoc_vien;
create policy hoc_vien_sel on public.hoc_vien for select to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());
create policy hoc_vien_ins on public.hoc_vien for insert to authenticated
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy hoc_vien_upd on public.hoc_vien for update to authenticated
  using (my_role() = 'admin' or coso_id = my_coso())
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy hoc_vien_del on public.hoc_vien for delete to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());

-- ----- so_quy -----
drop policy if exists so_quy_sel on public.so_quy;
drop policy if exists so_quy_ins on public.so_quy;
drop policy if exists so_quy_upd on public.so_quy;
drop policy if exists so_quy_del on public.so_quy;
create policy so_quy_sel on public.so_quy for select to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());
create policy so_quy_ins on public.so_quy for insert to authenticated
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy so_quy_upd on public.so_quy for update to authenticated
  using (my_role() = 'admin' or coso_id = my_coso())
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy so_quy_del on public.so_quy for delete to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());

-- ----- diem_danh_hv -----
drop policy if exists dd_sel on public.diem_danh_hv;
drop policy if exists dd_ins on public.diem_danh_hv;
drop policy if exists dd_upd on public.diem_danh_hv;
drop policy if exists dd_del on public.diem_danh_hv;
create policy dd_sel on public.diem_danh_hv for select to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());
create policy dd_ins on public.diem_danh_hv for insert to authenticated
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy dd_upd on public.diem_danh_hv for update to authenticated
  using (my_role() = 'admin' or coso_id = my_coso())
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy dd_del on public.diem_danh_hv for delete to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());

-- ----- cham_cong_gv -----
drop policy if exists cc_sel on public.cham_cong_gv;
drop policy if exists cc_ins on public.cham_cong_gv;
drop policy if exists cc_upd on public.cham_cong_gv;
drop policy if exists cc_del on public.cham_cong_gv;
create policy cc_sel on public.cham_cong_gv for select to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());
create policy cc_ins on public.cham_cong_gv for insert to authenticated
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy cc_upd on public.cham_cong_gv for update to authenticated
  using (my_role() = 'admin' or coso_id = my_coso())
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy cc_del on public.cham_cong_gv for delete to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());

-- ----- gv_edits: chỉnh sửa hồ sơ giáo viên (đè lên data.js tĩnh) -----
create table if not exists public.gv_edits (
  gv_id   int primary key,          -- id giáo viên trong data.js
  coso_id int not null,
  ten text, ns text, td text, dc text, sdt text, mon text,
  updated_at timestamptz default now()
);
alter table public.gv_edits enable row level security;
drop policy if exists gv_sel on public.gv_edits;
drop policy if exists gv_ins on public.gv_edits;
drop policy if exists gv_upd on public.gv_edits;
drop policy if exists gv_del on public.gv_edits;
create policy gv_sel on public.gv_edits for select to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());
create policy gv_ins on public.gv_edits for insert to authenticated
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy gv_upd on public.gv_edits for update to authenticated
  using (my_role() = 'admin' or coso_id = my_coso())
  with check (my_role() = 'admin' or coso_id = my_coso());
create policy gv_del on public.gv_edits for delete to authenticated
  using (my_role() = 'admin' or coso_id = my_coso());

-- ============================================================
-- XONG PHẦN TẠO BẢNG. Bấm "Run".
-- ============================================================


-- ============================================================
-- (CHẠY SAU) GÁN QUYỀN CHO TÀI KHOẢN — làm ở FILE/BƯỚC RIÊNG
-- Sau khi đã tạo tài khoản trong Authentication > Users, chạy khối
-- dưới đây để gán vai trò + cơ sở theo email. Sửa email cho khớp.
-- Bảng cơ sở:
--   0 Diễn Liên | 1 Diễn Hạnh | 2 Diễn Hồng | 3 Diễn Hồng 1
--   4 Diễn Kỷ   | 5 Diễn Kỷ 1 | 6 Diễn Ngọc | 7 Diễn Ngọc 2
--   8 Diễn Tháp | 9 Diễn Đồng | 10 Hợp Thành | 11 Minh Châu
--   12 Trung Dinh | 13 Trung Tâm
-- ============================================================
--
-- -- Giám đốc (toàn hệ thống):
-- update public.profiles p set role='admin', coso_id=null
--   from auth.users u where u.id = p.id and u.email = 'giamdoc@avatar.vn';
--
-- -- Lễ tân từng cơ sở (mở dòng nào cần dùng):
-- update public.profiles p set role='owner', coso_id=0  from auth.users u where u.id=p.id and u.email='cs0@avatar.vn';
-- update public.profiles p set role='owner', coso_id=1  from auth.users u where u.id=p.id and u.email='cs1@avatar.vn';
-- update public.profiles p set role='owner', coso_id=2  from auth.users u where u.id=p.id and u.email='cs2@avatar.vn';
-- update public.profiles p set role='owner', coso_id=3  from auth.users u where u.id=p.id and u.email='cs3@avatar.vn';
-- update public.profiles p set role='owner', coso_id=4  from auth.users u where u.id=p.id and u.email='cs4@avatar.vn';
-- update public.profiles p set role='owner', coso_id=6  from auth.users u where u.id=p.id and u.email='cs6@avatar.vn';
-- update public.profiles p set role='owner', coso_id=7  from auth.users u where u.id=p.id and u.email='cs7@avatar.vn';
-- update public.profiles p set role='owner', coso_id=8  from auth.users u where u.id=p.id and u.email='cs8@avatar.vn';
-- update public.profiles p set role='owner', coso_id=9  from auth.users u where u.id=p.id and u.email='cs9@avatar.vn';
-- update public.profiles p set role='owner', coso_id=10 from auth.users u where u.id=p.id and u.email='cs10@avatar.vn';
-- update public.profiles p set role='owner', coso_id=11 from auth.users u where u.id=p.id and u.email='cs11@avatar.vn';
-- update public.profiles p set role='owner', coso_id=12 from auth.users u where u.id=p.id and u.email='cs12@avatar.vn';
-- update public.profiles p set role='owner', coso_id=13 from auth.users u where u.id=p.id and u.email='cs13@avatar.vn';
--
-- -- Kiểm tra kết quả:
-- select u.email, p.role, p.coso_id from public.profiles p join auth.users u on u.id=p.id order by p.role, p.coso_id;
