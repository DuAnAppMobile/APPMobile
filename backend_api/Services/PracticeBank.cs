namespace EnglishRpg.Api.Services;

// Separate authored practice content: never expose the stage/Boss answer bank.
public sealed record PracticeTopic(string Id, string Name, string Lesson);
public sealed record PracticeItem(string Id, string TopicId, string Content,
    string[] Options, int CorrectIndex, string Explanation);

public static class PracticeBank
{
    public static readonly PracticeTopic[] Topics = [
        new("tenses", "Các thì cơ bản", "Hiện tại đơn: thói quen, sự thật; he/she/it + V-s/es. Hiện tại tiếp diễn: am/is/are + V-ing. Quá khứ đơn: hành động đã kết thúc. Hiện tại hoàn thành: have/has + V3, thường đi với since/for."),
        new("passive", "Câu bị động", "Bị động: chủ ngữ nhận hành động, dùng be + V3. Thì nằm ở động từ be: is/are, was/were, has/have been. Sau động từ khuyết thiếu: modal + be + V3."),
        new("relative", "Mệnh đề quan hệ", "Who chỉ người làm chủ ngữ; which chỉ vật; whose chỉ sở hữu; where chỉ nơi chốn. Mệnh đề không xác định có dấu phẩy không dùng that. Chọn đại từ dựa vào vai trò của từ bị thiếu."),
        new("conditional", "Câu điều kiện", "Loại 0: if + hiện tại đơn, hiện tại đơn (sự thật). Loại 1: if + hiện tại đơn, will + V (có thể xảy ra). Loại 2: if + quá khứ đơn, would + V (giả định hiện tại). Loại 3: if + had + V3, would have + V3 (giả định quá khứ).")
    ];

    public static readonly PracticeItem[] Items = [
        Q("t1", "tenses", "My brother usually ___ to school by bus.", ["go", "goes", "going", "gone"], 1, "Usually diễn tả thói quen nên dùng hiện tại đơn. My brother là ngôi thứ ba số ít: go → goes."),
        Q("t2", "tenses", "Listen! Someone ___ at the door.", ["knocks", "knocked", "is knocking", "has knocked"], 2, "Listen! báo hiệu hành động đang xảy ra: someone + is + knocking."),
        Q("t3", "tenses", "We ___ this museum last Sunday.", ["visit", "visited", "have visited", "are visiting"], 1, "Last Sunday là thời điểm quá khứ đã kết thúc, dùng quá khứ đơn: visited."),
        Q("t4", "tenses", "She ___ here since 2020 and still lives here.", ["lived", "is living", "has lived", "live"], 2, "Since 2020 nối quá khứ với hiện tại, dùng hiện tại hoàn thành: she has lived."),
        Q("t5", "tenses", "At 8 p.m. yesterday, I ___ dinner.", ["am cooking", "cook", "have cooked", "was cooking"], 3, "Hành động đang diễn ra tại một thời điểm cụ thể trong quá khứ dùng was/were + V-ing."),
        Q("t6", "tenses", "By the time we arrived, the film ___.", ["had started", "starts", "has started", "is starting"], 0, "Phim bắt đầu trước khi chúng tôi đến. Hành động xảy ra trước một mốc quá khứ dùng had + V3."),
        Q("p1", "passive", "English ___ in many countries.", ["speaks", "is spoken", "is speaking", "spoke"], 1, "English nhận hành động nói, không tự nói. Bị động hiện tại đơn: is + spoken."),
        Q("p2", "passive", "This bridge ___ in 1990.", ["built", "is built", "was built", "has built"], 2, "Cây cầu được xây vào năm 1990: bị động quá khứ đơn, was + built."),
        Q("p3", "passive", "The report must ___ before Friday.", ["finish", "be finished", "finished", "finishing"], 1, "Sau must, bị động dùng be + V3: must be finished, nghĩa là phải được hoàn thành."),
        Q("p4", "passive", "A new hospital ___ next year.", ["will build", "built", "will be built", "has built"], 2, "Bệnh viện sẽ được xây: bị động tương lai đơn là will be + V3."),
        Q("p5", "passive", "The classroom ___ right now.", ["is being cleaned", "cleans", "was cleaned", "has cleaned"], 0, "Right now: đang được dọn. Bị động hiện tại tiếp diễn: is being + cleaned."),
        Q("p6", "passive", "The letters ___ already.", ["have sent", "have been sent", "are sending", "send"], 1, "Thư đã được gửi: chủ ngữ số nhiều + have been + V3. Sent là quá khứ phân từ của send."),
        Q("r1", "relative", "The woman ___ teaches us English is very kind.", ["which", "whose", "who", "where"], 2, "The woman là người và từ bị thiếu làm chủ ngữ của teaches, dùng who."),
        Q("r2", "relative", "The laptop ___ I bought yesterday is expensive.", ["who", "which", "where", "whose"], 1, "Laptop là vật; đại từ làm tân ngữ của bought: dùng which."),
        Q("r3", "relative", "The boy ___ father is a doctor sits next to me.", ["whose", "who", "which", "where"], 0, "Father thuộc về the boy, cần quan hệ sở hữu: whose father."),
        Q("r4", "relative", "This is the village ___ I grew up.", ["which", "who", "whose", "where"], 3, "Grew up cần địa điểm, nghĩa là lớn lên ở ngôi làng đó: where = in which."),
        Q("r5", "relative", "My sister, ___ lives in Hue, is a nurse.", ["that", "who", "where", "whose"], 1, "Chỉ người trong mệnh đề không xác định có dấu phẩy: dùng who, không dùng that."),
        Q("r6", "relative", "The car, ___ was parked outside, belongs to Nam.", ["that", "who", "which", "whose"], 2, "Chỉ vật trong mệnh đề không xác định: dùng which, không dùng that."),
        Q("c1", "conditional", "If it rains tomorrow, we ___ at home.", ["stayed", "would stay", "will stay", "had stayed"], 2, "Điều kiện loại 1, khả năng tương lai: if + hiện tại đơn, will + V."),
        Q("c2", "conditional", "If I were you, I ___ more carefully.", ["will study", "would study", "study", "had studied"], 1, "If I were you là giả định hiện tại, loại 2: would + V."),
        Q("c3", "conditional", "If she had left earlier, she ___ the train.", ["will catch", "catches", "would catch", "would have caught"], 3, "Giả định trái quá khứ, loại 3: had left đi với would have + V3 (caught)."),
        Q("c4", "conditional", "If you heat ice, it ___.", ["melts", "would melt", "had melted", "melted"], 0, "Sự thật khoa học dùng loại 0: hiện tại đơn ở cả hai vế. It là số ít nên melts."),
        Q("c5", "conditional", "Unless you hurry, you ___ the bus.", ["missed", "would miss", "will miss", "had missed"], 2, "Unless = if not. Điều kiện có thể xảy ra trong tương lai: nếu không nhanh thì sẽ lỡ xe, dùng will miss."),
        Q("c6", "conditional", "If he ___ more free time now, he would learn Japanese.", ["has", "had", "had had", "will have"], 1, "Now và would learn cho thấy loại 2: giả định hiện tại, if + quá khứ đơn (had).")
    ];

    private static PracticeItem Q(string id, string topic, string text, string[] options, int answer, string explanation)
        => new(id, topic, text, options, answer, explanation);
}
