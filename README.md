# AVATAR Center — Hệ thống quản trị chuỗi

Giao diện quản trị nội bộ cho **Trung tâm Anh ngữ AVATAR** (Nghệ An): quản lý chuỗi cơ sở thành viên, tập trung vào **giáo viên, lớp học, học sinh, học phí** và **điểm danh – đối soát**.

- Tông màu **xanh navy** chủ đạo, thiết kế **mobile-first**, dùng tốt trên điện thoại và máy tính; cài được như ứng dụng (PWA).
- Frontend: **HTML + CSS + JavaScript thuần**, không cần build, chạy trên GitHub Pages.
- Backend: **Supabase** (Postgres + Auth + RLS + Realtime) — dữ liệu tập trung, đồng bộ mọi máy theo thời gian thực.

## Phân quyền (3 vai trò)

| Vai trò | Phạm vi | Chức năng chính |
|---|---|---|
| **Giám đốc** (`admin`) | Toàn hệ thống | Xem/tổng hợp mọi cơ sở; lọc theo từng cơ sở; quản lý GV/lớp/HS/khoản thu; tạo & quản lý tài khoản giáo viên; **chốt** số liệu điểm danh. |
| **Lễ tân** (`owner`) | Cố định 1 cơ sở | Quản lý GV, lớp, học sinh, khoản thu của cơ sở mình; điểm danh & **đối soát**. |
| **Giáo viên** (`teacher`) | Lớp được phân công | Xem lớp mình phụ trách, **ghi danh** (thêm học sinh) và **điểm danh**; gửi đối soát. Không thấy khoản thu, không thấy lớp/cơ sở khác. |

Phân quyền được khóa ở tầng CSDL bằng **RLS** (Row Level Security) theo `role` và `coso_id`/`gv_id`.

## Chức năng

- **Bảng điều hành** — KPI (dự thu / đã thu học phí, học sinh đang học, lớp), tài chính học phí, chuyên cần (30 ngày gần nhất), điểm danh hôm nay, cảnh báo điều hành, hoạt động gần đây.
- **Cơ sở** — danh mục cơ sở + trang chi tiết từng cơ sở (chỉ Giám đốc).
- **Giáo viên / Lớp học / Học sinh** — danh sách, tìm kiếm, lọc, thêm/sửa, phân công lớp, nhập Excel hàng loạt.
- **Ghi danh & Điểm danh** — ghi danh học sinh vào lớp; điểm danh học sinh + chấm công giáo viên từng buổi.
- **Đối soát** — luồng duyệt: Giáo viên gửi → Lễ tân đối soát → Quản trị **chốt** (khóa số liệu ca dạy).
- **Thu – Chi** — sổ quỹ thu–chi theo hạng mục, tồn quỹ, lập/**sửa**/xóa phiếu thu–chi (in & tải Word). Số hiệu phiếu chuẩn `PT-02-2607-001` (trigger CSDL sinh, mỗi cơ sở một dãy theo tháng), tách **người nộp/nhận tiền** khỏi người lập phiếu, **hình thức thanh toán** tiền mặt / chuyển khoản, gợi ý **chi lương theo số buổi chấm công** của giáo viên.
  - **Học phí thu theo đợt** — mỗi lần phụ huynh nộp là một phiếu thu riêng, giữ đủ lịch sử; số đã đóng và còn phải thu tự tính từ các phiếu.
  - **In sổ quỹ** ngay trên web (A4 nằm ngang, kẻ ô, lặp tiêu đề, khối ký) và **Xuất Excel** theo mẫu sổ quỹ kế toán: đầu sổ đơn vị + mẫu số S05-DNN, số dư đầu kỳ – phát sinh – số dư cuối kỳ, tồn quỹ lũy kế, số tiền bằng chữ; kèm sheet tổng hợp theo hạng mục và theo cơ sở.
  - **Chốt sổ theo tháng** (Quản trị) — kỳ đã chốt khóa hoàn toàn với mọi vai trò ở tầng CSDL; có mở khóa khi cần sửa.
