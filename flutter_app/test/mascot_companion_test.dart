import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_rpg_app/widgets/mascot_companion.dart';
import 'package:english_rpg_app/widgets/mascot_lines.dart';

void main() {
  testWidgets('companion greets, celebrates by name, and encourages mistakes', (
    tester,
  ) async {
    Future<void> show({bool? correct, bool welcome = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotCompanion(
              playerName: 'Minh',
              isCorrect: correct,
              welcome: welcome,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await show(welcome: true);
    expect(find.textContaining('Ếch Alime đây.'), findsOneWidget);
    await show();
    expect(find.textContaining('cổ vũ'), findsOneWidget);
    await show(correct: true);
    final praise = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(
      MascotLines.right.any(
        (s) => praise.contains(s.replaceAll('{name}', 'Minh')),
      ),
      isTrue,
    );
    await show(correct: false);
    final line = tester.widget<Text>(find.byType(Text)).data;
    expect(MascotLines.wrong, contains(line));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MascotCompanion(playerName: 'Minh', isCorrect: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byType(Text)).data, line);
  });
}
