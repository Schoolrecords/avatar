-- ============================================================
-- AVATAR — Giai đoạn 7
--   PHẦN 1: Chấm công ghi rõ AI THỰC DẠY  (sửa lỗi tính lương sai người)
--   PHẦN 2: Danh sách cơ sở đưa lên CSDL  (mở cơ sở mới không phải sửa code)
--
-- Chạy 1 lần trong Supabase → SQL Editor → Run. An toàn chạy lại nhiều lần.
-- KHÔNG đụng tới điểm danh, học sinh hay sổ quỹ đang có.
-- ============================================================

-- ============================================================
-- PHẦN 1 — CHẤM CÔNG GẮN VỚI NGƯỜI THỰC DẠY
--
-- Trước đây cham_cong_gv chỉ có (lop_id, ngay) nên khi tính lương, hệ thống
-- phải suy ra "GV nào ĐANG phụ trách lớp này". Hai chỗ sai:
--   · Cô B dạy thay lớp của cô A  → công vào túi cô A.
--   · Lớp đổi giáo viên giữa tháng → công cả tháng nhảy sang người mới.
-- Nay mỗi buổi lưu thêm gv_id = người thực dạy buổi đó.
-- ============================================================
alter table public.cham_cong_gv add column if not exists gv_id bigint;
create index if not exists cc_gv_idx on public.cham_cong_gv(gv_id);

-- Điền cho dữ liệu cũ: lấy giáo viên đang phụ trách lớp (đúng với đa số buổi).
-- Buổi nào thực tế có người dạy thay thì lễ tân vào màn Điểm danh chọn lại.
do $$ begin
  if to_regclass('public.lop_hoc') is not null then
    update public.cham_cong_gv c
       set gv_id = l.gv_id
      from public.lop_hoc l
     where l.id = c.lop_id and c.gv_id is null and l.gv_id is not null;
  end if;
end $$;

-- ============================================================
-- PHẦN 2 — BẢNG CƠ SỞ
--
-- Danh sách 14 cơ sở đang nằm cứng trong file data.js: mở cơ sở mới phải sửa
-- code rồi đẩy lại lên web. Nay đưa lên CSDL để Quản trị tự thêm/sửa/xóa.
-- Giữ NGUYÊN mã cơ sở 0–13 nên toàn bộ học sinh, lớp, giáo viên, sổ quỹ,
-- điểm danh cũ vẫn khớp.
-- ============================================================
create table if not exists public.co_so (
  id      int primary key,               -- giữ đúng mã cũ 0..13
  ten     text not null,
  dc      text,                          -- địa chỉ
  build   boolean default false,         -- đang xây dựng (chưa hoạt động)
  thu_tu  int,                           -- thứ tự hiển thị
  created_at timestamptz default now()
);
alter table public.co_so enable row level security;

-- Ai đăng nhập cũng ĐỌC được (cần tên cơ sở để hiển thị khắp nơi);
-- chỉ Quản trị mới được thêm/sửa/xóa.
drop policy if exists cs_sel on public.co_so;
drop policy if exists cs_ins on public.co_so;
drop policy if exists cs_upd on public.co_so;
drop policy if exists cs_del on public.co_so;
create policy cs_sel on public.co_so for select to authenticated using (true);
create policy cs_ins on public.co_so for insert to authenticated with check (my_role()='admin');
create policy cs_upd on public.co_so for update to authenticated using (my_role()='admin') with check (my_role()='admin');
create policy cs_del on public.co_so for delete to authenticated using (my_role()='admin');

-- Nạp sẵn 14 cơ sở hiện có, đúng mã đang dùng.
-- on conflict do nothing: chạy lại KHÔNG đè lên tên/địa chỉ anh đã sửa trong app.
insert into public.co_so (id, ten, dc, build, thu_tu) values
  (0 ,'Diễn Liên'  ,''                                             ,false, 0),
  (1 ,'Diễn Hạnh'  ,''                                             ,false, 1),
  (2 ,'Diễn Hồng'  ,''                                             ,false, 2),
  (3 ,'Diễn Hồng 2',''                                             ,false, 3),
  (4 ,'Diễn Kỷ'    ,''                                             ,false, 4),
  (5 ,'Diễn Ngọc'  ,''                                             ,false, 5),
  (6 ,'Diễn Ngọc 2',''                                             ,false, 6),
  (7 ,'Diễn Tháp'  ,''                                             ,false, 7),
  (8 ,'Diễn Đồng'  ,''                                             ,false, 8),
  (9 ,'Diễn Hoa'   ,''                                             ,false, 9),
  (10,'Diễn Xuân'  ,''                                             ,false,10),
  (11,'Minh Châu'  ,''                                             ,false,11),
  (12,'Trung Dinh' ,''                                             ,false,12),
  (13,'Hợp Thành'  ,'Xóm Phụng Luật, Xã Yên Thành, tỉnh Nghệ An'   ,false,13)
on conflict (id) do nothing;

-- Bật realtime cho cả hai (sửa ở máy này, máy kia tự thấy)
do $$ begin
  begin execute 'alter publication supabase_realtime add table public.co_so';
  exception when others then null; end;
end $$;

-- ============================================================
-- Kiểm tra kết quả — cả 2 dòng phải đúng
-- ============================================================
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='cham_cong_gv' and column_name='gv_id')  as da_co_cot_gv_id,
  (select count(*) from public.cham_cong_gv where gv_id is not null)                     as buoi_da_gan_gv,
  (select count(*) from public.co_so)                                                    as so_co_so;

-- ============================================================
-- XONG. Kết quả đúng: da_co_cot_gv_id = 1, so_co_so = 14.
-- (buoi_da_gan_gv là số buổi chấm công cũ đã gán được giáo viên — bao nhiêu cũng được.)
-- Sau đó tải lại web (Ctrl+F5).
-- ============================================================
