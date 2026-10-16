# English Quest

> Ghi chú ban đầu của repository: Lam on dung co pha gi het nha

## Chuyển sang máy Windows khác để chạy đồ án

Giải nén source, cài Flutter SDK + Git + .NET SDK 10 + Android Studio (plugin Flutter/Dart,
Android SDK Platform-Tools và một AVD). Đưa Flutter vào PATH, chấp nhận Android licenses khi được yêu cầu.
Mở SETUP-WINDOWS.cmd để kiểm tra và tự tạo database mới. Sau đó bật một emulator trong Android Studio,
mở CHAY-ANDROID.cmd. Không cần AVD tên English_Quest_API_36; script nhận thiết bị sẵn có.
Nếu nhiều thiết bị, dùng scripts/run-android.ps1 -DeviceId ID. Điện thoại thật cần USB debugging.
Backend và database chạy local trên máy mới, không cần SQL Server và không cần sao chép database.

Chỉ muốn chạy thử APK mà không sửa code: có thể tạo bộ demo Windows x64 tự chứa .NET runtime
bằng scripts/package-demo.ps1. Hướng dẫn: packaging/demo/DOC-TRUOC.md. Bộ này vẫn cần
Android Studio/emulator hoặc điện thoại USB; không phải app offline hay backend online dùng chung.

## Bản tài khoản mới (16/10/2026)

- Đăng ký/đăng nhập bằng tài khoản + mật khẩu; không còn đăng nhập chỉ bằng tên.
- Username 3–32 ký tự `[a-z0-9_]`, mật khẩu 10–128 ký tự có chữ và số.
- Tài khoản mới bắt đầu từ 0. Database mặc định: `backend_api/english-quest-accounts.db` (SQLite).
  Database `english-rpg.db` cũ không nhập sang và không bị xóa.
- EXP, trường mục tiêu, tiến độ ải và sổ ôn luyện lưu trên backend. Các app phải dùng **cùng API/database**
  để đồng bộ giữa máy; mỗi người chạy backend riêng không tự đồng bộ.
- Đăng xuất tại trang chủ. Token chỉ giữ trong bộ nhớ app; mở lại app phải đăng nhập.
  Chưa có khôi phục/đổi mật khẩu. Chỉ dùng mật khẩu demo, không dùng mật khẩu quan trọng.
- Chạy `scripts/run-backend.ps1` trước để tạo database/nạp câu hỏi, rồi `scripts/run-android.ps1`.
  Máy khác cần .NET 10, Flutter SDK, Android Studio + plugin Flutter/Dart và máy ảo Android phù hợp.
  Tên AVD trong script dành cho máy gốc; máy khác có thể chạy emulator riêng từ Android Studio.
- API đăng nhập: `/api/auth/register`, `/api/auth/login`, `/api/auth/logout`.
  API dữ liệu cần `Authorization: Bearer <token>`. `/api/players/login` cũ đã vô hiệu hóa.
- Bảo vệ ownership cho player/attempt; password băm bằng ASP.NET Core PasswordHasher;
  token ngẫu nhiên, DB chỉ giữ hash, hạn 7 ngày. Nhập sai 5 lần khóa 5 phút, giới hạn theo IP.
- Production bắt buộc HTTPS; HTTP chỉ cho Development local. Chưa có host công khai.
  Không đưa SQLite lên filesystem tạm của hosting; cần ổ bền vững/sao lưu hoặc SQL Server.
- SQL Server có migration `AddAccountsAndPractice`, chưa được thử trên SQL Server thật.
  Kiểm tra API bằng PowerShell 7: `scripts/test-accounts.ps1` (tạo tài khoản test_ riêng).

Các mô tả đăng nhập chỉ theo tên/lưu sổ cục bộ trong tài liệu cũ đã được thay bằng phần này.

## Android và iOS

Đây là Flutter mobile app có project native `flutter_app/android` và `flutter_app/ios`. Web dùng để xem nhanh giao diện. Font tiếng Việt được đóng gói trong app, không cần tải Google Fonts khi mở.

**Android Studio:** mở `flutter_app` bằng File → Open (cài plugin Flutter nếu cần); Device Manager → bật `English_Quest_API_36`. Hoặc chạy `powershell -ExecutionPolicy Bypass -File .\scripts\run-android.ps1` để tự bật backend, emulator và app. Emulator cần driver tăng tốc chạy được. API emulator: `http://10.0.2.2:5137/api`.

**Android USB:** bật Developer options và USB debugging, cắm điện thoại, chấp nhận máy tính trên điện thoại, chạy `adb devices` để lấy ID. Giữ backend chạy, sau đó `powershell -ExecutionPolicy Bypass -File .\scripts\run-android-usb.ps1 -DeviceId ID`. Script dùng adb reverse nên không cần mở firewall hay cùng Wi-Fi.

**APK:** `powershell -ExecutionPolicy Bypass -File .\scripts\build-android.ps1 -ApiBaseUrl http://10.0.2.2:5137/api` để build cho emulator; dùng `http://127.0.0.1:5137/api` cho điện thoại qua USB + adb reverse. File ở `flutter_app/build/app/outputs/flutter-apk/app-release.apk`. Bản release này ký bằng debug key để demo đồ án, chưa phải bản phát hành store.

