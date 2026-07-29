-- ============================================================
-- AVATAR — XÓA DỮ LIỆU CHẠY THỬ (để bắt đầu nhập dữ liệu thật)
-- Dán toàn bộ vào Supabase → SQL Editor → bấm "Run". Sau đó vào web bấm Ctrl+F5.
--
--  • XÓA: học sinh đã ghi danh, phiếu thu–chi, điểm danh, chấm công (dữ liệu test).
--  • GIỮ NGUYÊN: giáo viên, lớp học (danh mục), tài khoản đăng nhập, phân quyền.
--
-- ⚠️ THAO TÁC NÀY KHÔNG HOÀN TÁC ĐƯỢC. Chỉ chạy khi chắc chắn muốn dọn sạch dữ liệu thử.
-- ============================================================

delete from public.so_quy;          -- phiếu thu / chi
delete from public.diem_danh_hv;     -- điểm danh học sinh
delete from public.cham_cong_gv;     -- chấm công giáo viên
delete from public.hoc_vien;         -- học sinh đã ghi danh

-- (Tùy chọn) Chỉ xóa của MỘT cơ sở, ví dụ Diễn Liên (coso_id = 0):
--   delete from public.so_quy      where coso_id = 0;
--   delete from public.diem_danh_hv where coso_id = 0;
--   delete from public.cham_cong_gv where coso_id = 0;
--   delete from public.hoc_vien    where coso_id = 0;

-- ============================================================
-- XONG. Bấm "Run". Vào web Ctrl+F5 → thông báo & số liệu về sạch.
-- ============================================================
