# English Quest — Source chia sẻ

Thư mục này chứa source Flutter, backend ASP.NET Core, tài nguyên giao diện, kiểm thử và script Windows.

## Chạy trên máy khác

1. Cài Git, Flutter SDK, .NET SDK 10, Android Studio và Android SDK. Thêm Flutter vào PATH.
2. Tạo máy ảo Android trong Android Studio hoặc kết nối điện thoại có USB debugging.
3. Chạy `SETUP-WINDOWS.cmd` và đọc thông báo kiểm tra môi trường.
4. Chạy `CHAY-ANDROID.cmd`. Script hỗ trợ khởi động backend, chờ máy ảo và thiết lập kết nối cổng.
5. Tạo tài khoản mới trong app. Database được tạo trên máy chạy backend, không kèm dữ liệu tài khoản của máy cũ.

Để sửa giao diện bằng Android Studio, mở thư mục `flutter_app`. Không chọn Windows desktop làm thiết bị chạy; chọn máy Android.

## Chia sẻ qua GitHub

- Repository dự kiến: https://github.com/huy270856/Lap-Trinh-MobileApp
- Source nằm ngay thư mục gốc của repository.
- Bản APK có sẵn trong `App-Android`; đưa lên GitHub Releases. APK bị Git bỏ qua có chủ đích.
- Không có database tài khoản, file khóa ký app hoặc thư mục build trong bộ source.
- GitHub lưu source/APK, không tự chạy backend. Chưa cấu hình hosting online.

Xem `README.md` để biết thêm hướng dẫn chạy và cấu trúc dự án.
