# English Quest — demo mobile trên máy Windows khác

Đây là app Android thật (Android 7/API 24 trở lên), kèm backend Windows 10/11 64-bit đã đóng gói runtime.
Không cần mang database cũ, không cần cài SQL Server/.NET/Flutter nếu chỉ chạy thử bộ demo này.
Vẫn cần Android Studio + Android SDK và máy ảo Android (hoặc điện thoại Android cắm USB).
Lần cài Android Studio/SDK/máy ảo cần Internet; ảo hóa CPU phải được bật để chạy emulator.

## Chạy

1. Giải nén **toàn bộ ZIP** vào thư mục có quyền ghi, ví dụ Documents/EnglishQuest. Không chạy bên trong ZIP.
2. Mở `CHAY-BACKEND.cmd`. Lần đầu tự tạo `data/english-quest-accounts.db` và dữ liệu câu hỏi.
   Giữ cửa sổ này mở. Không cần quyền Administrator. Cổng local mặc định 5137.
3. Bật **một** máy ảo Android từ Device Manager của Android Studio. Không cần đặt tên giống máy gốc.
4. Mở `CAI-VA-MO-APP.cmd`: tự cài APK, nối thiết bị với backend local bằng ADB reverse và mở app.
5. Chọn Đăng ký để tạo tài khoản mới. Tên 3–32 chữ không dấu/số/_, mật khẩu 10–128 ký tự có chữ và số.

`English-Quest-Local.apk` có ARM 32-bit, ARM64 và x86_64 cho emulator/điện thoại tương thích.
Bản này trỏ `http://127.0.0.1:5137/api`, do đó **phải** chạy bước nối ADB ở máy đang test.
Nếu cài APK bằng cách kéo thả vào emulator vẫn cần chạy `adb reverse tcp:5137 tcp:5137`.
Sau mỗi lần tắt/bật máy ảo hoặc rút/cắm lại USB, chạy lại CAI-VA-MO-APP.cmd để nối lại.

Với điện thoại thật: bật Developer options → USB debugging, cắm USB và chấp nhận máy tính.
Giữ kết nối USB trong lúc demo. Chưa có bản tự kết nối server online; APK không chạy độc lập/offline.

## Dữ liệu

- Mỗi máy tính tự có database riêng, tài khoản mới và tiến độ mới. Không đồng bộ giữa các máy tính.
- Mở lại backend giữ nguyên dữ liệu đã tạo, không reset tài khoản mỗi lần chạy.
- Backend chỉ lắng nghe loopback, không tự mở firewall hay đưa app ra Internet.
- Đây là cấu hình Development local, dùng mật khẩu riêng cho demo, không dùng mật khẩu quan trọng.
- Tắt bằng Ctrl+C trong cửa sổ backend. Không xóa thư mục data nếu muốn giữ tiến độ trên máy đó.

## Khi gặp lỗi

- Cổng 5137 bận: dừng backend cũ trước, không mở hai backend cùng lúc.
- Không thấy thiết bị: mở khóa điện thoại/đợi emulator boot xong; kiểm tra `adb devices`.
- Nhiều thiết bị: đóng bớt hoặc dùng `powershell -ExecutionPolicy Bypass -File .\install-demo.ps1 -DeviceId ID`.
- Không tìm thấy adb: Android Studio → SDK Manager → SDK Tools → Android SDK Platform-Tools.
  SDK đặt ở chỗ khác thì khai báo ANDROID_HOME hoặc đưa adb vào PATH.
- APK trùng chữ ký với bản cũ: tự gỡ bản cũ nếu đồng ý rồi cài lại; script không tự gỡ/xóa dữ liệu.
- Backend không chạy: kiểm tra Windows là x64, đã giải nén đủ thư mục server, phần mềm bảo vệ không chặn file.
  Không tự tắt phần mềm bảo vệ; xác minh file rồi xử lý theo chính sách máy.

Để đọc/sửa code trong Android Studio, dùng gói SOURCE riêng: cần thêm Flutter SDK, Git và .NET SDK 10.
Đây không phải bộ cài cho macOS/Linux; các máy đó cần build/chạy backend từ source phù hợp hệ điều hành.
