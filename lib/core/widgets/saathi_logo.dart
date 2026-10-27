import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Saathi mark: the two figures from the app icon (built by tools/build_icons.py).
class SaathiMark extends StatelessWidget {
  const SaathiMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/brand/saathi_logo.png',
      height: size,
      filterQuality: FilterQuality.medium,
    ),
  );
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
          SaathiMark(size: size * 1.2),
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
