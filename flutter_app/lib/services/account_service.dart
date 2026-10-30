import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_client.dart';
import 'player_service.dart';

class AccountApi {
  AccountApi({http.Client? client}) : _client = client ?? AuthClient();
  final http.Client _client;
  void dispose() => _client.close();
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$apiBaseUrl/$path'));
    request.headers['Content-Type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request))
          .timeout(apiTimeout);
    } catch (_) {
      throw Exception(
        'Không kết nối được máy chủ. Hãy kiểm tra mạng và thử lại.',
      );
    }
    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập hết hạn. Hãy đăng xuất rồi đăng nhập lại.',
      );
    }
    if (response.statusCode == 403) {
      throw Exception('Tài khoản không có quyền thực hiện thao tác này.');
    }
    if (response.statusCode == 409) {
      throw Exception(
        'Không thể thực hiện: câu hỏi đã có người chơi sử dụng, không được xóa.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Yêu cầu thất bại (${response.statusCode}).';
      try {
        final data = jsonDecode(response.body);
        if (data['message'] is String) message = data['message'];
      } catch (_) {}
      throw Exception(message);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
