import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Saathi mark: a steady centre (the user) with a small companion on its orbit.
class SaathiMark extends StatelessWidget {
  const SaathiMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final ringRadius = s * 0.38;
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.075
        ..color = AppColors.textPrimary,
    );
    canvas.drawCircle(center, s * 0.15, Paint()..color = AppColors.textPrimary);
    // Companion sits on the ring at 45°, with a white gap so it reads as separate.
    const angle = -math.pi / 4;
    final companion =
        center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
    canvas.drawCircle(
      companion,
      s * 0.17,
      Paint()..color = AppColors.background,
    );
    canvas.drawCircle(
      companion,
      s * 0.12,
      Paint()..color = AppColors.lavenderStrong,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mark + wordmark. The wordmark stays in Latin script in every language (brand).
class SaathiLogo extends StatelessWidget {
  const SaathiLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Saathi',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SaathiMark(size: size),
          SizedBox(width: size * 0.32),
          Text(
            'Saathi',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: size * 0.78,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}
