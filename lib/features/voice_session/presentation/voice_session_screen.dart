import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../../guided_workflow/presentation/workflow_screen.dart';
import '../domain/voice_session_service.dart';
import 'voice_actions.dart';
import 'voice_orb.dart';
import 'voice_status_text.dart';

class VoiceSessionScreen extends StatelessWidget {
  const VoiceSessionScreen({super.key, this.fromGuide = false});

  static const routeName = '/voice';

  /// Opened from the guide: "Back to your guide" just closes this screen.
  final bool fromGuide;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.talkToSaathi),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _LanguageChip(
              label: services.settings.language == 'mr'
                  ? l10n.languageMarathi
                  : l10n.languageEnglish,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([services.voice, services.guide]),
          builder: (context, _) {
            final status = services.voice.status;
            final text = VoiceStatusText.of(l10n, status);
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        VoiceOrb(status: status),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          liveRegion: true,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              key: ValueKey(status),
                              children: [
                                Text(
                                  text.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  text.hint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge!.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _GuideContext(fromGuide: fromGuide),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.xs,
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                  ),
                  child: _Controls(status: status, fromGuide: fromGuide),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.translate_rounded, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: AppColors.textPrimary),
        ),
      ],
    ),
  );
}

/// What the user is working on, so the call and the guide stay connected.
class _GuideContext extends StatelessWidget {
  const _GuideContext({required this.fromGuide});
  final bool fromGuide;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ola = services.guide;
    final session = ola.session;
    final step = ola.currentStep;
    final language = services.settings.language;

    if (session == null || !session.isOpen || step == null) {
      return Text(
        l10n.voiceNoGuideHint,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge,
      );
    }
    final definition = ola.definition!;
    final index = definition.indexOf(step.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.currentStepLabel} · '
            '${l10n.stepOf(index + 1, definition.steps.length)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(step.title.of(language), style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(step.instruction.of(language), style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: l10n.backToGuide,
            icon: Icons.checklist_rounded,
            onPressed: () {
              if (fromGuide) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: WorkflowScreen.routeName,
                    ),
                    builder: (_) => const WorkflowScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.status, required this.fromGuide});

  final VoiceStatus status;
  final bool fromGuide;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final voice = services.voice;
    final l10n = AppLocalizations.of(context);

    void restart() =>
        startVoiceSession(context, openScreen: false, fromGuide: fromGuide);

    if (status.isLive) {
      final canMute = status.phase != VoicePhase.connecting;
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: voice.muted ? l10n.unmute : l10n.mute,
              icon: voice.muted ? Icons.mic_rounded : Icons.mic_off_rounded,
              onPressed: canMute ? () => voice.setMuted(!voice.muted) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: PrimaryButton(
              label: l10n.endCall,
              icon: Icons.call_end_rounded,
              onPressed: voice.end,
            ),
          ),
        ],
      );
    }

    return switch (status.phase) {
      VoicePhase.requestingPermission => PrimaryButton(
        label: l10n.voiceRequestingPermission,
        busy: true,
        onPressed: null,
      ),
      VoicePhase.failed when status.failure == VoiceFailure.microphoneDenied =>
        Column(
          children: [
            PrimaryButton(
              label: l10n.openSettings,
              icon: Icons.settings_outlined,
              onPressed: services.android.openAppSettings,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(label: l10n.tryAgain, onPressed: restart),
          ],
        ),
      // Nothing to retry until the build is configured; the guide still works.
      VoicePhase.failed when status.failure == VoiceFailure.notConfigured =>
        const SizedBox.shrink(),
      VoicePhase.failed => PrimaryButton(
        label: l10n.tryAgain,
        icon: Icons.refresh_rounded,
        onPressed: restart,
      ),
      VoicePhase.ended || VoicePhase.disconnected => PrimaryButton(
        label: l10n.talkAgain,
        icon: Icons.mic_rounded,
        onPressed: restart,
      ),
      _ => PrimaryButton(
        label: l10n.startTalking,
        icon: Icons.mic_rounded,
        onPressed: restart,
      ),
    };
  }
}
