import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/player.dart';
import '../models/university.dart';
import 'auth_client.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl => _configuredApiBaseUrl.isNotEmpty
    ? _configuredApiBaseUrl
    : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:5137/api'
    : 'http://127.0.0.1:5137/api';

const apiTimeout = Duration(seconds: 15);

class PlayerServiceException implements Exception {
  const PlayerServiceException(this.message, {this.isConnectionError = false});

  final String message;
  final bool isConnectionError;
}

class PlayerService {
  PlayerService({http.Client? client}) : _client = client ?? AuthClient();

  final http.Client _client;

  void dispose() => _client.close();

  Future<Player> authenticate(
    String username,
    String password, {
    bool register = false,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$apiBaseUrl/auth/${register ? 'register' : 'login'}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(apiTimeout);
    } on Exception {
      throw _connectionException();
    }
    _ensureSuccess(response);
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        (data['token'] as String).length != 64 ||
        data['player'] is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi đăng nhập không hợp lệ.');
    }
    final player = Player.fromJson(data['player']);
    AuthSession.token = data['token'];
    AuthSession.playerId = player.id;
    return player;
  }

  Future<void> logout() async {
    final response = await _client
        .post(Uri.parse('$apiBaseUrl/auth/logout'))
        .timeout(apiTimeout);
    if (response.statusCode != 401) _ensureSuccess(response);
    AuthSession.clear();
  }

  Future<Player> getPlayer(int playerId) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$apiBaseUrl/players/$playerId'))
          .timeout(apiTimeout);
    } on Exception {
      throw _connectionException();
    }

    _ensureSuccess(response);
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'Phản hồi thông tin người chơi không hợp lệ.',
      );
    }
    return Player.fromJson(body);
  }

  Future<List<University>> getUniversities() async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$apiBaseUrl/universities'))
          .timeout(apiTimeout);
    } on Exception {
      throw _connectionException();
    }

    _ensureSuccess(response);
    final body = jsonDecode(response.body);
    if (body is! List<dynamic>) {
      throw const FormatException('Danh sách trường không hợp lệ.');
    }
    return body.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Dữ liệu trường đại học không hợp lệ.');
      }
      return University.fromJson(item);
    }).toList();
  }

  Future<Player> setTarget(Player player, University university) async {
    final http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse('$apiBaseUrl/players/${player.id}/target'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'universityId': university.id}),
          )
          .timeout(apiTimeout);
    } on Exception {
      throw _connectionException();
    }

    _ensureSuccess(response);
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi lưu trường mục tiêu không hợp lệ.');
    }
    return Player.fromJson(body);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlayerServiceException(_messageFromError(response));
    }
  }

  PlayerServiceException _connectionException() {
    return const PlayerServiceException(
      'Không thể kết nối đến máy chủ. Vui lòng kiểm tra backend đang chạy.',
      isConnectionError: true,
    );
  }

  String _messageFromError(http.Response response) {
    if (response.statusCode == 401 && response.body.isEmpty) {
      return 'Phiên đăng nhập hết hạn. Hãy đăng xuất và đăng nhập lại.';
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        return body['message'] as String;
      }
    } on FormatException {
      // Non-JSON error responses use the status code below.
    }
    return 'Yêu cầu thất bại (${response.statusCode}). Vui lòng thử lại.';
  }
}
