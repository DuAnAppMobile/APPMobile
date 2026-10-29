# SPEC.md: English Quest – ứng dụng luyện tiếng Anh gamified

> Tài liệu này mô tả phiên bản đang có trong repository. Ứng dụng Flutter gọi ASP.NET
> Core Web API; backend dùng SQLite tại `backend_api/english-quest-accounts.db`. Người
> chơi đăng ký/đăng nhập bằng username và mật khẩu; API được bảo vệ bằng session bearer
> token, còn thao tác quản trị câu hỏi yêu cầu role `Admin`. Nội dung Ôn luyện hiện được
> cung cấp riêng với nội dung ải/Boss. Backend hiện phục vụ local/demo; chưa có host
> công khai. Ứng dụng giữ token trong bộ nhớ, vì vậy cần đăng nhập lại sau khi khởi động
> lại app.

# 1. Tổng quan

- **Sản phẩm:** Ứng dụng Flutter học tiếng Anh theo mô hình RPG nhẹ; hiện hỗ trợ Android và Flutter Web để chạy thử.
- **Người dùng:** Người chơi đăng ký bằng tài khoản (username) và mật khẩu; mỗi tài khoản có hồ sơ người chơi riêng. Tài khoản thông thường có role `User`; role `Admin` dành cho chức năng quản trị câu hỏi.
- **Ý tưởng game:** Chọn trường mục tiêu → tích lũy EXP qua các ải → đạt ngưỡng EXP của trường để mở khóa trường mục tiêu.
- **Nội dung chính:** Câu hỏi trắc nghiệm tiếng Anh trong các ải thường và ngân hàng câu hỏi Boss; dữ liệu ải/trường/câu hỏi được lưu ở backend.
- **Ôn luyện:** Có 4 chủ đề ngữ pháp (các thì, câu bị động, mệnh đề quan hệ, câu điều kiện), tổng cộng 24 câu. Backend chấm câu trả lời, trả giải thích và lưu kết quả gần nhất của mỗi câu cho từng người chơi; không cộng EXP, không tác động tiến độ ải.
- **AI Mentor:** Hint 1, Hint 2 và giải thích được biên soạn sẵn; không gọi mô hình AI khi chạy.
- **Phạm vi triển khai:** Dự án học tập/demo chạy với backend local; các ứng dụng kết nối cùng backend để dùng chung dữ liệu.
- **Ngoài phạm vi:** Bảng xếp hạng, đăng nhập Google, nhóm người dùng sinh viên, AI sinh câu hỏi/hint theo thời gian thực, quên/đổi mật khẩu và lưu phiên đăng nhập qua lần khởi động ứng dụng.

**Quy tắc game**

| Mục | Giá trị |
|---|---|
| Ải thường | 3 ải, mỗi ải 10 câu |
| Qua ải thường | Đúng ≥ 8/10 thì được tính là qua ải và mở ải kế. Không đạt vẫn nhận EXP theo công thức. |
| EXP mỗi câu đúng | Ải 1 = 200, ải 2 = 300, ải 3 = 400 |
| Câu sai | 0 EXP, không bị trừ EXP |
| Hint | Hint 1 miễn phí, tự hiện khi trả lời sai ở ải thường. Hint 2 xuất hiện khi chọn “Xem tiếp”, trừ 60 EXP vào tổng EXP của lượt; tổng EXP lượt không thấp hơn 0. |
| Trả lời | Mỗi câu chỉ trả lời một lần; hint hỗ trợ học sau khi trả lời, không đổi kết quả đúng/sai. |
| Boss | Mỗi lượt chọn ngẫu nhiên 15 câu từ ngân hàng Boss (khoảng 60 câu); giới hạn 30 phút cho toàn lượt; thắng khi đúng ≥ 13/15. Thắng lần đầu nhận 2000 EXP; các lần thắng sau không nhận thêm. Không có EXP từng câu hoặc hint. Đáp án công bố ở kết quả, không tiết lộ đúng/sai trong lúc chơi. |
| Mở ải | Tuần tự: qua ải N mới mở ải N+1. Boss mở sau khi hoàn thành 3 ải thường. |
| Chơi lại | Ải thường vẫn có thể nhận EXP theo kết quả; Boss chỉ có thưởng một lần. |
| Lượt thường dở | Có thể tiếp tục trong vòng 15 phút kể từ tương tác gần nhất; hết hạn thì không được tiếp tục. |
| Lượt Boss dở | Không giữ tiến độ; bắt đầu lại sẽ tạo lượt Boss mới. |
| Kết thúc lượt | Ải thường cần trả lời đủ 10 câu; Boss có thể kết thúc bất cứ lúc nào, câu bỏ trống tính là sai. |