**iOS (iOS 15+):** cần máy Mac có Flutter và Xcode. Chép source sang Mac, chạy `flutter pub get` rồi mở `flutter_app/ios/Runner.xcworkspace` bằng Xcode. Với iPhone thật, chọn Team trong Signing & Capabilities và bật Developer Mode trên iPhone. Chạy `flutter devices` để lấy ID rồi `API_BASE_URL=http://IP-MAY-CHAY-BACKEND:5137/api bash scripts/run-ios.sh DEVICE_ID`. Nếu backend nằm ngay trên Mac và dùng Simulator, URL là `http://127.0.0.1:5137/api`.

Điện thoại/iOS Simulator dùng backend ở máy Windows phải cùng mạng với máy Windows, backend lắng nghe `0.0.0.0:5137` (script run-backend đã cấu hình), và firewall cho phép kết nối cổng 5137. Trên iPhone, cho phép Local Network khi được hỏi. `localhost` trên điện thoại là chính điện thoại, không phải máy Windows.

iOS cho phép HTTP để demo backend nội bộ; nếu đưa lên store, thay backend bằng HTTPS và bỏ ngoại lệ `NSAllowsArbitraryLoads` trong Info.plist. Source iOS được chuẩn bị nhưng chỉ có thể xác nhận build/chạy sau khi thử trên Mac/Xcode.

## Chạy trên máy đã được setup

Trên Desktop có hai shortcut: **English Quest - Chay app** để chạy backend và mở Flutter trên Chrome, **English Quest - Mo code** để mở source trong VS Code. Giữ cửa sổ chạy app mở trong lúc sử dụng. Có thể chạy tương đương bằng `powershell -ExecutionPolicy Bypass -File .\scripts\start-app.ps1`.

Máy đã có Flutter, .NET SDK 10, Android Studio, Android SDK 36, Java và các extension Flutter/C# trong VS Code. Emulator `English_Quest_API_36` và driver tăng tốc AEHD đã cài, kiểm tra được. Shortcut **English Quest - Android** mở app native trên emulator; **English Quest - Android Studio** mở source trong IDE.

Android Studio đã cài plugin Flutter và Dart; đóng rồi mở lại Studio một lần để nạp Dart mới. Nếu IDE hỏi Flutter SDK, chọn `C:\Users\Admin\Documents\Codex\toolchains\flutter`. Chọn `emulator-5554`/`English_Quest_API_36` và mở `lib/main.dart` để chạy. Khi chạy từ IDE trên emulator, API mặc định dùng `10.0.2.2` nên không cần dart-define. Giữ backend đang chạy. Script run-android dùng Skia thay Impeller để tương thích bộ đồ họa emulator trên máy này.

Kiểm tra trên Android emulator: `cd flutter_app` rồi `flutter test integration_test/mobile_smoke_test.dart -d emulator-5554 --no-enable-impeller --dart-define=API_BASE_URL=http://10.0.2.2:5137/api`. Test tạo người chơi demo riêng, kiểm tra đăng nhập, chọn trường, bản đồ, tải câu hỏi và trả lời; không sửa tiến độ người chơi đang dùng.

Ứng dụng luyện thi tiếng Anh theo phong cách RPG: Flutter ở phía người chơi, ASP.NET Core Web API ở phía server và SQL Server lưu tiến độ.

## Cần cài trên Windows

- Git và VS Code.
- Flutter stable; chạy được lệnh `flutter doctor`.
- .NET SDK 10.x.
- Android Studio + Android SDK nếu chạy emulator.
- Không cần cài database để chạy local: mặc định dự án dùng SQLite.

Sau khi cài Android Studio, mở **SDK Manager** và cài Android SDK, Platform Tools, Command-line Tools và một emulator. Sau đó chạy:

```powershell
flutter doctor
flutter doctor --android-licenses
```

## Setup dự án lần đầu

Mở thư mục repo bằng VS Code, mở Terminal và chạy:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
```

Script sẽ tạo phần Android còn thiếu, tải package, analyze/test Flutter và build backend.

Backend mặc định tạo file `backend_api/english-rpg.db`. Nếu cần dùng SQL Server đúng mô hình triển khai ban đầu, đổi `DatabaseProvider` thành `SqlServer` trong `backend_api/appsettings.json` và cập nhật connection string `SqlServer`.

## Chạy nhanh trên web

Mở hai terminal:

```powershell
.\scripts\run-backend.ps1
```

```powershell
.\scripts\run-web.ps1
```

Hoặc trong VS Code: **Terminal → Run Task** rồi chạy `1. Backend + seed`, sau đó `2. Flutter web`.

## Chạy trên Android Emulator

1. Mở Android Studio → Device Manager → bật emulator.
2. Giữ backend đang chạy.
3. Chạy:

```powershell
.\scripts\run-android.ps1
```

Android Emulator dùng `10.0.2.2` để gọi backend trên máy Windows. Nếu chạy điện thoại thật, dùng lệnh dưới với IP LAN của máy tính:

```powershell
cd flutter_app
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5137/api
```

Nhớ thay `192.168.1.10` và cho phép cổng 5137 qua Windows Firewall.

## Cấu trúc

- `flutter_app/lib/screens`: các màn hình.
- `flutter_app/lib/services`: gọi API; URL nhận từ `API_BASE_URL`.
- `flutter_app/lib/theme`: màu sắc và typography.
- `backend_api`: API, Entity Framework và seed 90 câu hỏi.
- `scripts`: setup và chạy dự án.
