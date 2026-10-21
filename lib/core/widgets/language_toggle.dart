import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// English / मराठी switch bound to the saved language preference.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false, this.enabled = true});

  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l10n = AppLocalizations.of(context);
    final options = {'en': l10n.languageEnglish, 'mr': l10n.languageMarathi};
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius + 3),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            for (final entry in options.entries)
              _Segment(
                label: entry.value,
                selected: settings.language == entry.key,
                compact: compact,
                onTap: enabled ? () => settings.setLanguage(entry.key) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final segment = Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.background : Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          side: selected
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: compact ? 40 : AppSpacing.minTouchTarget,
              minWidth: compact ? 72 : 0,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return compact ? segment : Expanded(child: segment);
  }
}