**Trường mục tiêu và EXP yêu cầu**

| Trường | EXP |
|---|---:|
| ĐH Quốc gia Hà Nội (VNU) | 10000 |
| ĐH Quốc gia TP.HCM (VNU-HCM) | 10000 |
| ĐH Bách khoa Hà Nội (HUST) | 9000 |
| ĐH Bách khoa, ĐHQG TP.HCM (HCMUT) | 8000 |
| ĐH Y Hà Nội (HMU) | 7500 |
| ĐH Y Dược TP.HCM (UMP) | 7000 |
| ĐH Ngoại thương (FTU) | 5000 |
| ĐH Kinh tế TP.HCM | 4500 |

# 2. Tính năng

**Module A: Đăng ký/Đăng nhập bằng tài khoản và mật khẩu**
- [Must] Đăng ký bằng username và mật khẩu; username được chuẩn hóa chữ thường, dài 3–32 ký tự, chỉ gồm chữ không dấu, số và `_`.
- [Must] Mật khẩu dài 10–128 ký tự, có ít nhất một chữ cái và một chữ số.
- [Must] Đăng ký tạo tài khoản và hồ sơ Players liên kết, sau đó cấp phiên đăng nhập.
- [Must] Đăng nhập bằng cùng username/mật khẩu; xác minh mật khẩu bằng ASP.NET Core PasswordHasher, không lưu mật khẩu rõ.
- [Must] Token phiên bearer ngẫu nhiên có hạn 7 ngày; backend chỉ lưu SHA-256 hash của token. App giữ token trong bộ nhớ và gắn vào các yêu cầu sau đăng nhập.
- [Must] Role mặc định là `User`; role `Admin` được dùng để kiểm soát endpoint quản trị.
- [Must] Có thể đăng xuất để thu hồi phiên hiện tại. Tài khoản bị tạm khóa 5 phút sau 5 lần đăng nhập sai liên tiếp; endpoint đăng nhập/đăng ký có giới hạn tốc độ.

**Module B: Hồ sơ người chơi và trường mục tiêu**
- [Must] Mỗi tài khoản gắn với một hồ sơ Player; hồ sơ hiển thị tên tài khoản, Avatar, tổng EXP và trường mục tiêu.
- [Must] Chọn trường mục tiêu từ danh sách 8 trường; mục tiêu không thể đổi sau khi đã chọn.
- [Must] Hiển thị tiến độ EXP tới ngưỡng trường và trạng thái mở khóa khi tổng EXP đạt yêu cầu.
- [Must] Người chơi có thể cập nhật Avatar bằng `AvatarId`.

**Module C: Ải thường**
- [Must] Có 3 ải, mỗi ải 10 câu trắc nghiệm; độ khó tăng dần theo ải.
- [Must] Qua ải khi đúng ≥ 8/10; chỉ khi qua mới mở ải kế.
- [Must] Không đạt vẫn nhận EXP tính theo số câu đúng, trừ khoản Hint 2 đã dùng; EXP của lượt chặn ở 0.
- [Must] Cần trả lời đủ 10 câu mới kết thúc lượt; câu chỉ được trả lời một lần.
- [Must] EXP mỗi câu đúng lần lượt là 200, 300, 400 theo ải.
- [Must] Có thể tiếp tục lượt dở còn hạn; người chơi có thể chọn bắt đầu lại, lượt cũ bị hết hạn và không trao EXP.

