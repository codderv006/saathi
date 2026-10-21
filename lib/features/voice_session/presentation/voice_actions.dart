import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../guided_workflow/domain/workflow.dart';
import 'voice_session_screen.dart';

/// Starts a voice call with the current guide step as context, explaining the
/// microphone first if Android hasn't granted it yet. Opens the voice screen.
Future<void> startVoiceSession(
  BuildContext context, {
  bool openScreen = true,
  bool fromGuide = false,
}) async {
  final services = AppScope.of(context);
  final voice = services.voice;
  if (voice.status.isBusy) {
    if (openScreen) _openScreen(context, fromGuide);
    return;
  }

  final perms = await services.android.permissionState();
  if (perms['microphone'] != true) {
    if (!context.mounted) return;
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MicRationaleSheet(),
    );
    if (agreed != true) return;
  }
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context);
  final language = services.settings.language;
  final session = services.guide.session;
  final step = services.guide.currentStep;
  final def = services.guide.definition;
  // Only attach the guide when the call is about it: started inside the guide, or
  // the guide is actively open. A paused guide is not assumed.
  final guideOpen =
      session != null &&
      step != null &&
      def != null &&
      (fromGuide ? session.isOpen : session.status == SessionStatus.active);
  if (openScreen) _openScreen(context, fromGuide);
  await voice.start(
    language: language,
    context: {
      if (guideOpen) ...{
        'saathi_task': def.title.of(language),
        'saathi_step':
            '${l10n.stepOf(def.indexOf(step.id) + 1, def.steps.length)}: '
            '${step.title.of(language)}',
        'saathi_instruction': step.instruction.of(language),
      },
    },
  );
}

void _openScreen(BuildContext context, bool fromGuide) {
  final route = ModalRoute.of(context);
  if (route?.settings.name == VoiceSessionScreen.routeName) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: VoiceSessionScreen.routeName),
      builder: (_) => VoiceSessionScreen(fromGuide: fromGuide),
    ),
  );
}

class _MicRationaleSheet extends StatelessWidget {
  const _MicRationaleSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
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
            const Icon(Icons.mic_none_rounded, size: 36),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.micRationaleTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.micRationaleBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.continueAction,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: l10n.notNow,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
