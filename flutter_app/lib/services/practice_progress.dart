import 'dart:convert';


import '../models/practice.dart';
import 'player_service.dart';
import 'practice_service.dart';
import 'auth_client.dart';

/// Production reads server-owned progress. Injected storage is a unit-test double.
class PracticeProgress {
  PracticeProgress({
    Future<String?> Function(String)? read,
    Future<void> Function(String, String)? write,
  }) : _remote = read == null && write == null,
       _read = read ?? ((_) async => null),
       _write = write ?? ((_, _) async {});
  final Future<String?> Function(String) _read;
  final bool _remote;
  final Future<void> Function(String, String) _write;
  final Map<String, bool> latest = {};
  String _key = '';
  Set<String> get wrongIds =>
      latest.entries.where((e) => !e.value).map((e) => e.key).toSet();
  int get mastered => latest.values.where((value) => value).length;

  Future<void> load(int playerId) async {
    _key = 'practice.v1.$apiBaseUrl.$playerId';
    latest.clear();
    if (_remote) {
      if (AuthSession.playerId != playerId) {
        throw const PracticeException('Vui lòng đăng nhập lại.');
      }
      final service = PracticeService();
      try {
        latest.addAll(await service.progress());
      } finally {
        service.dispose();
      }
      return;
    }
    final raw = await _read(_key);
    if (raw == null) return;
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> || data.values.any((v) => v is! bool)) {
      throw const FormatException(
        'Sổ ôn luyện bị lỗi, chưa thể tải dữ liệu đã lưu.',
      );
    }
    latest.addAll(data.cast<String, bool>());
  }

  Future<void> record(PracticeQuestion question, bool correct) async {
    if (_key.isEmpty) throw StateError('Load progress before recording.');
    final updated = {...latest, question.id: correct};
    // Commit in memory only after persistence succeeds, so retry is safe.
    if (!_remote) await _write(_key, jsonEncode(updated));
    latest
      ..clear()
      ..addAll(updated);
  }
}
