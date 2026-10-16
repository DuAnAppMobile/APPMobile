import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/services/auth_client.dart';
import 'package:english_rpg_app/services/player_service.dart';

void main() {
  tearDown(AuthSession.clear);
  test('login parses account and stores only in-memory session', () async {
    final service = PlayerService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(jsonDecode(request.body), {
          'username': 'minh',
          'password': 'TestOnly12345',
        });
        return http.Response(
          jsonEncode({
            'token': 'a' * 64,
            'player': {'id': 42, 'name': 'minh', 'totalExp': 800},
          }),
          200,
        );
      }),
    );
    final player = await service.authenticate('minh', 'TestOnly12345');
    expect(player.totalExp, 800);
    expect(AuthSession.playerId, 42);
    expect(AuthSession.token, 'a' * 64);
    service.dispose();
  });
  test(
    'authenticated clients attach token and logout revokes before clearing',
    () async {
      AuthSession.token = 'b' * 64;
      AuthSession.playerId = 1;
      final service = PlayerService(
        client: AuthClient(
          inner: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer ${'b' * 64}');
            expect(request.url.path, '/api/auth/logout');
            return http.Response('', 204);
          }),
        ),
      );
      await service.logout();
      expect(AuthSession.token, isNull);
      expect(AuthSession.playerId, isNull);
      service.dispose();
    },
  );
  test('invalid auth response never sets a token', () async {
    final service = PlayerService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      service.authenticate('minh', 'TestOnly12345'),
      throwsFormatException,
    );
    expect(AuthSession.token, isNull);
    service.dispose();
  });
}
