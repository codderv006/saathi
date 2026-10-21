import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 underneath, restyled to Saathi's calm light look.
/// Typography uses the platform font (Roboto / Noto Devanagari on Android).
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryAction,
      onPrimary: AppColors.onPrimaryAction,
      secondary: AppColors.lavenderStrong,
      onSecondary: AppColors.onPrimaryAction,
      error: AppColors.roseStrong,
      onError: AppColors.onPrimaryAction,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceMuted,
      surfaceContainer: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.disabledSurface,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    const text = TextTheme(
      // Hero
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
      // Screen heading
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      ),
      // Section heading
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 17,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      // Supporting
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      // Metadata
      bodySmall: TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
    );
    const buttonSize = Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.onPrimaryAction,
          disabledBackgroundColor: AppColors.disabledSurface,
          disabledForegroundColor: AppColors.textTertiary,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          foregroundColor: AppColors.textPrimary,
          textStyle: text.titleMedium,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: text.bodyLarge!.copyWith(
          color: AppColors.onPrimaryAction,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.textPrimary,
        linearTrackColor: AppColors.disabledSurface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.background),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryAction
              : AppColors.disabledSurface,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
