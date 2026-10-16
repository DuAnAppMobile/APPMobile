import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/practice.dart';
import '../services/practice_progress.dart';
import '../services/practice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_companion.dart';
import '../widgets/answer_meme.dart';

class PracticeQuizScreen extends StatefulWidget {
  const PracticeQuizScreen({
    super.key,
    required this.player,
    required this.title,
    required this.questions,
    required this.service,
    required this.progress,
  });
  final Player player;
  final String title;
  final List<PracticeQuestion> questions;
  final PracticeService service;
  final PracticeProgress progress;
  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  final _scroll = ScrollController();
  late List<PracticeQuestion> _questions = [...widget.questions];
  final Map<String, PracticeResult> _results = {};
  int _index = 0;
  int? _selected;
  bool _busy = false, _finished = false, _canPop = false;
  String? _error;
  PracticeResult? get _result => _results[_questions[_index].id];
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _answer(int selected) async {
    if (_busy || _result != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final question = _questions[_index];
    try {
      final result = await widget.service.answer(question.id, selected);
      await widget.progress.record(question, result.isCorrect);
      if (!mounted) return;
      setState(() {
        _selected = selected;
        _results[question.id] = result;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PracticeException
              ? e.message
              : e is FormatException
              ? e.message
              : 'Chưa lưu được kết quả. Hãy chọn lại đáp án để thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_busy || _result == null) return;
    setState(() {
      if (_index == _questions.length - 1) {
        _finished = true;
      } else {
        _index++;
        _selected = null;
        _error = null;
      }
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _exit() async {
    if (_busy) return;
    final leave =
        _finished ||
        _results.isEmpty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Tạm nghỉ luyện công?'),
                content: const Text(
                  'Các câu đã trả lời được giữ trong sổ ôn luyện. Lần sau sẽ bắt đầu lượt mới.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Ở lại'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Tạm nghỉ'),
                  ),
                ],
              ),
            ) ==
            true;
    if (leave && mounted) {
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Chưa có câu hỏi để ôn.')),
      );
    }
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            onPressed: _busy ? null : _exit,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        bottomNavigationBar: _finished
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: MascotCompanion(
                    playerName: widget.player.name,
                    isCorrect: _result?.isCorrect,
                    questionNumber: _index,
                  ),
                ),
              ),
        body: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: _finished ? _summary() : _question(),
        ),
      ),
    );
  }

  List<Widget> _question() {
    final question = _questions[_index];
    final result = _result;
    return [
      Text(
        'Ôn luyện · Câu ${_index + 1} / ${_questions.length} · Không tính EXP',
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: _results.length / _questions.length),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          question.content,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < question.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: AppColors.text,
              disabledBackgroundColor: result == null
                  ? null
                  : i == result.correctIndex
                  ? AppColors.mint
                  : i == _selected
                  ? AppColors.peach
                  : AppColors.surface,
            ),
            onPressed: _busy || result != null ? null : () => _answer(i),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${String.fromCharCode(65 + i)}. ${question.options[i]}',
              ),
            ),
          ),
        ),
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
        ),
      if (result != null) ...[
        AnswerMeme(correct: result.isCorrect, questionNumber: _index),
        Text(
          result.isCorrect
              ? 'Chính xác!'
              : 'Chưa đúng · Đáp án ${String.fromCharCode(65 + result.correctIndex)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(result.explanation, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _next,
          child: Text(
            _index == _questions.length - 1
                ? 'Xem kết quả ôn luyện'
                : 'Câu tiếp theo',
          ),
        ),
      ],
    ];
  }

  List<Widget> _summary() {
    final correct = _results.values.where((r) => r.isCorrect).length;
    final wrong = _questions
        .where((q) => _results[q.id]?.isCorrect == false)
        .toList();
    return [
      const Icon(Icons.menu_book_rounded, size: 56, color: AppColors.primary),
      const SizedBox(height: 16),
      Text(
        'Xong một hiệp luyện công!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Text(
        'Đúng $correct / ${_questions.length} câu',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Không thay đổi EXP hoặc tiến độ ải.\nKết quả từng câu đã được lưu trên máy chủ.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      if (wrong.isNotEmpty)
        FilledButton.icon(
          onPressed: () {
            setState(() {
              _questions = [...wrong]..shuffle();
              _results.clear();
              _index = 0;
              _selected = null;
              _finished = false;
              _error = null;
            });
            if (_scroll.hasClients) _scroll.jumpTo(0);
          },
          icon: const Icon(Icons.replay),
          label: Text('Phục thù ${wrong.length} câu sai'),
        ),
      OutlinedButton(onPressed: _exit, child: const Text('Về góc ôn luyện')),
      const SizedBox(height: 20),
      for (final q in _questions)
        ExpansionTile(
          leading: Icon(
            _results[q.id]!.isCorrect ? Icons.check_circle : Icons.refresh,
            color: _results[q.id]!.isCorrect
                ? AppColors.success
                : AppColors.error,
          ),
          title: Text(q.content),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Đáp án: ${q.options[_results[q.id]!.correctIndex]}\n\n${_results[q.id]!.explanation}',
              ),
            ),
          ],
        ),
    ];
  }
}