**Module D: Hint và tổng kết**
- [Must] Hint 1 và Hint 2 được lưu sẵn cùng câu hỏi.
- [Must] Hint 1 tự hiển thị miễn phí sau khi trả lời sai ở ải thường.
- [Must] Hint 2 chỉ được cấp khi người chơi yêu cầu; trừ 60 EXP trong tính toán tổng EXP của lượt.
- [Must] Kết quả lượt thường gồm số đúng/sai, trạng thái qua/thua, EXP nhận, tổng EXP mới và phần xem lại câu sai kèm hint/giải thích.
- [Must] Câu trả lời, kết quả và EXP được xử lý ở server; client không nhận đáp án đúng trước thời điểm được phép.

**Module E: Boss**
- [Must] Chỉ mở Boss sau khi hoàn thành cả 3 ải thường.
- [Must] Server chọn ngẫu nhiên 15 câu từ ngân hàng câu hỏi Boss ở mỗi lượt.
- [Must] Thời gian tối đa 30 phút do server quản lý; không có Mentor/hint.
- [Must] Trong lượt Boss, API chỉ xác nhận đã ghi nhận câu trả lời, không trả đúng/sai. Màn kết quả mới công bố đáp án.
- [Must] Có thể kết thúc bất kỳ lúc nào; câu chưa trả lời được tính là sai. Thắng khi đúng ≥ 13 câu.
- [Must] Thưởng cố định 2000 EXP cho lần thắng đầu tiên; lượt thắng sau không nhận thưởng.
- [Must] Lượt Boss đang dở không được phục hồi; lần bắt đầu tiếp theo tạo lượt mới.

**Module F: Ôn luyện**
- [Must] Có 4 chủ đề: các thì cơ bản, câu bị động, mệnh đề quan hệ và câu điều kiện; tổng cộng 24 câu.
- [Must] Có thể xem bài nhắc kiến thức và danh sách câu hỏi theo chủ đề hoặc toàn bộ ngân hàng Ôn luyện.
- [Must] Đáp án đúng và giải thích chỉ được trả về sau khi gửi câu trả lời.
- [Must] Lưu kết quả mới nhất theo người chơi và câu hỏi trên backend; không cộng EXP và không làm thay đổi tiến độ ải/Boss.

**Module G: Hồ sơ cá nhân**
- [Must] Hiển thị Avatar, tổng EXP và danh sách Huy hiệu (Badges) đã nhận.
- [Must] Huy hiệu được trao tự động khi hoàn tất điều kiện trong game. Các điều kiện hiện có gồm: qua ải 1 (“Chiến binh tập sự”), đạt 10/10 câu trong một lượt 10 câu (“Bất bại”), và thắng Boss (“Kẻ chinh phục”).
- [Must] Huy hiệu được lưu theo quan hệ người chơi–huy hiệu; mỗi huy hiệu chỉ xuất hiện một lần trong hồ sơ.
- [Must] Người chơi có thể cập nhật Avatar; giá trị mặc định là `default_avatar`.

**Module H: Lịch sử làm bài**
- [Must] Xem lại các lượt chơi đã hoàn thành, sắp xếp lượt mới nhất trước.
- [Must] Mỗi mục lịch sử hiển thị tên ải, trạng thái Pass/Fail, số câu đúng trên tổng số câu, EXP nhận và thời điểm chơi.
- [Must] Lịch sử không bao gồm lượt đang chơi hoặc lượt hết hạn; dữ liệu lấy từ các lượt ải/Boss đã hoàn tất.

