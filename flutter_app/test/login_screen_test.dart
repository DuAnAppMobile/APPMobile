import 'dart:convert';

import 'package:english_rpg_app/screens/login_screen.dart';
import 'package:english_rpg_app/services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'registration validates password confirmation without sending request',
    (tester) async {
      var requests = 0;
      final service = PlayerService(
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 500);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(playerService: service)),
      );
      await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'minh_alime');
      await tester.enterText(find.byType(TextField).at(1), 'Password12345');
      await tester.enterText(find.byType(TextField).at(2), 'Different12345');
      await tester.ensureVisible(find.text('Đăng ký và bắt đầu'));
      await tester.tap(find.text('Đăng ký và bắt đầu'));
      await tester.pumpAndSettle();
      expect(find.text('Hai mật khẩu chưa khớp nhau.'), findsOneWidget);
      expect(requests, 0);
    },
  );
  testWidgets('opens HomeScreen for a player with a saved target', (
    tester,
  ) async {
    final service = PlayerService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'token': 'a' * 64,
              'player': {
                'id': 12,
                'name': 'Saved target',
                'totalExp': 1200,
                'targetUniversityId': 3,
                'targetUniversity': {
                  'id': 3,
                  'name': 'ĐH Bách khoa Hà Nội',
                  'shortName': 'HUST',
                  'expRequired': 9000,
                },
                'isTargetUnlocked': false,
              },
            }),
          ),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(playerService: service)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'saved_target');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    final startButton = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Hành trình của bạn'), findsOneWidget);
    expect(find.text('Saved target'), findsOneWidget);
  });

  testWidgets('opens university selection for a player without a target', (
    tester,
  ) async {
    final service = PlayerService(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'token': 'b' * 64,
                'player': {
                  'id': 13,
                  'name': 'New player',
                  'totalExp': 0,
                  'targetUniversityId': null,
                  'targetUniversity': null,
                  'isTargetUnlocked': false,
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path == '/api/universities') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'id': 3,
                  'name': 'ĐH Bách khoa Hà Nội',
                  'shortName': 'HUST',
                  'expRequired': 9000,
                },
              ]),
            ),
            200,
          );
        }
        throw StateError('Unexpected request: ${request.url}');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(playerService: service)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'new_player');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    final startButton = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Chọn đích đến'), findsOneWidget);
  });
}
