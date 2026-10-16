# Bản Android để cài thử

`English-Quest-Local.apk` là bản APK đã build trước đó, không tự cập nhật khi sửa source.

- APK dùng backend tại `http://127.0.0.1:5137/api` trong thiết bị Android.
- Máy tính cần chạy backend. Thiết bị cần kết nối ADB và chuyển tiếp cổng bằng `adb reverse tcp:5137 tcp:5137`.
- Đây không phải bản offline hoặc bản đã kết nối server online.
- Với source này, chạy `SETUP-WINDOWS.cmd` lần đầu, sau đó `CHAY-ANDROID.cmd` để chạy thử. Đọc README ở thư mục gốc để biết công cụ cần cài.
- Muốn tạo lại bộ APK và backend đóng gói, dùng `scripts/package-demo.ps1` với thư mục đầu ra mới.

APK được bỏ qua trong Git để giữ kho source nhẹ. Khi push source xong, tải APK này lên phần GitHub Releases để người khác tải về.
