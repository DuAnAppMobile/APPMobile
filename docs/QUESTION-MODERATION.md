# Xử lý câu lỗi: chỉ bù quyền lợi

Trong Admin → Câu hỏi, nút xử lý ở cuối mỗi câu kiểm tra số lượt liên quan trước. Câu chưa được dùng vẫn xóa hẳn được. Với câu đã dùng, Admin chọn và ghi lý do:

- Ngừng dùng, giữ lịch sử: câu không được chọn trong lượt mới, lịch sử giữ nguyên.
- Sửa đáp án, chấm bù: lưu đáp án điều chỉnh trên bản cũ, tạo câu thay thế với đáp án mới cho lượt sau. Những lựa chọn đã được chấm đúng vẫn được tính đúng; người chọn đáp án sửa được công nhận thêm. Hoàn phí Hint 2 của câu được điều chỉnh có lợi.
- Hủy câu lỗi: lưu dấu vết, tính câu đó đúng cho các lượt liên quan, kể cả câu bỏ trống. Hoàn phí Hint 2. Không xóa lượt chơi.

Chỉ xử lý thưởng cho lượt đã hoàn thành. Lượt đang chơi áp dụng khi gửi đáp án/kết thúc. Lượt hết hạn không được hồi sinh. Lượt Boss đã thua vì quá thời gian không chuyển thành thắng.

EXP chỉ cộng phần chênh lệch dương. Không hạ số đúng, không thu hồi qua ải, huy hiệu, mục tiêu trường hay EXP. Có thể công nhận thêm qua ải và huy hiệu. Boss vẫn chỉ thưởng một lần mỗi người. Gửi lặp yêu cầu không cộng thưởng lần nữa.

Lịch sử trả `compensationExp`, `hasAdjustedQuestions`; giao diện hiển thị ghi chú bù EXP. Câu bị hủy/điều chỉnh được đánh dấu khi xem lại câu. Bản gốc không bị sửa nội dung/đáp án gốc sau khi đã được dùng: chỉnh sửa thông thường tạo phiên bản thay thế và giữ kết quả cũ. Muốn bù lịch sử cần dùng thao tác xử lý câu lỗi.

Ngừng/hủy câu có thể làm kho dưới 10 câu thường hoặc 15 câu Boss; hộp thoại cảnh báo và Admin cần thêm câu hợp lệ thay thế để bắt đầu lượt mới. Trạng thái các ải đã mở vẫn giữ nguyên. Công tắc “Hiện câu đã ngừng / đã hủy” cho phép xem các bản cũ.

SQLite được nâng cấp thêm cột tự động, giữ dữ liệu cũ (hỗ trợ cả database trước đây tạo bằng EnsureCreated). Có migration QuestionModeration cho schema EF. Trước khi cập nhật máy đang dùng, giữ bản sao database đã dừng backend. Seed không ghi đè câu Admin đã sửa.

Kiểm tra backend trên database riêng trong thư mục tạm:

```powershell
dotnet build backend_api/EnglishRpg.Api.csproj -o backend_api/bin/moderation-check
pwsh -File scripts/test-question-moderation.ps1
```

Các API Admin mới: GET `questions/{id}/impact`, POST `questions/{id}/resolve` với mode retire/correct/void, reason và correctOption khi sửa đáp án. Quyền Admin vẫn kiểm tra tại server; toàn bộ bù thưởng nằm trong transaction.
