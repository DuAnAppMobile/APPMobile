import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/university.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/rpg_shell.dart';
import 'home_screen.dart';

class UniversitySelectionScreen extends StatefulWidget {
  const UniversitySelectionScreen({super.key, required this.player});

  final Player player;

  @override
  State<UniversitySelectionScreen> createState() =>
      _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  final _playerService = PlayerService();
  List<University>? _universities;
  String? _errorMessage;
  int? _savingUniversityId;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    setState(() => _errorMessage = null);
    try {
      final universities = await _playerService.getUniversities();
      if (mounted) setState(() => _universities = universities);
    } on PlayerServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _selectUniversity(University university) async {
    setState(() {
      _savingUniversityId = university.id;
      _errorMessage = null;
    });

    try {
      final player = await _playerService.setTarget(widget.player, university);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(player: player, university: university),
        ),
      );
    } on PlayerServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _savingUniversityId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn đích đến')),
      body: _universities == null
          ? _buildLoadingOrError()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: _universities!.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const RpgBadge(
                          icon: Icons.explore_rounded,
                          label: 'CHƯƠNG 1 · ƯỚC MƠ',
                          color: AppColors.cyan,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Em muốn chạm tới\nngôi trường nào?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chào ${widget.player.name}! Hãy chọn thật kỹ nhé — mục tiêu sẽ đồng hành cùng em suốt hành trình.',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final university = _universities![index - 1];
                final isSaving = _savingUniversityId == university.id;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    enabled: _savingUniversityId == null,
                    leading: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: [
                          AppColors.mint,
                          AppColors.lavender,
                          AppColors.peach,
                          AppColors.yellow,
                        ][(index - 1) % 4],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        university.shortName.length > 3
                            ? university.shortName.substring(0, 3)
                            : university.shortName,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      university.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${university.shortName}  ·  ${university.expRequired} EXP',
                      style: const TextStyle(
                        color: AppColors.exp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => _selectUniversity(university),
                  ),
                );
              },
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
            FilledButton(
              onPressed: _loadUniversities,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