**Module I: Quản lý câu hỏi – Admin**
- [Must] Phân quyền theo `Role`: chỉ tài khoản có role `Admin` được truy cập API quản trị câu hỏi; tài khoản User bị từ chối.
- [Must] Admin có thể xem danh sách/chi tiết câu hỏi, tạo mới, cập nhật và xóa câu hỏi.
- [Must] Dữ liệu câu hỏi quản lý gồm ải, nội dung, bốn lựa chọn, đáp án đúng, hai hint và giải thích.
- [Must] Không cho xóa câu hỏi đã được tham chiếu bởi lượt chơi/câu trả lời.

**Tính năng hệ thống**
- [Must] Các API yêu cầu xác thực dùng `Authorization: Bearer <token>`; server kiểm tra session còn hạn và quyền sở hữu Player/lượt chơi.
- [Should] Hiển thị thông báo rõ ràng khi mất kết nối hoặc server không phản hồi.
- [Nice] Hiệu ứng nhẹ khi qua ải, thắng Boss hoặc mở khóa trường; không làm thay đổi luật chơi.

# 3. Kiến trúc kỹ thuật

- **Frontend:** Flutter + Dart; ứng dụng Android và cấu hình chạy thử trên Flutter Web.
- **Backend:** ASP.NET Core Web API, REST/JSON, Entity Framework Core.
- **Database hiện dùng:** SQLite, file `backend_api/english-quest-accounts.db` (connection string mặc định `Data Source=english-quest-accounts.db`, chạy backend từ thư mục `backend_api`).
- **Luồng:** Flutter → HTTP/JSON → ASP.NET Core Web API → Entity Framework Core → SQLite.
- **Xác thực:** Session Bearer Token. Đăng ký/đăng nhập tạo token ngẫu nhiên 32 byte biểu diễn dạng hex; token gửi cho client, database chỉ lưu hash SHA-256. Phiên hết hạn sau 7 ngày; logout xóa phiên hiện tại.
- **Ủy quyền:** Role-based Authorization. Tài khoản có role `User` hoặc `Admin`; AdminController yêu cầu role Admin. Bộ lọc sở hữu kiểm tra các route có `playerId`, `id`, `attemptId` và yêu cầu start để người dùng không truy cập dữ liệu người chơi khác.
- **Bảo vệ đăng nhập:** PasswordHasher của ASP.NET Core với cấu hình 600.000 iterations; username duy nhất; sau 5 lần nhập sai liên tiếp tài khoản bị khóa 5 phút; giới hạn 20 yêu cầu auth/phút theo địa chỉ IP.
- **Chính sách API:** Các controller mặc định yêu cầu xác thực; đăng ký và đăng nhập cho phép truy cập ẩn danh. Backend yêu cầu HTTPS cho `/api` ngoài môi trường Development. CORS được cấu hình cho localhost Flutter Web.
- **Nguyên tắc gameplay:** Server chấm câu trả lời và tính EXP; đáp án ải thường không gửi trước khi trả lời. Với Boss, không trả đúng/sai trong lượt chơi; server giữ thời gian hết hạn, danh sách câu của lượt và kết quả.
- **Ôn luyện:** Nội dung được định nghĩa riêng trong PracticeBank, không dùng ngân hàng câu hỏi ải/Boss; kết quả gần nhất được lưu trong SQLite.
- **Tổ chức backend:** `Controllers` xử lý HTTP, `Services` chứa nghiệp vụ, `Models` định nghĩa entity, `Data/AppDbContext` cấu hình EF Core.
- **Cấu hình chạy:** Mặc định database provider là SQLite. Backend demo chạy local; URL API của app có thể được cấu hình bằng `API_BASE_URL`.

# 4. Database schema (dạng text)

Các bảng dưới đây mô tả entity và quan hệ hiện có trong EF Core/SQLite. PK/FK và giới hạn độ dài được cấu hình trong `AppDbContext`.

