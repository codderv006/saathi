import 'package:flutter/painting.dart';

/// The only place raw colour values live. Widgets use these semantic names.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F7F9);
  static const disabledSurface = Color(0xFFEEEEF1);
  static const border = Color(0xFFE8E8ED);

  // Text
  static const textPrimary = Color(0xFF171719);
  static const textSecondary = Color(
    0xFF6E6E77,
  ); // #777780 nudged for AA on white
  static const textTertiary = Color(0xFFA0A0A8);

  // Actions
  static const primaryAction = Color(0xFF171719);
  static const onPrimaryAction = Color(0xFFFFFFFF);

  // Pastel accents — backgrounds only, never as text colour.
  static const lavender = Color(0xFFE9E3FF);
  static const softBlue = Color(0xFFE2EEFF);
  static const mint = Color(0xFFDDF5E8);
  static const peach = Color(0xFFFFE8DC);
  static const paleYellow = Color(0xFFFFF3CC);
  static const rose = Color(0xFFFCE4EB);

  // Strong counterparts for icons/markers drawn on pastels.
  static const lavenderStrong = Color(0xFF5B4BC4);
  static const mintStrong = Color(0xFF1E7A4C);
  static const peachStrong = Color(0xFFB4541F);
  static const roseStrong = Color(0xFFB0304F);

  // Screenshot annotation highlight.
  static const highlight = Color(0xFF5B4BC4);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavender, softBlue],
  );
}
