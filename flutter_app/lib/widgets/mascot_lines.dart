import 'dart:math';

/// Shuffle bags avoid repeats until every line has been heard. Rebuilds never draw.
class MascotLines {
  MascotLines({Random? random}) : _random = random ?? Random();
  static final shared = MascotLines();
  final Random _random;
  final List<String> _wrongBag = [];
  final List<String> _rightBag = [];
  String? _lastWrong;
  String? _lastRight;

  static const wrong = [
    'Alime đã xem. Alime đang giả vờ chưa thấy.',
    'Đáp án đi một đường, mình đi một nẻo. Đọc gợi ý rồi quay xe!',
    'Não vừa bật chế độ máy bay à? Hạ cánh ở phần gợi ý nha.',
    'Câu này chưa trúng. Nhưng ít nhất mình đã loại được một đáp án!',
    'Kiến thức đang buffering… Gợi ý là nút tải lại đó.',
    'Ếch ôm sách cả ngày mà câu này cũng làm ếch trầm tư.',
    'Plot twist: đáp án đúng không phải nhân vật mình chọn.',
    'Một pha thử lòng đáp án. Nó chưa rung động, mình học tiếp!',
    'Sai một câu, thêm một mẩu kiến thức. Deal này vẫn lời.',
    'Alime xin phép sầu 3 giây. Rồi cùng xem gợi ý!',
    'Đáp án này hơi lạc hệ anime rồi. Kéo về đúng vũ trụ nào.',
    'Không sao đâu! Cú này là lấy đà cho màn comeback.',
    'Bấm rất tự tin. Tiếc là ngữ pháp chưa đồng ý. Xem lại chút nha!',
    'Câu này gài nhẹ. Mình gỡ bằng gợi ý, không gỡ bằng niềm tin.',
    'Alime vẫn tin bạn. Chỉ tạm thời không tin đáp án vừa rồi.',
    'Một chút sóng gió cho hành trình đỡ nhạt. Đọc lại là lên trình!',
    'Đáp án vừa né mình như né deadline. Mình bắt lại ở câu sau!',
    'Ếch chưa khóc. Ếch đang tưới nước cho cây kiến thức.',
    'Chưa chuẩn thôi, chưa phải hết cứu. Gợi ý ở ngay đây nè.',
    'Đừng lo, đây là tập luyện. Nhân vật chính còn được phát triển!',
  ];
  static const right = [
    'Chúc mừng, {name}! Bạn làm đúng rồi! Alime xin bái phục.',
    'Kiến thức +1, độ ngầu +100. Ếch ghi nhận!',
    'Đúng rồi! Pha này không cần sức mạnh tình bạn.',
    'Bạn thật tuyệt vời! Ếch chưa kịp load mà bạn đã đúng.',
    'Chuẩn bài! Cuốn sách trên tay ếch bỗng nhẹ hẳn.',
    'Ngữ pháp đã đồng ý. Alime cũng không còn gì để cãi.',
    'Một đáp án đúng, một lần deadline bớt đáng sợ.',
    'Đỉnh! Nhân vật chính của buổi học hôm nay đây rồi.',
    'Alime mặt vẫn sầu nhưng trong lòng đang mở hội.',
    'Câu này bạn gánh. Ếch xin làm linh vật cổ vũ.',
    'Đúng rồi, {name}! Trình này phải cho ếch xin chữ ký.',
    'Đáp án chuẩn không cần chỉnh. Alime đứng hình mất 2 giây.',
  ];

  String next(bool correct, String name) {
    final bag = correct ? _rightBag : _wrongBag;
    final last = correct ? _lastRight : _lastWrong;
    if (bag.isEmpty) {
      bag.addAll(correct ? right : wrong);
      bag.shuffle(_random);
      if (bag.last == last) {
        final first = bag.removeAt(0);
        bag.add(first);
      }
    }
    final line = bag.removeLast();
    if (correct) {
      _lastRight = line;
    } else {
      _lastWrong = line;
    }
    return line.replaceAll('{name}', name.trim().isEmpty ? 'bạn' : name.trim());
  }
}
