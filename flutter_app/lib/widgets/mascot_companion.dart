import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_lines.dart';

/// A finite greeting/celebration: never loops while the learner is reading.
class MascotCompanion extends StatefulWidget {
  const MascotCompanion({
    super.key,
    this.playerName,
    this.isCorrect,
    this.questionNumber = 0,
    this.welcome = false,
  });
  final String? playerName;
  final bool? isCorrect;
  final int questionNumber;
  final bool welcome;

  @override
  State<MascotCompanion> createState() => _MascotCompanionState();
}

class _MascotCompanionState extends State<MascotCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _updateMessage();
    _motion.forward();
  }

  @override
  void didUpdateWidget(covariant MascotCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCorrect != oldWidget.isCorrect ||
        widget.questionNumber != oldWidget.questionNumber ||
        widget.welcome != oldWidget.welcome) {
      _updateMessage();
    }
    if (widget.isCorrect != null && oldWidget.isCorrect != widget.isCorrect) {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  late String _message;

  void _updateMessage() {
    if (widget.welcome) {
      _message = 'Ếch Alime đây. Mặt hơi sầu,\nnhưng vẫn gánh bạn qua môn.';
    } else if (widget.isCorrect != null) {
      _message = MascotLines.shared.next(
        widget.isCorrect!,
        widget.playerName ?? '',
      );
    } else {
      _message = 'Alime đang cổ vũ bạn.\nMặt sầu thôi, vẫn tin bạn làm được.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final celebrating = widget.isCorrect == true;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: reducedMotion ? 0 : 250),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: celebrating ? AppColors.mint : AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _message,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _motion,
            builder: (context, child) {
              final wave = reducedMotion
                  ? 0.0
                  : math.sin(_motion.value * math.pi * 4);
              return Transform.translate(
                offset: Offset(0, -wave.abs() * (celebrating ? 16 : 6)),
                child: Transform.rotate(
                  angle: wave * .07,
                  child: Transform.scale(
                    scaleX: 1 + wave.abs() * .04,
                    scaleY: 1 - wave.abs() * .03,
                    child: child,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 96,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 92,
                    height: 112,
                    child: Image.asset(
                      'assets/images/ech_alime.png',
                      fit: BoxFit.contain,
                      semanticLabel: 'Ếch Alime ôm sách, bạn đồng hành mặt sầu',
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      celebrating
                          ? Icons.auto_awesome_rounded
                          : Icons.favorite_rounded,
                      size: 23,
                      color: celebrating ? AppColors.exp : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
