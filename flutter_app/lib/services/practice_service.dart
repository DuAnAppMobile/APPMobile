import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/practice.dart';
import 'player_service.dart';
import 'auth_client.dart';

class PracticeException implements Exception {
  const PracticeException(this.message);
  final String message;
}

class PracticeService {
  PracticeService({http.Client? client}) : _client = client ?? AuthClient();
  final http.Client _client;
  void dispose() => _client.close();

  Future<Map<String, bool>> progress() async {
    final data = await _request('progress');
    if (data is! Map<String, dynamic> || data.values.any((v) => v is! bool)) {
      throw const FormatException('Tiến độ máy chủ không hợp lệ.');
    }
    return data.cast<String, bool>();
  }

  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final http.Response response;
    try {
      final url = Uri.parse('$apiBaseUrl/practice/$path');
      response =
          await (body == null
                  ? _client.get(url)
                  : _client.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body),
                    ))
              .timeout(apiTimeout);
    } on Exception {
      throw const PracticeException(
        'Không kết nối được máy chủ. Kiểm tra mạng và thử lại nhé.',
      );
    }
    if (response.statusCode == 401) {
      throw const PracticeException(
        'Phiên đăng nhập hết hạn. Hãy về trang chủ, đăng xuất và đăng nhập lại.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PracticeException(
        'Không tải được ôn luyện (${response.statusCode}). Hãy thử lại.',
      );
    }
    return jsonDecode(response.body);
  }

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final data = await _request(path);
    if (data is! List || data.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('Dữ liệu ôn luyện không hợp lệ.');
    }
    return data.map((item) => parse(item as Map<String, dynamic>)).toList();
  }

  Future<List<PracticeTopic>> topics() =>
      _list('topics', PracticeTopic.fromJson);
  Future<List<PracticeQuestion>> questions({String? topicId}) => _list(
    'questions${topicId == null ? '' : '?topicId=${Uri.encodeQueryComponent(topicId)}'}',
    PracticeQuestion.fromJson,
  );
  Future<PracticeResult> answer(String id, int selectedIndex) async {
    final data = await _request(
      'answer',
      body: {'questionId': id, 'selectedIndex': selectedIndex},
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Kết quả không hợp lệ.');
    }
    return PracticeResult.fromJson(data);
  }
}
