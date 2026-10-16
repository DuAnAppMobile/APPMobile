import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnswerMeme extends StatelessWidget {
  const AnswerMeme({
    super.key,
    required this.correct,
    required this.questionNumber,
  });
  final bool correct;
  final int questionNumber;

  @override
  Widget build(BuildContext context) {
    // Keep reactions playful and supportive; avoid insulting the learner.
    const happy = [3, 6, 1, 7];
    const retry = [0, 2];
    final pool = correct ? happy : retry;
    final index = pool[questionNumber % pool.length];
    final caption = correct
        ? [
            'Kiến thức +1, tự tin +100!',
            'Chuẩn không cần chỉnh!',
            'Giỏi quá, ngại giùm luôn!',
            'Tâm bất biến giữa vạn câu hỏi!',
          ][questionNumber % happy.length]
        : [
            'Ếch rơi nước mắt… nhưng mình học tiếp nha!',
            'Khoan, để ếch load lại kiến thức!',
          ][questionNumber % retry.length];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct ? AppColors.mint : AppColors.lavender,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/meme_$index.png',
              height: 140,
              fit: BoxFit.contain,
              semanticLabel: correct
                  ? 'Meme ếch ăn mừng'
                  : 'Meme ếch động viên',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
