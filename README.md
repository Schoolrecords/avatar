# AVATAR Center 360 — Bản demo

Demo giao diện cho **Trung tâm Anh ngữ AVATAR** (Nghệ An), gồm hai khu vực trong cùng một trang:

1. **Website thương hiệu** — dành cho phụ huynh và học viên (giới thiệu, chương trình, lộ trình, đăng ký học thử / kiểm tra đầu vào).
2. **Trung tâm điều hành** — dành cho lãnh đạo, quản lý, giáo viên, nhân viên (bảng điều hành, học viên, lớp học, tuyển sinh, học phí, điểm danh, tiến bộ, nhân sự, báo cáo…).

Công nghệ: **HTML + CSS + JavaScript thuần**, không cần máy chủ, không cần build. Toàn bộ đường dẫn là tương đối nên chạy tốt trên GitHub Pages ở đường dẫn con.

## Cấu trúc

| File | Vai trò |
|------|---------|
| `index.html` | Trang chính, mở vào **Website thương hiệu**. Chứa đầy đủ cả khu điều hành, chuyển qua lại bằng thanh dưới màn hình. |
| `trung-tam-dieu-hanh.html` | Bản mở thẳng vào **Trung tâm điều hành** (nội dung giống `index.html`). |
| `HUONG_DAN.txt` | Ghi chú đưa demo lên GitHub Pages. |

## Chạy thử

Mở trực tiếp `index.html` bằng trình duyệt, hoặc truy cập bản đã triển khai trên GitHub Pages.

## Phân quyền minh họa

Trong Trung tâm điều hành có thể đổi vai trò để xem menu/chức năng thay đổi theo nhóm: **Giám đốc, Quản lý chuyên môn, Tư vấn viên, Giáo viên, Kế toán**.

## Lưu ý về dữ liệu

- Đây là **bản demo**: mọi số liệu, học viên, phụ huynh, nhân sự đều là **dữ liệu mẫu**, không phải thông tin thật.
- Dữ liệu thêm mới trong phiên (học viên, Lead, nhân sự, vai trò đang chọn) được lưu tạm bằng **localStorage** của trình duyệt để không mất khi tải lại trang; xóa dữ liệu duyệt web sẽ xóa các mục này.
- Khi triển khai thật cần kết nối cơ sở dữ liệu / API cho: học viên, lớp học, học phí, điểm danh, điểm số, tuyển sinh, nhân sự, báo cáo và thông báo phụ huynh.
