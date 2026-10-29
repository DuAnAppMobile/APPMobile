# Dự án: App luyện thi tiếng Anh Gamified

## Tech Stack
- Frontend: Flutter (Dart)
- Backend: ASP.NET Core Web API (C#)
- Database: SQL Server + Entity Framework Core
- Cấu trúc thư mục: Tách riêng `flutter_app/` (UI) và `backend_api/` (Server)

## Quy tắc làm việc
- Đọc file `docs/SPEC.md` để nắm rõ yêu cầu.
- Server chấm điểm và tính EXP, client chỉ hiển thị.
- Không tự ý thêm tính năng ngoài spec.
- Khi tạo code, hãy tạo từng phần nhỏ, dừng lại để tôi kiểm tra.
- Luôn ưu tiên chạy được trên môi trường localhost trước.

## Quy tắc tìm kiếm giải pháp (Tham khảo Open Source)
Đối với bất kỳ tính năng mới nào chưa được định nghĩa chi tiết trong dự án, hoặc khi gặp một bài toán kiến trúc chưa quen thuộc:
1. Tuyệt đối KHÔNG tự bịa ra kiến trúc phức tạp từ con số 0.
2. Hãy chủ động tìm kiếm các dự án mã nguồn mở (open-source) trên GitHub có tính năng tương tự để tham khảo cách họ thiết kế Database, API và xử lý logic.
3. Đề xuất phương án tối ưu nhất dựa trên các thực tiễn tốt nhất (best practices) trước khi viết code.