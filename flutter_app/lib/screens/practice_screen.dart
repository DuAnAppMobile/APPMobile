import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/practice.dart';
import '../services/practice_service.dart';
import '../services/practice_progress.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_mascot.dart';
import 'practice_quiz_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.player});
  final Player player;
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _service = PracticeService();
  final _progress = PracticeProgress();
  List<PracticeTopic> _topics = [];
  List<PracticeQuestion> _questions = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _progress.load(widget.player.id);
      final topics = await _service.topics();
      final questions = await _service.questions();
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(e);
        });
      }
    }
  }

  String _message(Object e) => e is PracticeException
      ? e.message
      : e is FormatException
      ? e.message
      : 'Không tải được sổ ôn luyện từ máy chủ. Hãy thử lại.';

  Future<void> _start(
    String title,
    List<PracticeQuestion> pool, {
    int limit = 10,
  }) async {
    if (pool.isEmpty) return;
    final shuffled = [...pool]..shuffle();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeQuizScreen(
          player: widget.player,
          title: title,
          questions: shuffled.take(limit).toList(),
          service: _service,
          progress: _progress,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final validIds = _questions.map((q) => q.id).toSet();
    final wrong = _questions
        .where((q) => _progress.wrongIds.contains(q.id))
        .toList();
    final mastered = _progress.latest.entries
        .where((e) => e.value && validIds.contains(e.key))
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Góc ôn luyện')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Luyện công cùng Alime',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sai ở đây để đúng ở ải.\nKhông giờ đếm, không áp lực EXP.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                      child: QuestMascot(height: 120, compact: true),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã nắm vững $mastered / ${_questions.length} câu',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _questions.isEmpty
                            ? 0
                            : mastered / _questions.length,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dựa trên lần trả lời gần nhất của từng câu.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _questions.isEmpty
                      ? null
                      : () => _start('Luyện tổng hợp', _questions),
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Luyện tổng hợp · 10 câu'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: wrong.isEmpty
                      ? null
                      : () => _start(
                          'Ôn lại câu sai',
                          wrong,
                          limit: wrong.length,
                        ),
                  icon: const Icon(Icons.history_edu_rounded),
                  label: Text('Sổ câu sai · ${wrong.length} câu'),
                ),
                if (wrong.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Chưa có câu cần ôn lại. Alime tạm yên lòng.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Chọn chủ đề',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _topics.length; i++)
                  _topicCard(_topics[i], i),
                const SizedBox(height: 12),
                const Text(
                  'Sổ câu sai gồm câu làm trong mục Ôn luyện, lưu trên máy chủ theo tài khoản. '
                  'Trả lời đúng lần sau sẽ đưa câu ra khỏi sổ. Đăng nhập cùng tài khoản và cùng máy chủ trên máy khác để lấy lại tiến độ. Mở lại mục này để cập nhật thay đổi từ thiết bị khác.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topicCard(PracticeTopic topic, int index) {
    final pool = _questions.where((q) => q.topicId == topic.id).toList();
    final learned = pool.where((q) => _progress.latest[q.id] == true).length;
    return Card(
      color: [
        AppColors.lavender,
        AppColors.mint,
        AppColors.peach,
        const Color(0xFFFFF0B7),
      ][index % 4],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text('$learned / ${pool.length} câu đã nắm vững'),
            ExpansionTile(
              title: const Text('Nhắc nhanh kiến thức'),
              tilePadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    topic.lesson,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: pool.isEmpty ? null : () => _start(topic.name, pool),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Luyện ${pool.length} câu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
