import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The owner's original frog, surrounded by code-native illustration shapes.
class QuestMascot extends StatelessWidget {
  const QuestMascot({super.key, this.height = 260, this.compact = false});
  final double height;
  final bool compact;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final diameter = (constraints.maxWidth * (compact ? .8 : .56)).clamp(
          64.0,
          height * .76,
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 20,
              child: Icon(
                Icons.wb_sunny_rounded,
                size: compact ? 25 : 42,
                color: AppColors.yellow,
              ),
            ),
            Positioned(
              bottom: 12,
              left: 4,
              child: Transform.rotate(
                angle: -.5,
                child: Icon(
                  Icons.eco_rounded,
                  size: compact ? 55 : 86,
                  color: const Color(0xFFB2D8AE),
                ),
              ),
            ),
            Positioned(
              bottom: 9,
              right: 2,
              child: Transform.rotate(
                angle: .4,
                child: Icon(
                  Icons.eco_rounded,
                  size: compact ? 45 : 70,
                  color: const Color(0xFF87BF94),
                ),
              ),
            ),
            Container(
              width: diameter,
              height: diameter,
              padding: EdgeInsets.all(compact ? 8 : 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                child: Image.asset(
                  'assets/images/ech_alime.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Ếch Alime ôm sách học tiếng Anh',
                ),
              ),
            ),
            if (!compact) ...[
              const Positioned(
                left: 14,
                top: 28,
                child: _Tile(label: 'Aa', color: AppColors.yellow, angle: -.13),
              ),
              const Positioned(
                right: 14,
                bottom: 42,
                child: _Tile(
                  label: 'Alime!',
                  color: AppColors.lavender,
                  angle: .1,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.color, required this.angle});
  final String label;
  final Color color;
  final double angle;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C203C32),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    ),
  );
}