```text
Accounts
  Id (PK), Username (unique, tối đa 32),
  PasswordHash (hash, tối đa 512), Role (mặc định 'User', tối đa 20),
  PlayerId (FK -> Players, unique), FailedLogins, LockedUntil (nullable)

LoginSessions
  TokenHash (PK, SHA-256 của bearer token, tối đa 64 ký tự hex),
  AccountId (FK -> Accounts), ExpiresAt

Universities
  Id (PK), Name, ShortName, ExpRequired

Players
  Id (PK), Name (unique), AvatarId (mặc định 'default_avatar'),
  TargetUniversityId (FK -> Universities, nullable), TotalExp, CreatedAt

Badges
  Id (PK), Name, Description, IconUrl

PlayerBadges
  PlayerId (FK -> Players), BadgeId (FK -> Badges)
  PK ghép (PlayerId, BadgeId)

Stages
  Id (PK), OrderNo, Name, Type ('Normal' | 'Boss'),
  QuestionCount, PassCorrect, TimeLimitSeconds,
  ExpPerCorrect, BonusExp

Questions
  Id (PK), StageId (FK -> Stages), OrderNo, Content,
  OptionA, OptionB, OptionC, OptionD, CorrectOption ('A'..'D'),
  Hint1 (nullable), Hint2 (nullable), Explanation (nullable)

PlayerStageProgress
  PlayerId (FK -> Players), StageId (FK -> Stages) -- PK ghép
  IsCompleted, FirstClearedAt (nullable), BestCorrectCount, BossRewardClaimed

StageAttempts
  Id (PK), PlayerId (FK -> Players), StageId (FK -> Stages),
  StartedAt, ExpiresAt, FinishedAt (nullable),
  Status ('InProgress' | 'Passed' | 'Failed' | 'Expired'),
  CorrectCount, ExpEarned

AttemptQuestions
  AttemptId (FK -> StageAttempts), QuestionId (FK -> Questions), OrderNo
  PK ghép (AttemptId, QuestionId)

AttemptAnswers
  Id (PK), AttemptId (FK -> StageAttempts), QuestionId (FK -> Questions),
  SelectedOption (nullable), IsCorrect, ShownHint1, UsedNextHint, ExpDelta

PracticeRecords
  PlayerId (FK -> Players), QuestionId (string), IsCorrect
  PK ghép (PlayerId, QuestionId)
```

**Ghi chú dữ liệu và nghiệp vụ**
- `Accounts.PlayerId` liên kết một-một với hồ sơ `Players`; `Players.Name` được tạo theo username tài khoản.
- `LoginSessions` không lưu bearer token dạng rõ. Phiên hết hạn có thể được dọn khi tạo phiên đăng nhập mới.
- `PlayerBadges` là bảng liên kết nhiều-nhiều; nghiệp vụ finish lượt tự trao các huy hiệu đã cấu hình khi người chơi đạt điều kiện.
- `ExpRequired` là ngưỡng của từng trường trong `Universities`; `AvatarId` là mã avatar chứ không phải dữ liệu ảnh nhị phân.
- Các câu Boss dùng `StageId` của Boss làm ngân hàng. Khi bắt đầu, server ghi 15 câu ngẫu nhiên vào `AttemptQuestions`; ải thường sử dụng các câu được cấu hình cho ải.
- `ExpDelta` ghi biến động câu trả lời/hint. EXP lượt thường được tính ở server và không thể thấp hơn 0; lượt thường Failed vẫn có thể nhận EXP. Boss chỉ cấp `BonusExp` khi thắng lần đầu.
- Lượt thường hết hạn sau 15 phút không tương tác; `ExpiresAt` được cập nhật theo tương tác. Hạn Boss cố định 30 phút tính từ lúc bắt đầu.
- `PracticeRecords` lưu kết quả mới nhất cho từng cặp người chơi/câu Ôn luyện; ngân hàng câu Ôn luyện nằm trong mã nguồn `PracticeBank`, không phải bảng `Questions`.

# 5. API endpoints

Tất cả route dưới đây có tiền tố `/api` trừ `/health`. API yêu cầu bearer token, ngoại trừ đăng ký/đăng nhập và health check. Các route truy vấn/thay đổi dữ liệu Player chỉ cho phép chủ sở hữu Player tương ứng; API quản trị yêu cầu role Admin.

