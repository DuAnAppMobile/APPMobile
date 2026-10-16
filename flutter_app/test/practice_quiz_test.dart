import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/models/player.dart';
import 'package:english_rpg_app/models/practice.dart';
import 'package:english_rpg_app/screens/practice_quiz_screen.dart';
import 'package:english_rpg_app/services/practice_progress.dart';
import 'package:english_rpg_app/services/practice_service.dart';
import 'package:english_rpg_app/theme/app_theme.dart';

void main() {
  testWidgets('double tap submits once, network failure remains retryable', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final progress = PracticeProgress(
      read: (_) async => null,
      write: (_, _) async {},
    );
    await progress.load(1);
    final service = PracticeService(
      client: MockClient((_) {
        calls++;
        return pending.future;
      }),
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeQuizScreen(
          player: const Player(id: 1, name: 'Test'),
          title: 'Test',
          questions: const [
            PracticeQuestion('t1', 'tenses', 'Question?', [
              'one',
              'two',
              'three',
              'four',
            ]),
          ],
          service: service,
          progress: progress,
        ),
      ),
    );
    await tester.tap(find.text('A. one'));
    await tester.tap(find.text('A. one'));
    expect(calls, 1);
    pending.completeError(http.ClientException('offline'));
    await tester.pumpAndSettle();
    expect(progress.latest, isEmpty);
    expect(
      tester
          .widget<OutlinedButton>(
            find.ancestor(
              of: find.text('A. one'),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'wrong, correct, summary, retry and resolved notebook on narrow phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final saved = <String, String>{};
      final progress = PracticeProgress(
        read: (k) async => saved[k],
        write: (k, v) async {
          saved[k] = v;
        },
      );
      await progress.load(7);
      final service = PracticeService(
        client: MockClient((request) async {
          final data = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'isCorrect': data['selectedIndex'] == 1,
              'correctIndex': 1,
              'explanation': 'Chủ ngữ số ít dùng động từ thêm s.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: PracticeQuizScreen(
            player: const Player(id: 7, name: 'Minh'),
            title: 'Luyện thử',
            questions: const [
              PracticeQuestion('t1', 'tenses', 'She ___ daily.', [
                'go',
                'goes',
                'going',
                'gone',
              ]),
              PracticeQuestion('t2', 'tenses', 'He ___ daily.', [
                'walk',
                'walks',
                'walking',
                'walked',
              ]),
            ],
            service: service,
            progress: progress,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('A. go'));
      await tester.pumpAndSettle();
      expect(progress.wrongIds, {'t1'});
      Future<void> tapNext(String text) async {
        await tester.scrollUntilVisible(
          find.text(text),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tapNext('Câu tiếp theo');
      await tester.tap(find.text('B. walks'));
      await tester.pumpAndSettle();
      await tapNext('Xem kết quả ôn luyện');
      expect(find.text('Đúng 1 / 2 câu'), findsOneWidget);
      await tester.tap(find.text('Phục thù 1 câu sai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B. goes'));
      await tester.pumpAndSettle();
      await tapNext('Xem kết quả ôn luyện');
      expect(find.text('Đúng 1 / 1 câu'), findsOneWidget);
      expect(progress.wrongIds, isEmpty);
      expect(progress.mastered, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
