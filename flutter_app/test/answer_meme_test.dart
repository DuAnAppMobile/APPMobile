import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_rpg_app/widgets/answer_meme.dart';

void main() {
  testWidgets('correct and incorrect answers select their own meme pools', (
    tester,
  ) async {
    for (final correct in [true, false]) {
      for (var question = 0; question < 10; question++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerMeme(correct: correct, questionNumber: question),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        final path = (image.image as AssetImage).assetName;
        expect(
          correct ? [3, 6, 1, 7] : [0, 2],
          contains(
            int.parse(RegExp(r'meme_(\d+)').firstMatch(path)!.group(1)!),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