**Auth**
- `POST /api/auth/register`: body `{ username, password }`; kiểm tra định dạng, tạo Account và Player, trả token, thời hạn, role và thông tin player.
- `POST /api/auth/login`: body `{ username, password }`; trả token, thời hạn, role và thông tin player. Sai thông tin hoặc đang bị khóa trả lỗi xác thực.
- `POST /api/auth/logout`: thu hồi session bearer đang dùng; trả `204 No Content`.

**Người chơi, hồ sơ và lịch sử**
- `GET /api/players/{id}`: thông tin Player, Avatar, EXP, trường mục tiêu và trạng thái mở khóa.
- `PUT /api/players/{id}/target`: body `{ universityId }`; chọn trường mục tiêu một lần.
- `GET /api/players/{id}/profile`: hồ sơ gồm tên, Avatar, tổng EXP và danh sách huy hiệu.
- `PUT /api/players/{id}/avatar`: body `{ avatarId }`; cập nhật Avatar.
- `GET /api/players/{id}/history`: các lượt ải/Boss hoàn tất, mới nhất trước; gồm trạng thái, số câu đúng/tổng câu, EXP và thời điểm chơi.
- `GET /api/universities`: danh sách trường và ngưỡng EXP.
- `POST /api/players/login` là route cũ không còn dùng để đăng nhập; backend hiện trả `410 Gone`. Dùng `/api/auth/login`.

**Ải và lượt chơi**
- `GET /api/stages?playerId={id}`: danh sách ải và trạng thái khóa/mở/đã qua; gồm trạng thái lượt thường đang dở còn hạn.
- `POST /api/stages/{stageId}/start`: body `{ playerId, restart }`. Ải thường trả lượt đang dở nếu còn hạn và `restart` là false; `restart: true` làm lượt cũ hết hạn và tạo lượt mới. Boss luôn bắt đầu lượt mới và chọn ngẫu nhiên 15 câu. Câu trả về không bao gồm đáp án đúng hay hint.
- `GET /api/attempts/{attemptId}`: lấy lại trạng thái lượt thường còn hạn.
- `POST /api/attempts/{attemptId}/answer`: body `{ questionId, selectedOption }`. Ải thường trả đúng/sai và Hint 1 nếu sai; Boss chỉ xác nhận đã ghi nhận câu trả lời.
- `POST /api/attempts/{attemptId}/hint/next`: body `{ questionId }`; trả Hint 2 và áp dụng mức trừ 60 EXP. Không áp dụng cho Boss.
- `POST /api/attempts/{attemptId}/finish`: hoàn tất lượt, trả kết quả, trạng thái và EXP; lượt thường yêu cầu đủ câu trả lời, Boss tính câu bỏ trống là sai.
- `GET /api/attempts/{attemptId}/summary`: xem tổng kết sau khi hoàn tất; ải thường trả nội dung câu sai/hint/giải thích, Boss trả đáp án và lựa chọn đã gửi.

**Ôn luyện**
- `GET /api/practice/topics`: danh sách chủ đề, bài nhắc kiến thức và số câu mỗi chủ đề.
- `GET /api/practice/questions?topicId={id}`: câu hỏi theo chủ đề; bỏ `topicId` để lấy toàn bộ câu. Không trả đáp án/giải thích trước khi nộp.
- `POST /api/practice/answer`: body `{ questionId, selectedIndex }`; chấm và trả kết quả/đáp án/giải thích, đồng thời cập nhật kết quả gần nhất.
- `GET /api/practice/progress`: kết quả gần nhất của các câu thuộc người chơi đang đăng nhập.

