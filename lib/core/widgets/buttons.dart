import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Full-width primary action. While [busy], it shows progress and ignores taps,
/// which prevents duplicate submissions.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: _ButtonContent(
        label: label,
        icon: icon,
        busy: busy,
        color: AppColors.onPrimaryAction,
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      child: _ButtonContent(label: label, icon: icon),
    ),
  );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    this.icon,
    this.busy = false,
    this.color,
  });

  final String label;
  final IconData? icon;
  final bool busy;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(
      child: Text(label, textAlign: TextAlign.center, softWrap: true),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(icon, size: 22),
            ),
          text,
        ],
      ),
    );
  }
}

/// Compact labelled action with an icon on top, for secondary rows (Repeat / Help).
class QuietAction extends StatelessWidget {
  const QuietAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
      backgroundColor: AppColors.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium!.copyWith(fontSize: 16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
