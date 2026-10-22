import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Soft gradient backdrop with two blurred colour blooms. Calm, not busy.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFFF5F2FF)],
            ),
          ),
        ),
      ),
      Positioned(
        top: -120,
        right: -100,
        child: _bloom(AppColors.lavender, 320),
      ),
      Positioned(
        bottom: -140,
        left: -120,
        child: _bloom(AppColors.softBlue, 360),
      ),
      Positioned.fill(child: child),
    ],
  );

  static Widget _bloom(Color color, double size) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
