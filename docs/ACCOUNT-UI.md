# Hồ sơ và bảo mật tài khoản

Trang chủ → biểu tượng Hồ sơ: thông tin cá nhân, chọn avatar, huy hiệu, lịch sử và bảo mật. Tài khoản có role Admin còn thấy Kho câu hỏi (thêm/sửa/xóa). API vẫn kiểm tra role ở server. Xóa câu đã được dùng trả 409 và giao diện giải thích lý do.

Admin đăng nhập sẽ vào thẳng không gian quản trị riêng, bỏ qua chọn trường/trang chủ người chơi. Ba mục Tổng quan, Câu hỏi, Tài khoản cung cấp số lượng câu theo ải, tìm kiếm/lọc, CRUD và bảo mật/đăng xuất. Tổng quan lấy số liệu thật từ ngân hàng câu hỏi; chưa có API thống kê người dùng nên không hiển thị thống kê người dùng.

Flutter dùng AccountApi → AuthClient để gắn Bearer token; không dùng Axios/Dio. Token và role chỉ giữ trong bộ nhớ. 401 yêu cầu đăng nhập lại, 403 thông báo thiếu quyền.

## Đổi và khôi phục mật khẩu

- POST /api/auth/change-password: currentPassword, newPassword. Cần đăng nhập và mật khẩu hiện tại. Hủy tất cả phiên và mã khôi phục sau thành công.
- POST /api/auth/recovery-code: currentPassword. Cần đăng nhập và mật khẩu hiện tại. Trả mã ngẫu nhiên 32 byte chỉ một lần, hạn 90 ngày. Mã mới thay mã cũ.
- POST /api/auth/reset-password: username, code, newPassword. Không cần đăng nhập; cần mã đã lưu trước. Mã dùng một lần, hủy mọi phiên khi reset và gỡ khóa đăng nhập.
- Giao diện Quên mật khẩu nằm ở trang đăng nhập. Chưa có email khôi phục. Nếu chưa tạo hoặc đã mất mã, không thể tự khôi phục trong app.
- Chỉ lưu hash mã trong LoginSessions, dùng tiền tố R để tách với hash phiên (hex), không thay schema database. Mã khôi phục không thể dùng làm Bearer token. Không ghi mã hay mật khẩu vào log.

Luồng được tham khảo từ cơ chế reset token và recovery code của ASP.NET Core Identity: https://github.com/dotnet/aspnetcore/blob/main/src/Identity/Core/src/IdentityApiEndpointRouteBuilderExtensions.cs . Dự án dùng session tự quản lý nên đây là triển khai phù hợp với schema hiện có, không thay toàn bộ hệ thống sang Identity.

Hiệu ứng: màn hồ sơ hiện dần và trượt nhẹ, chuyển trang fade/slide trên Android; tôn trọng tùy chọn giảm chuyển động của thiết bị. iOS giữ chuyển trang native.
