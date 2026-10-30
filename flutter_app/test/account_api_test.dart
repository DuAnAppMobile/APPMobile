import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/services/account_service.dart';
import 'package:english_rpg_app/services/auth_client.dart';

void main() {
  tearDown(AuthSession.clear);
  test('new account endpoints attach bearer and send avatar JSON', () async {
    AuthSession.token = 'session-token';
    final api = AccountApi(
      client: AuthClient(
        inner: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer session-token');
          expect(request.method, 'PUT');
          expect(jsonDecode(request.body), {'avatarId': 'frog_star'});
          return http.Response('{"avatarId":"frog_star"}', 200);
        }),
      ),
    );
    expect(
      (await api.call(
        'players/1/avatar',
        method: 'PUT',
        body: {'avatarId': 'frog_star'},
      ))['avatarId'],
      'frog_star',
    );
    api.dispose();
  });
  for (final entry in {
    401: 'hết hạn',
    403: 'không có quyền',
    409: 'không được xóa',
  }.entries) {
    test('handles ${entry.key} with actionable message', () async {
      final api = AccountApi(
        client: MockClient((_) async => http.Response('', entry.key)),
      );
      await expectLater(
        api.call('admin/questions/1', method: 'DELETE'),
        throwsA(predicate((e) => e.toString().contains(entry.value))),
      );
      api.dispose();
    });
  }
}
