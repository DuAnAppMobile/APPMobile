import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:english_rpg_app/main.dart';

void main() {
  testWidgets('shows player name input and validates empty submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EnglishRpgApp());

    expect(find.text('Chào mừng bạn đến với'), findsOneWidget);
    expect(find.text('Tên tài khoản'), findsNothing);
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Một lời nhắn từ chúng mình'), findsOneWidget);
    expect(find.text('Tên tài khoản'), findsNothing);
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    expect(find.text('Tên tài khoản'), findsOneWidget);
    final startButton = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pump();

    expect(find.text('Vui lòng nhập tên tài khoản.'), findsOneWidget);
  });
}
