import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';

enum HelpChoice { repeat, simpler, showAgain, goBack, talk, stop }

/// "I need help" options. None of them advance the workflow.
Future<HelpChoice?> showHelpSheet(
  BuildContext context, {
  required bool canGoBack,
  required bool hasScreenshot,
}) {
  final l10n = AppLocalizations.of(context);
  final options = [
    (HelpChoice.repeat, Icons.replay_rounded, l10n.helpRepeat),
    (HelpChoice.simpler, Icons.lightbulb_outline_rounded, l10n.helpSimpler),
    if (hasScreenshot)
      (HelpChoice.showAgain, Icons.image_outlined, l10n.helpShowAgain),
    if (canGoBack) (HelpChoice.goBack, Icons.undo_rounded, l10n.helpGoBack),
    (HelpChoice.talk, Icons.mic_none_rounded, l10n.helpTalk),
    (HelpChoice.stop, Icons.pause_circle_outline_rounded, l10n.helpStop),
  ];
  return showModalBottomSheet<HelpChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helpTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (choice, icon, label) in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                minVerticalPadding: AppSpacing.sm,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.textPrimary),
                ),
                title: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => Navigator.pop(context, choice),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Lets the user copy an address to paste into the ride app themselves. Saathi never pastes.
Future<void> showCopyTextSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CopyTextSheet(),
    );

class _CopyTextSheet extends StatefulWidget {
  const _CopyTextSheet();

  @override
  State<_CopyTextSheet> createState() => _CopyTextSheetState();
}

class _CopyTextSheetState extends State<_CopyTextSheet> {
  final _text = TextEditingController();
  String? _message;
  bool _copied = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final value = _text.text.trim();
    if (value.isEmpty) {
      setState(() => _message = l10n.copyEmpty);
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: value));
      setState(() {
        _copied = true;
        _message = l10n.copied;
      });
    } catch (_) {
      setState(() => _message = l10n.copyFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.copySheetTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.copySheetBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _text,
                minLines: 2,
                maxLines: 4,
                style: theme.textTheme.bodyLarge,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {
                  _copied = false;
                  _message = null;
                }),
                decoration: InputDecoration(
                  labelText: l10n.copyFieldLabel,
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _copied
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _message!,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _copied ? l10n.continueAction : l10n.copyAction,
                icon: _copied ? null : Icons.copy_rounded,
                onPressed: _copied ? () => Navigator.pop(context) : _copy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
