import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/stage.dart';
import '../services/stage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/rpg_shell.dart';
import 'boss_quiz_screen.dart';

class BossIntroScreen extends StatefulWidget {
  const BossIntroScreen({super.key, required this.player, required this.stage});

  final Player player;
  final Stage stage;

  @override
  State<BossIntroScreen> createState() => _BossIntroScreenState();
}

class _BossIntroScreenState extends State<BossIntroScreen> {
  final _stageService = StageService();
  bool _isStarting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _stageService.dispose();
    super.dispose();
  }

  Future<void> _startBoss() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });
    try {
      final attempt = await _stageService.startBossStage(
        playerId: widget.player.id,
        stageId: widget.stage.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BossQuizScreen(stage: widget.stage, attempt: attempt),
        ),
      );
      if (mounted) setState(() => _isStarting = false);
    } on StageServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) {
        setState(() {
          _isStarting = false;
          _errorMessage = error.message;
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _errorMessage = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu Boss')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [AppColors.peach, Color(0xFFFFD2AE)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: .4),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 58,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const RpgBadge(
                  icon: Icons.warning_amber_rounded,
                  label: 'THỬ THÁCH CUỐI',
                  color: AppColors.error,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.stage.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cánh cổng cuối đã mở. Bình tĩnh, tập trung và chiến đấu hết mình nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                const GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Luật giao chiến',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 16),
                      _BossRule(
                        icon: Icons.quiz_rounded,
                        text: '15 câu hỏi',
                        detail: 'Chọn ngẫu nhiên mỗi lượt',
                      ),
                      _BossRule(
                        icon: Icons.timer_rounded,
                        text: '30 phút',
                        detail: 'Đồng hồ không dừng',
                      ),
                      _BossRule(
                        icon: Icons.workspace_premium_rounded,
                        text: '13/15 để thắng',
                        detail: 'Thưởng lần đầu 2.000 EXP',
                      ),
                      _BossRule(
                        icon: Icons.visibility_off_rounded,
                        text: 'Ẩn kết quả',
                        detail: 'Đáp án hiện sau khi nộp',
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isStarting ? null : _startBoss,
                  child: _isStarting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bước vào trận Boss  →'),
                ),
                OutlinedButton(
                  onPressed: _isStarting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BossRule extends StatelessWidget {
  const _BossRule({
    required this.icon,
    required this.text,
    required this.detail,
  });
  final IconData icon;
  final String text;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.error, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