- **Tài khoản giáo viên** (chỉ Giám đốc) — tạo/đổi mật khẩu/khóa/xóa tài khoản GV (qua Edge Function `quan-ly-tk`).
- **In ấn hồ sơ (A4, in ngay trên web)** — mỗi bản in lấy **đúng danh sách đang xem** (theo bộ lọc trên màn hình), có tiêu đề đơn vị, dòng tổng hợp, ngày tháng và khối ký; bảng dài tự lặp tiêu đề và chừa lề mỗi trang. Danh sách nhiều cơ sở được **tách thành nhiều tờ — mỗi cơ sở (hoặc mỗi lớp) một tờ riêng để ký lưu hồ sơ**.

  | Bản in | Nơi bấm | Khổ | Tách tờ |
  |---|---|---|---|
  | Danh sách giáo viên (có cột ký tên) | Giáo viên → 🖶 In danh sách | A4 dọc | theo cơ sở |
  | Danh sách lớp học (GV, sĩ số, lịch, dự thu) | Lớp học → 🖶 In danh sách | A4 dọc | theo cơ sở |
  | Danh sách học sinh của lớp | Học sinh → 🖶 In danh sách | A4 dọc | theo lớp |
  | Bảng theo dõi thu học phí (đã đóng / còn phải thu) | Học sinh → 🖶 In học phí | A4 ngang | theo cơ sở |
  | Tổng hợp quy mô & học phí các cơ sở | Cơ sở → 🖶 In tổng hợp | A4 ngang | một tờ |
  | Báo cáo chuyên cần học sinh | Báo cáo → 🖶 In chuyên cần | A4 ngang | một tờ |
  | Biên bản đối soát ca dạy | Đối soát → 🖶 In biên bản | A4 ngang | một tờ |
  | Danh sách tài khoản GV (cột ký nhận, **không in mật khẩu**) | Tài khoản → 🖶 In danh sách | A4 dọc | một tờ |

  Ngoài ra đã có sẵn: **phiếu thu/chi**, **sổ quỹ**, **bảng thanh toán công giảng dạy**, **danh sách điểm danh từng buổi**, **lịch dạy theo ca**, **trang hướng dẫn sử dụng**.
- **Hướng dẫn sử dụng** — hướng dẫn hiển thị **theo vai trò đang đăng nhập** (Giám đốc xem được cả 3 bản để in phát cho nhân viên): 3 việc đầu tiên, sơ đồ quy trình một buổi dạy, menu có gì, thao tác từng bước, cách hệ thống tính số liệu, hỏi đáp – xử lý sự cố. Có nút **In / lưu PDF**.

## Cấu trúc

| File | Vai trò |
|------|---------|
| `index.html` | Toàn bộ ứng dụng (đăng nhập + các module). |
| `data.js` | Dữ liệu giáo viên/lớp gốc (đã nạp vào Supabase ở Giai đoạn 2; giữ để đối chiếu id). |
| `supabase-schema.sql` | Tạo bảng nền + RLS. |
| `sql-giai-doan-2.sql` … `sql-giai-doan-5-thu-chi.sql` | Các bước migration theo giai đoạn (GV/lớp sống, vai trò GV, luồng đối soát, hoàn thiện sổ quỹ). |
| `sql-*.sql` khác | Bổ sung cột (ngày nhập/thôi học, ngày đóng, số tiền đóng, hợp đồng GV…), dọn dữ liệu thử. |
| `edge-function-quan-ly-tk.ts` | Edge Function quản lý tài khoản giáo viên (deploy trên Supabase). |
| `supabase.min.js` | Thư viện Supabase (tự host — không phụ thuộc CDN). |
| `xlsx.full.min.js`, `exceljs.min.js` | Thư viện Excel (tự host). |
| `fonts/` | Font thương hiệu UTM Avo (tự host). |

## Vận hành

1. Chạy các file `sql-*.sql` trong Supabase → SQL Editor theo thứ tự giai đoạn (an toàn khi chạy lại — dùng `if not exists`).
2. Deploy Edge Function `quan-ly-tk`.
3. Tạo tài khoản Giám đốc/Lễ tân trong Authentication, gán `role`/`coso_id` trong bảng `profiles`.
4. Đăng nhập tại `index.html`. Tên đăng nhập ngắn sẽ tự thêm đuôi `@avatar.vn`.

> Lưu ý: dữ liệu hiện là **dữ liệu vận hành thật** lưu tập trung trên Supabase (không còn dùng dữ liệu mẫu/localStorage).
