import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:english_rpg_app/models/practice.dart';
import 'package:english_rpg_app/services/practice_service.dart';
import 'package:english_rpg_app/services/practice_progress.dart';
import 'package:english_rpg_app/widgets/mascot_lines.dart';

void main() {
  const question = PracticeQuestion('t1', 'tenses', 'Question?', [
    'A',
    'B',
    'C',
    'D',
  ]);
  test(
    'shuffle bags exhaust pool before repeating, including refill boundary',
    () {
      final lines = MascotLines(random: Random(7));
      for (final correct in [false, true]) {
        final size = correct
            ? MascotLines.right.length
            : MascotLines.wrong.length;
        final drawn = List.generate(size, (_) => lines.next(correct, 'Minh'));
        expect(drawn.toSet().length, size);
        expect(lines.next(correct, 'Minh'), isNot(drawn.last));
        expect(drawn.any((s) => s.contains('{name}')), isFalse);
      }
    },
  );
  test('progress survives repository recreation, isolates players, clears resolved mistakes', () async {
    final memory = <String, String>{};
    PracticeProgress store() => PracticeProgress(
      read: (key) async => memory[key],
      write: (key, value) async {
        memory[key] = value;
      },
    );
    final first = store();
    await first.load(42);
    await first.record(question, false);
    await first.record(question, false);
    expect(first.wrongIds, {'t1'});
    final reloaded = store();
    await reloaded.load(42);
    expect(reloaded.wrongIds, {'t1'});
    await reloaded.record(question, true);
    expect(reloaded.wrongIds, isEmpty);
    expect(reloaded.mastered, 1);
    await first.load(43);
    expect(first.latest, isEmpty);
  });
  test('failed storage write does not falsely commit result', () async {
    final store = PracticeProgress(
      read: (_) async => null,
      write: (_, _) async => throw Exception('disk'),
    );
    await store.load(1);
    await expectLater(store.record(question, true), throwsException);
    expect(store.latest, isEmpty);
  });
  test(
    'practice API sends selected index and parses grading response',
    () async {
      final service = PracticeService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/practice/answer');
          expect(jsonDecode(request.body), {
            'questionId': 't1',
            'selectedIndex': 2,
          });
          return http.Response(
            jsonEncode({
              'isCorrect': false,
              'correctIndex': 1,
              'explanation': 'Vì chủ ngữ số ít.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await service.answer('t1', 2);
      expect(result.isCorrect, isFalse);
      expect(result.correctIndex, 1);
      service.dispose();
    },
  );
  test(
    'API rejects malformed results, bad status and connection errors',
    () async {
      for (final response in [
        http.Response('{}', 200),
        http.Response('{}', 500),
      ]) {
        final service = PracticeService(
          client: MockClient((_) async => response),
        );
        await expectLater(
          service.answer('t1', 0),
          throwsA(anyOf(isA<FormatException>(), isA<PracticeException>())),
        );
        service.dispose();
      }
      final service = PracticeService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(service.questions(), throwsA(isA<PracticeException>()));
      service.dispose();
    },
  );
  test('invalid question structure never enters practice', () {
    expect(
      () => PracticeQuestion.fromJson({
        'id': 'x',
        'topicId': 't',
        'content': '?',
        'options': ['only one'],
      }),
      throwsFormatException,
    );
  });
}
