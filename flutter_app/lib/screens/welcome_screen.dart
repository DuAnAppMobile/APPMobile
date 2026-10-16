import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/rpg_shell.dart';
import '../widgets/quest_mascot.dart';
import '../widgets/mascot_companion.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _showTeamNote(BuildContext context) async {
    final start = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.favorite_rounded,
          color: AppColors.exp,
          size: 32,
        ),
        title: const Text('Một lời nhắn từ chúng mình'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'English Quest là sản phẩm được tạo nên từ tâm huyết, sự cố gắng '
                'và tinh thần đồng hành của cả tập thể nhóm.',
              ),
              SizedBox(height: 16),
              Text(
                'Từng màn hình, từng câu hỏi là một phần của hành trình chúng mình '
                'cùng học, cùng sửa và cùng làm tốt hơn. Dù vẫn có thể còn những '
                'điều chưa hoàn hảo, chúng mình hy vọng ứng dụng sẽ mang đến cho '
                'bạn một trải nghiệm học tiếng Anh thật vui và ý nghĩa.',
              ),
              SizedBox(height: 16),
              Text(
                'Cảm ơn bạn đã ghé thăm và trở thành một phần của hành trình này. 💛',
                style: TextStyle(
                  color: AppColors.exp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Quay lại'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
    if (start == true && context.mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        size: 23,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'english quest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const QuestMascot(height: 260),
                const SizedBox(height: 12),
                const MascotCompanion(welcome: true),
                const SizedBox(height: 28),
                const Text(
                  'Chào mừng bạn đến với',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Học tiếng Anh,\nvui mỗi ngày.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ếch Alime ôm sách, bạn ôm ước mơ.\nMặt có thể sầu, kiến thức vẫn phải lên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.6),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RpgBadge(
                      icon: Icons.bolt_rounded,
                      label: 'Học theo từng ải',
                    ),
                    RpgBadge(
                      icon: Icons.school_rounded,
                      label: 'Chạm tới ước mơ',
                      color: AppColors.exp,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Tiếp tục',
                  isLoading: false,
                  onPressed: () => _showTeamNote(context),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Một sản phẩm từ tâm huyết của cả nhóm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
