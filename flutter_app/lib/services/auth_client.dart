import 'package:http/http.dart' as http;

// Memory-only credentials: reopening the app requires login, data stays on server.
class AuthSession {
  static String? token;
  static int? playerId;
  static String role = 'User';
  static void clear() {
    token = null;
    playerId = null;
    role = 'User';
  }
}

class AuthClient extends http.BaseClient {
  AuthClient({http.Client? inner}) : _inner = inner ?? http.Client();
  final http.Client _inner;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = AuthSession.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
