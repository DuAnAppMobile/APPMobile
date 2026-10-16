import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/stage.dart';
import '../services/stage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/rpg_shell.dart';
import 'boss_intro_screen.dart';
import 'quiz_screen.dart';

class StagesMapScreen extends StatefulWidget {
  const StagesMapScreen({super.key, required this.player});

  final Player player;

  @override
  State<StagesMapScreen> createState() => _StagesMapScreenState();
}

class _StagesMapScreenState extends State<StagesMapScreen> {
  final _stageService = StageService();
  List<Stage>? _stages;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  @override
  void dispose() {
    _stageService.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    setState(() => _errorMessage = null);
    try {
      final stages = await _stageService.getStages(widget.player.id);
      if (mounted) setState(() => _stages = stages);
    } on StageServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _openStage(Stage stage) async {
    if (stage.isLocked) return;
    var restart = false;
    if (stage.isNormal && stage.hasInProgressAttempt) {
      final shouldRestart = await showResumeStageDialog(context);
      if (shouldRestart == null || !mounted) return;
      restart = shouldRestart;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => stage.isNormal
            ? QuizScreen(player: widget.player, stage: stage, restart: restart)
            : BossIntroScreen(player: widget.player, stage: stage),
      ),
    );
    if (mounted) _loadStages();
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        _stages?.where((stage) => stage.status == 'completed').length ?? 0;
    final columns = MediaQuery.sizeOf(context).width < 350 ? 1 : 2;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ hành trình')),
      body: _stages == null
          ? _buildLoadingOrError()
          : RefreshIndicator(
              onRefresh: _loadStages,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const RpgBadge(
                          icon: Icons.route_rounded,
                          label: 'HÀNH TRÌNH 4 CHẶNG',
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Mỗi bài học,\nmột bước tiến.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _stages!.isEmpty
                                ? 0
                                : completed / _stages!.length,
                            minHeight: 8,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completed/${_stages!.length} ải đã hoàn thành',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chọn bài học của bạn',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đi từng bước nhỏ, chinh phục mục tiêu lớn.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stages!.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 260 * scale,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (_, index) => _buildStageCard(_stages![index]),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStageCard(Stage stage) {
    const colors = [
      AppColors.mint,
      AppColors.lavender,
      AppColors.peach,
      Color(0xFFFFF0B7),
    ];
    const icons = [
      Icons.waving_hand_rounded,
      Icons.auto_stories_rounded,
      Icons.rocket_launch_rounded,
      Icons.emoji_events_rounded,
    ];
    final index = (stage.orderNo - 1).clamp(0, 3);
    final completed = stage.status == 'completed';
    final subtitle = stage.isLocked
        ? 'Hoàn thành ải trước để mở.'
        : completed
        ? 'Đã hoàn thành. Ôn lại nhé!'
        : stage.hasInProgressAttempt
        ? 'Tiếp tục lượt chơi còn dở.'
        : stage.isNormal
        ? 'Sẵn sàng học điều mới?'
        : 'Thử thách cuối hành trình.';
    return Material(
      color: stage.isLocked
          ? Color.lerp(colors[index], Colors.white, .35)
          : colors[index],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: stage.isLocked ? AppColors.border : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: stage.isLocked ? null : () => _openStage(stage),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icons[index],
                      color: stage.isLocked
                          ? AppColors.textMuted
                          : AppColors.primary,
                      size: 27,
                    ),
                  ),
                  const Spacer(),
                  if (completed)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  if (stage.isLocked)
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.textMuted,
                      size: 17,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stage.name,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stage.isLocked
                          ? 'Chưa mở khóa'
                          : completed
                          ? 'Học lại'
                          : 'Vào bài',
                      style: TextStyle(
                        color: stage.isLocked
                            ? AppColors.textMuted
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    stage.isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 17,
                    color: stage.isLocked
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrError() {
    if (_errorMessage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadStages, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
