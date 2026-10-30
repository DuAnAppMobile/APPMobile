import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/screens/admin_screen.dart';
import 'package:english_rpg_app/screens/login_screen.dart';
import 'package:english_rpg_app/screens/home_screen.dart';
import 'package:english_rpg_app/screens/university_selection_screen.dart';
import 'package:english_rpg_app/services/account_service.dart';
import 'package:english_rpg_app/services/auth_client.dart';
import 'package:english_rpg_app/services/player_service.dart';

void main() {
  tearDown(AuthSession.clear);
  testWidgets(
    'used question opens impact confirmation and retires without deleting history',
    (tester) async {
      AuthSession.role = 'Admin';
      String? mode;
      final api = AccountApi(
        client: MockClient((request) async {
          expect(request.method, isNot('DELETE'));
          if (request.url.path.endsWith('/impact'))
            return http.Response(
              jsonEncode({
                'attempts': 3,
                'completed': 2,
                'activeQuestions': 10,
                'requiredQuestions': 10,
              }),
              200,
            );
          if (request.url.path.endsWith('/resolve')) {
            mode = jsonDecode(request.body)['mode'];
            return http.Response('{"attempts":0,"exp":0}', 200);
          }
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'stageId': 1,
                'content': 'Used question',
                'correctOption': 'A',
              },
            ]),
            200,
          );
        }),
      );
      await tester.pumpWidget(MaterialApp(home: AdminScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Câu hỏi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa / Xử lý câu lỗi'));
      await tester.pumpAndSettle();
      expect(find.text('Xử lý câu hỏi đã sử dụng'), findsOneWidget);
      expect(find.textContaining('3 lượt liên quan'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Older curriculum',
      );
      await tester.ensureVisible(find.text('Xác nhận xử lý'));
      await tester.tap(find.text('Xác nhận xử lý'));
      await tester.pumpAndSettle();
      expect(mode, 'retire');
    },
  );
  testWidgets('admin login bypasses player home and university selection', (
    tester,
  ) async {
    final service = PlayerService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'token': 'a' * 64,
            'role': 'Admin',
            'player': {'id': 1, 'name': 'admin', 'totalExp': 0},
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(playerService: service)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'Admin123456');
    final button = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(UniversitySelectionScreen), findsNothing);
  });
  testWidgets('dashboard totals, stage navigation and search use loaded bank', (
    tester,
  ) async {
    AuthSession.role = 'Admin';
    final api = AccountApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'stageId': 1,
              'content': 'Present tense',
              'correctOption': 'A',
            },
            {
              'id': 2,
              'stageId': 4,
              'content': 'Boss challenge',
              'correctOption': 'B',
            },
          ]),
          200,
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: AdminScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Trung tâm quản lý'), findsOneWidget);
    expect(find.text('Tổng câu hỏi'), findsOneWidget);
    await tester.tap(find.text('Câu hỏi'));
    await tester.pumpAndSettle();
    expect(find.text('Present tense'), findsOneWidget);
    expect(find.text('Boss challenge'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Boss'));
    await tester.pumpAndSettle();
    expect(find.text('Present tense'), findsNothing);
    expect(find.text('Boss challenge'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'absent');
    await tester.pumpAndSettle();
    expect(find.text('Không có câu hỏi phù hợp.'), findsOneWidget);
  });
  testWidgets('ordinary users cannot open admin workspace', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    expect(find.text('Chỉ quản trị viên được truy cập.'), findsOneWidget);
    expect(find.text('Trung tâm quản lý'), findsNothing);
  });
}
