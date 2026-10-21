import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/workflow.dart';

/// Shown only after the user explicitly reported the outcome. The success message
/// repeats what the user told us; Saathi has not verified anything in the ride app.
class CompletionScreen extends StatelessWidget {
  const CompletionScreen({
    super.key,
    required this.outcome,
    required this.appName,
  });

  final Outcome outcome;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final success = outcome == Outcome.succeeded;
    void home() => Navigator.of(context).popUntil((r) => r.isFirst);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: success ? AppColors.mint : AppColors.softBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          success
                              ? Icons.check_rounded
                              : Icons.self_improvement_rounded,
                          size: 36,
                          color: success
                              ? AppColors.mintStrong
                              : AppColors.lavenderStrong,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          success
                              ? l10n.completedTitle
                              : l10n.notCompletedTitle,
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        success
                            ? l10n.completedBody(appName)
                            : l10n.notCompletedBody,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: success ? l10n.done : l10n.returnHome,
                onPressed: home,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
