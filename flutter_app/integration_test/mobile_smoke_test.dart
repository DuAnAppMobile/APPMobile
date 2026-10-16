import 'package:english_rpg_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:english_rpg_app/widgets/answer_meme.dart';
import 'package:english_rpg_app/services/practice_service.dart';
import 'package:english_rpg_app/widgets/mascot_companion.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile login, target, map, question and answer use real API', (
    tester,
  ) async {
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsWidgets);
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      for (var i = 0; i < 5 && finder.hitTestable().evaluate().isEmpty; i++) {
        final y = tester.getCenter(finder).dy;
        await tester.drag(find.byType(Scrollable).first,
          Offset(0, y < 0 ? 180 : -180));
        await tester.pumpAndSettle();
      }
      expect(finder.hitTestable(), findsOneWidget);
      await tester.tap(finder);
    }

    app.main();
    await tester.pumpAndSettle();
    const capture = bool.fromEnvironment('CAPTURE_UI');
    if (capture && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    Future<void> screenshot(String name) async {
      if (capture) {
        await tester.pumpAndSettle();
        await binding.takeScreenshot(name);
      }
    }

    await screenshot('01-welcome');
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Một lời nhắn từ chúng mình'), findsOneWidget);
    await screenshot('02-team-note');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    await screenshot('03-login');
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    final username = 'minh_${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'TestOnly12345');
    await tester.enterText(find.byType(TextField).at(2), 'TestOnly12345');
    final login = find.text('Đăng ký và bắt đầu');
    await tester.ensureVisible(login);
    await tester.tap(login);
    final university = find.text('ĐH Kinh tế TP.HCM');
    await waitFor(university);
    await tester.ensureVisible(university);
    await tester.tap(university);
    await waitFor(find.text('Hành trình của bạn'));
    await screenshot('04-home');
    final practiceButton = find.text('Ôn luyện cùng Alime');
    await tapVisible(practiceButton);
    await waitFor(find.text('Chọn chủ đề'));
    await screenshot('08-practice-hub');
    final topicButton = find.text('Luyện 6 câu').first;
    await tester.scrollUntilVisible(
      topicButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(topicButton);
    await tester.pumpAndSettle();
    final practiceApi = PracticeService();
    final bank = await practiceApi.questions(topicId: 'tenses');
    final current = bank.firstWhere(
      (q) => find.text(q.content).evaluate().isNotEmpty,
    );
    final solution = await practiceApi.answer(current.id, 0);
    final wrongIndex = (solution.correctIndex + 1) % 4;
    await tester.tap(
      find.text(
        '${String.fromCharCode(65 + wrongIndex)}. ${current.options[wrongIndex]}',
      ),
    );
    await waitFor(
      find.byWidgetPredicate(
        (w) => w is MascotCompanion && w.isCorrect == false,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Câu tiếp theo'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<AnswerMeme>(find.byType(AnswerMeme)).correct, isFalse);
    await screenshot('09-practice-wrong');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạm nghỉ'));
    await tester.pumpAndSettle();
    final notebook = find.text('Sổ câu sai · 1 câu');
    await tester.scrollUntilVisible(
      notebook,
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(notebook);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        '${String.fromCharCode(65 + solution.correctIndex)}. ${current.options[solution.correctIndex]}',
      ),
    );
    await waitFor(
      find.byWidgetPredicate(
        (w) => w is MascotCompanion && w.isCorrect == true,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Xem kết quả ôn luyện'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem kết quả ôn luyện'));
    await tester.pumpAndSettle();
    expect(find.text('Đúng 1 / 1 câu'), findsOneWidget);
    await screenshot('10-practice-summary');
    await tester.tap(find.text('Về góc ôn luyện'));
    await tester.pumpAndSettle();
    expect(find.text('Sổ câu sai · 0 câu'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    practiceApi.dispose();
    final mapButton = find.text('Tiếp tục phiêu lưu');
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    final stage = find.text('Ải 1: Khởi đầu');
    await waitFor(stage);
    await screenshot('05-lessons');
    await tester.tap(stage);
    final question = find.text(
      'Choose the correct form: Lan ___ English every evening.',
    );
    await waitFor(question);
    await screenshot('06-question');
    final answer = find.text('B. studies');
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await waitFor(find.byType(AnswerMeme));
    await tester.scrollUntilVisible(
      find.text('Chính xác!'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AnswerMeme>(find.byType(AnswerMeme)).correct, isTrue);
    await screenshot('07-mascot-celebration');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await waitFor(find.text('Tên tài khoản'));
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'TestOnly12345');
    final signIn = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await waitFor(find.text('Hành trình của bạn'));
    await tapVisible(find.text('Ôn luyện cùng Alime'));
    await waitFor(find.text('Sổ câu sai · 0 câu'));
    expect(find.text('Đã nắm vững 1 / 24 câu'), findsOneWidget);
    await screenshot('11-restored-after-login');
    expect(find.text('Mất kết nối'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
