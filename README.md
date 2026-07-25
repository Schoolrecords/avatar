# AVATAR Center — Hệ thống quản trị chuỗi (Bản demo giao diện)

Giao diện quản trị nội bộ cho **Trung tâm Anh ngữ AVATAR** (Nghệ An): quản lý **15 cơ sở thành viên + 1 Trung tâm chính**, tập trung vào **giáo viên, lớp học, học sinh** và **quản lý các khoản thu học phí**.

- Tông màu **xanh navy** chủ đạo, thiết kế **mobile-first**, dùng tốt trên cả điện thoại và máy tính.
- Công nghệ: **HTML + CSS + JavaScript thuần**, không cần máy chủ, không cần build. Chạy tốt trên GitHub Pages ở đường dẫn con.

## Phân quyền (3 vai trò)

| Vai trò | Phạm vi | Chức năng |
|---|---|---|
| **Giám đốc** (admin) | Toàn hệ thống | Xem/tổng hợp toàn bộ 16 cơ sở; chọn xem từng cơ sở qua bộ lọc "Cơ sở" |
| **Lễ tân** (chủ cơ sở) | Cố định 1 cơ sở | Quản lý giáo viên, lớp, học sinh, khoản thu của cơ sở mình |
| **Giáo viên** | Cố định 1 cơ sở | Xem lớp học và học sinh; không thấy khoản thu |

## Chức năng

- **Bảng điều hành** — KPI (giáo viên, học sinh, lớp, đã thu / còn nợ trong tháng), biểu đồ doanh thu theo cơ sở, danh sách công nợ cần nhắc.
- **Cơ sở** — danh mục 15 chi nhánh + Trung tâm chính (chỉ Giám đốc).
- **Giáo viên / Lớp học / Học sinh** — danh sách, tìm kiếm, lọc, thêm mới.
- **Khoản thu** ⭐ — theo dõi học phí theo tháng: phải đóng / đã đóng / còn nợ, tỷ lệ thu, nút "Thu đủ", lọc theo tháng và trạng thái.
- **Báo cáo** — tổng hợp doanh thu theo cơ sở và xu hướng 3 tháng.

## Chạy thử

Mở trực tiếp `index.html` bằng trình duyệt, hoặc truy cập bản đã triển khai trên GitHub Pages. Chọn vai trò ở màn đăng nhập để xem quyền hạn khác nhau.

## Lộ trình

- **Giai đoạn 1 (hiện tại):** Giao diện hoàn chỉnh, chạy bằng **dữ liệu mẫu**, lưu tạm bằng `localStorage` của trình duyệt — dùng để Trung tâm duyệt giao diện & luồng.
- **Giai đoạn 2:** Kết nối kho dữ liệu thật **Supabase** (đăng nhập, phân quyền theo cơ sở, lưu dữ liệu tập trung cho 16 cơ sở).
- **Giai đoạn 3:** Tạo tài khoản cho Giám đốc + 15 Lễ tân, nhập dữ liệu thật, đưa vào vận hành.

## Lưu ý về dữ liệu

- Đây là **bản demo giao diện**: mọi giáo viên, lớp, học sinh, khoản thu đều là **dữ liệu mẫu**, không phải thông tin thật.
- Dữ liệu thêm/sửa trong phiên được lưu tạm bằng `localStorage`; xóa dữ liệu duyệt web sẽ xóa các thay đổi này.

## Cấu trúc

| File | Vai trò |
|------|---------|
| `index.html` | Toàn bộ hệ thống quản trị (đăng nhập + 7 module). |
| `trung-tam-dieu-hanh.html` | Tự chuyển hướng về `index.html` (giữ tương thích đường dẫn cũ). |
| `HUONG_DAN.txt` | Ghi chú đưa demo lên GitHub Pages. |