**Quản lý câu hỏi – Admin**
- `GET /api/admin/questions`: danh sách câu hỏi; chỉ Admin.
- `GET /api/admin/questions/{id}`: chi tiết câu hỏi; chỉ Admin.
- `POST /api/admin/questions`: tạo câu hỏi; body gồm `stageId`, `content`, `optionA`–`optionD`, `correctOption` (`A`–`D`), `hint1`, `hint2`, `explanation`. `orderNo` tự tăng trong ải.
- `PUT /api/admin/questions/{id}`: cập nhật câu hỏi; nếu chuyển sang ải khác, câu hỏi được xếp cuối ải mới.
- `DELETE /api/admin/questions/{id}`: xóa câu hỏi; trả conflict nếu câu đã được tham chiếu trong lượt/câu trả lời.

**Hệ thống**
- `GET /health`: health check, cho phép ẩn danh.
- Trong Development, OpenAPI được cung cấp tại `/openapi/v1.json`.

# 6. UI/UX Direction

**Phong cách:** RPG nhẹ, tươi, dễ đọc; không rối mắt vì học sinh dùng để học.

**Palette (hiện tại)**
- Nền chính: `#1B1F3B` (xanh navy đậm)
- Nhấn chính: `#6C4AB6` (tím)
- EXP / phần thưởng: `#F5B83D` (vàng)
- Đúng / qua ải: `#3FB27F` (xanh lá)
- Sai / hết giờ / Boss: `#E5484D` (đỏ)
- Chữ trên nền tối: `#F4F1FF`; thẻ/khung: `#2A2F57`

**Typography (đề xuất)**
- Font: **Be Vietnam Pro** (hỗ trợ tiếng Việt tốt), dùng gói `google_fonts`.
- Tiêu đề: đậm 700; câu hỏi: 600, cỡ lớn; nội dung/hint: 400.

**Danh sách màn hình**
1. Đăng nhập / Đăng ký tài khoản
2. Chọn trường mục tiêu
3. Trang chủ: EXP hiện tại, thanh tiến độ tới EXP mục tiêu, trạng thái mở khóa trường
4. Bản đồ ải: 3 ải thường + Boss (khóa/mở/đã qua)
5. Màn chơi câu hỏi (ải thường): câu hỏi, 4 đáp án
6. Khung AI Mentor: tự hiện Hint 1 khi trả lời sai, nút "Xem tiếp" để ra Hint 2 (-60 EXP)
7. Tổng kết cuối ải: đúng/sai, EXP nhận (kể cả khi chưa đạt), xem lại câu sai + hint
8. Giới thiệu Boss (luật chơi, 30 phút)
9. Màn chơi Boss: đồng hồ đếm ngược, không có Mentor, không hiện đúng/sai từng câu
10. Kết quả Boss (thắng/thua) kèm đáp án đúng của từng câu
11. Hộp thoại: tiếp tục ải dở / chơi lại (hiện khi `hasInProgressAttempt` = true; chọn "chơi lại" thì gọi `start` với `restart` = true)
12. Hộp thoại: mất mạng (hiện giữa màn hình)
13. Hộp thoại: mở khóa trường mục tiêu

**Phân việc UI:** bạn làm đủ luồng chạy được với giao diện tối thiểu; bạn kia tối ưu giao diện trên GitHub. Hai bạn nên vẽ phác 13 màn hình này (giấy hoặc Figma) ở tuần 1.

# 7. Roadmap (khoảng 5 tuần)

**Milestone 1 (tuần 1): Nền móng**
- Chốt luật game, vẽ phác màn hình cùng bạn kia.
- Tạo database, seed 8 trường + 3 ải + Boss + một ít câu hỏi mẫu.
- Dựng API khung, nhập tên, chạy thông Flutter ↔ API (xử lý CORS).
- Chọn trường mục tiêu (màn chọn trường + lưu mục tiêu): làm sớm.

**Milestone 2 (tuần 2): Lõi ải thường**
- Start ải, trả lời, chấm đúng/sai, tính EXP theo ải (200 / 300 / 400), hoàn thành ải, mở ải kế.
- Hint 1 free tự hiện khi sai, nút "Xem tiếp" (trừ 60 EXP), EXP ải chặn ở 0.
- Build thử bản Android thật (không chờ tới cuối).

