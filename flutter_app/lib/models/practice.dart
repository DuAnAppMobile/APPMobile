class PracticeTopic {
  const PracticeTopic(this.id, this.name, this.lesson, this.questionCount);
  final String id, name, lesson;
  final int questionCount;
  factory PracticeTopic.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['lesson'] is! String ||
        json['questionCount'] is! int) {
      throw const FormatException('Chủ đề ôn luyện không hợp lệ.');
    }
    return PracticeTopic(
      json['id'],
      json['name'],
      json['lesson'],
      json['questionCount'],
    );
  }
}

class PracticeQuestion {
  const PracticeQuestion(this.id, this.topicId, this.content, this.options);
  final String id, topicId, content;
  final List<String> options;
  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    if (json['id'] is! String ||
        json['topicId'] is! String ||
        json['content'] is! String ||
        options is! List ||
        options.length != 4 ||
        options.any((o) => o is! String)) {
      throw const FormatException('Câu hỏi ôn luyện không hợp lệ.');
    }
    return PracticeQuestion(
      json['id'],
      json['topicId'],
      json['content'],
      options.cast<String>(),
    );
  }
}

class PracticeResult {
  const PracticeResult(this.isCorrect, this.correctIndex, this.explanation);
  final bool isCorrect;
  final int correctIndex;
  final String explanation;
  factory PracticeResult.fromJson(Map<String, dynamic> json) {
    final index = json['correctIndex'];
    if (json['isCorrect'] is! bool ||
        index is! int ||
        index < 0 ||
        index > 3 ||
        json['explanation'] is! String) {
      throw const FormatException('Kết quả ôn luyện không hợp lệ.');
    }
    return PracticeResult(json['isCorrect'], index, json['explanation']);
  }
}
