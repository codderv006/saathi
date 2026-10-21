import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum StatusTone { neutral, warning, error }

/// Plain-language message with an icon. Used for errors, empty and recovery states.
/// Tone is shown by icon and wording, never colour alone.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = StatusTone.neutral,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? body;
  final StatusTone tone;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (AppColors.softBlue, AppColors.lavenderStrong),
      StatusTone.warning => (AppColors.paleYellow, AppColors.peachStrong),
      StatusTone.error => (AppColors.rose, AppColors.roseStrong),
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.titleLarge),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body!,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              a,
            ],
          ],
        ],
      ),
    );
  }
}

/// Small inline notice (e.g. the money-safety note on sensitive steps).
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.icon,
    required this.text,
    this.background = AppColors.paleYellow,
  });

  final IconData icon;
  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}