**Milestone 3 (tuần 3): Boss và tổng kết, bàn giao UI**
- Màn tổng kết cuối ải.
- Boss: đồng hồ, thắng/thua, màn kết quả công bố đáp án, thưởng 2000 EXP một lần (chơi lại không tính điểm).
- Ải thường: thoát giữa ải giữ tiến độ 15 phút; thông báo mất mạng.
- **Đẩy code lên GitHub, bạn kia bắt đầu tối ưu UI.**

**Milestone 4 (tuần 4): Trường mục tiêu và nội dung**
- Thanh tiến độ, mở khóa trường.
- Hoàn tất nhập câu hỏi: 30 câu ải thường (kèm Hint 1, Hint 2) + khoảng 60 câu cho ngân hàng Boss (không hint); tổng khoảng 90 câu, nhờ người giỏi tiếng Anh rà đáp án.

**Milestone 5 (tuần 5): Hoàn thiện**
- Test toàn bộ luồng, sửa lỗi, ghép UI, chuẩn bị demo và báo cáo.
- Chừa buffer; không thêm tính năng mới.

**Quy tắc:** không thêm tính năng ngoài spec; thời gian dư dùng để test, sửa lỗi và chỉnh UI.

# 8. Rủi ro và câu hỏi mở

**Rủi ro**
- **Số lượng nội dung:** khoảng 90 câu: 30 câu ải thường (đề, đáp án, 2 hint) + khoảng 60 câu Boss (đề, đáp án; Boss không có hint). Đây là phần tốn công nhất của đồ án, nên bắt đầu soạn sớm và nhập theo đợt, không dồn vào tuần 4; AI soạn nháp có thể sai đáp án, cần người rà.
- **EXP và mục tiêu:** tối đa một lượt hoàn hảo (10 câu đúng mỗi ải, không xem Hint 2) là 10 × 200 + 10 × 300 + 10 × 400 = 9000, cộng thưởng Boss 2000 = 11000 EXP.
- **Web vs Android:** code chạy trên Flutter web chưa chắc chạy trên Android; build sớm ở tuần 2.
- **Phối hợp nhóm:** UI bị dồn cuối nếu bàn giao trễ.
- **Vibe code:** bạn không đọc được code, nên kiểm tra bằng chạy thử sau mỗi tính năng và commit nhỏ, thường xuyên.
- **Bản quyền đề thi:** chỉ dùng cho đồ án học thuật; nếu phát triển thật thì phải kiểm tra lại.

**Đã chốt:** 3 ải thường (EXP mỗi câu đúng: 200 / 300 / 400); Hint 1 free tự hiện khi sai, "Xem tiếp" ra Hint 2 và trừ 60 EXP vào tổng EXP của ải; EXP ải chặn ở 0; Boss mở khi hoàn thành 3 ải thường (không xét EXP), 15 câu random mỗi lần chơi từ ngân hàng khoảng 60 câu, thắng lần đầu thưởng 2000 EXP, chơi lại không tính điểm (chỉ ôn tập), thoát giữa Boss thì chơi lại từ đầu, thua Boss không bị khóa, Boss không hiện đúng/sai từng câu (đáp án công bố ở màn kết quả), finish Boss gọi lúc nào cũng được; ải thường không đạt (< 8 đúng) vẫn nhận EXP theo công thức, finish ải thường yêu cầu đủ 10 câu; `GET /api/stages` có `hasInProgressAttempt`, `POST start` có `restart`; mở ải tuần tự; khi tổng EXP đạt mức của trường đã chọn thì chỉ hiện trạng thái "đã mở khóa" kèm hộp thoại chúc mừng; mục tiêu trường cố định; Ôn luyện có 4 chủ đề, 24 câu, không cộng EXP; backend chạy localhost.

**Câu hỏi mở**
- Hiện chưa còn câu hỏi mở. Nếu phát sinh khi code (ví dụ cách tính giờ Boss khi mất mạng), ghi thêm vào đây.
