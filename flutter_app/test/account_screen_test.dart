import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/screens/account_screen.dart';
import 'package:english_rpg_app/services/account_service.dart';
import 'package:english_rpg_app/services/auth_client.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(AuthSession.clear);
  testWidgets('profile renders name EXP badge and saves selected avatar', (
    tester,
  ) async {
    String avatar = 'default_avatar';
    final api = AccountApi(
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          avatar = jsonDecode(request.body)['avatarId'];
          return http.Response('{}', 200);
        }
        return http.Response(
          jsonEncode({
            'name': 'alime_test',
            'totalExp': 2400,
            'avatarId': avatar,
            'badges': [
              {'name': 'Champion', 'description': 'First victory'},
            ],
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: AccountScreen(playerId: 1, api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('alime_test'), findsOneWidget);
    expect(find.textContaining('2400 EXP'), findsOneWidget);
    expect(find.text('Champion'), findsOneWidget);
    expect(find.text('Quản lý câu hỏi'), findsNothing);
    await tester.tap(find.text('Đổi avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('frog_star'));
    await tester.pumpAndSettle();
    expect(avatar, 'frog_star');
    expect(find.text('🌟'), findsOneWidget);
  });
  testWidgets('history displays completed attempts and result', (tester) async {
    final api = AccountApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'stageName': 'Stage one',
              'status': 'Passed',
              'correctCount': 9,
              'totalQuestions': 10,
              'expEarned': 1800,
              'playedAt': '2026-10-31T10:00:00',
            },
          ]),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(playerId: 1, api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Stage one'), findsOneWidget);
    expect(find.text('+1800 EXP'), findsOneWidget);
    expect(find.textContaining('9/10'), findsOneWidget);
  });
}
