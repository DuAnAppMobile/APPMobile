import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/university.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/rpg_shell.dart';
import '../widgets/quest_mascot.dart';
import 'stages_map_screen.dart';
import 'practice_screen.dart';
import 'login_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.player, required this.university});

  final Player player;
  final University university;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _playerService = PlayerService();
  late Player _player;
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _unlockDialogShown = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnlockDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  Future<void> _openStagesMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StagesMapScreen(player: _player)),
    );
    if (mounted) await _refreshPlayer();
  }

  Future<void> _refreshPlayer() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final player = await _playerService.getPlayer(_player.id);
      if (!mounted) return;
      setState(() => _player = player);
    } on PlayerServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }

    if (mounted) await _showUnlockDialogIfNeeded();
  }

  Future<void> _showUnlockDialogIfNeeded() async {
    if (_unlockDialogShown ||
        _player.totalExp < widget.university.expRequired ||
        !mounted) {
      return;
    }

    _unlockDialogShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: AlertDialog(
          icon: const _SparklingUniversityIcon(),
          title: const Text('Chúc mừng!'),
          content: Text(
            'Bạn đã mở khóa ${widget.university.name} '
            '(${widget.university.shortName})!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetExp = widget.university.expRequired;
    final progress = targetExp <= 0
        ? 1.0
        : (_player.totalExp / targetExp).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();
    final isUniversityUnlocked = _player.totalExp >= targetExp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hành trình của bạn'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AccountScreen(playerId: _player.id),
                ),
              );
              if (mounted) await _refreshPlayer();
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _isRefreshing
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất tài khoản?'),
                        content: const Text(
                          'Tiến độ đã lưu vẫn nằm trên máy chủ.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Ở lại'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !mounted) return;
                    setState(() => _isRefreshing = true);
                    try {
                      await _playerService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                        (_) => false,
                      );
                    } catch (_) {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                          _errorMessage =
                              'Chưa thể đăng xuất. Kiểm tra mạng rồi thử lại.';
                        });
                      }
                    }
                  },
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refreshPlayer,
            tooltip: 'Cập nhật',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlayer,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/ech_alime.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHÀO MỪNG TRỞ LẠI',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _player.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                RpgBadge(
                  icon: Icons.bolt_rounded,
                  label: '${_player.totalExp} EXP',
                  color: AppColors.exp,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0B7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hôm nay, mình\ncùng tiến bộ!',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Một bài học nhỏ.\nThêm một chút tự tin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 108,
                    child: QuestMascot(height: 120, compact: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.mint, Color(0xFFF2F8DE)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: .35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .18),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.exp,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      RpgBadge(
                        icon: isUniversityUnlocked
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        label: isUniversityUnlocked ? 'ĐÃ MỞ KHÓA' : 'MỤC TIÊU',
                        color: isUniversityUnlocked
                            ? AppColors.success
                            : AppColors.primaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.university.shortName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.university.name,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_player.totalExp} / $targetExp EXP',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$progressPercent%',
                        style: const TextStyle(
                          color: AppColors.exp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Semantics(
                      label: 'Tiến độ EXP: $progressPercent%',
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        color: AppColors.exp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassPanel(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bản đồ thử thách',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '3 ải thường và trận Boss cuối',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                'Không thể cập nhật EXP: $_errorMessage',
                style: TextStyle(color: AppColors.error),
              ),
              TextButton(
                onPressed: _isRefreshing ? null : _refreshPlayer,
                child: const Text('Thử cập nhật lại'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openStagesMap,
              icon: const Icon(Icons.sports_martial_arts_rounded),
              label: const Text('Tiếp tục phiêu lưu'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeScreen(player: _player),
                ),
              ),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Ôn luyện cùng Alime'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklingUniversityIcon extends StatefulWidget {
  const _SparklingUniversityIcon();

  @override
  State<_SparklingUniversityIcon> createState() =>
      _SparklingUniversityIconState();
}

class _SparklingUniversityIconState extends State<_SparklingUniversityIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleAnimation = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.school_rounded, size: 42, color: AppColors.exp),
          Positioned(top: 4, right: 5, child: _buildSparkle(size: 17)),
          Positioned(bottom: 8, left: 5, child: _buildSparkle(size: 13)),
          Positioned(top: 13, left: 7, child: _buildSparkle(size: 10)),
        ],
      ),
    );
  }

  Widget _buildSparkle({required double size}) {
    return FadeTransition(
      opacity: _sparkleAnimation,
      child: ScaleTransition(
        scale: _sparkleAnimation,
        child: Icon(Icons.auto_awesome, size: size, color: AppColors.exp),
      ),
    );
  }
}
