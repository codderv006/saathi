import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/config.dart';
import '../../core/services/settings_controller.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/saathi_logo.dart';
import '../../core/widgets/status_message.dart';
import '../../l10n/app_localizations.dart';
import '../guided_workflow/data/ride_workflow.dart';
import '../guided_workflow/data/workflow_registry.dart';
import '../guided_workflow/domain/workflow.dart';
import '../guided_workflow/domain/workflow_controller.dart';
import '../guided_workflow/presentation/screenshot_guide.dart';
import '../settings/settings_screen.dart';
import '../voice_session/domain/voice_session_service.dart';
import '../voice_session/presentation/voice_orb.dart';
import '../voice_session/presentation/voice_status_text.dart';
import 'guide_events_client.dart';
import 'guide_tool_handler.dart';

/// The whole app in one screen: the call starts on open, and the steps of the
/// chosen guide show underneath it.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RideApp? _pickedApp;
  bool _busy = false;

  /// A guide restored from a previous run is only shown after the user chooses
  /// to continue it.
  bool? _resumeChoiceNeeded;
  Outcome? _justFinished;

  /// "New ride" pressed: show the app list even though an old guide is open.
  bool _forcePicker = false;
  bool _guideWasOpen = false;
  WorkflowController? _guide;
  GuideEventsClient? _agentEvents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeChoiceNeeded == null) {
      final services = AppScope.of(context);
      final session = services.guide.session;
      _resumeChoiceNeeded = session != null && session.isOpen;
      _guideWasOpen = session?.isOpen ?? false;
      _guide = services.guide..addListener(_onGuideChanged);
      // The agent moves the guide by voice; the screen follows without taps.
      if (PocConfig.missing.isEmpty) {
        final handler = GuideToolHandler(
          guide: services.guide,
          settings: services.settings,
          userId: () => services.userId,
        );
        _agentEvents = GuideEventsClient(
          baseUrl: PocConfig.serverBase,
          token: PocConfig.devSessionToken,
          deviceId: services.settings.installationId,
          onEvent: handler.handle,
        )..start();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _call());
    }
  }

  @override
  void dispose() {
    _guide?.removeListener(_onGuideChanged);
    _agentEvents?.stop();
    super.dispose();
  }

  /// Keeps the screen in step with the guide, whoever changed it (tap or voice).
  void _onGuideChanged() {
    final session = _guide?.session;
    final open = session?.isOpen ?? false;
    setState(() {
      if (open) {
        _pickedApp = null;
        _resumeChoiceNeeded = false;
        _justFinished = null;
        _forcePicker = false;
      } else if (_guideWasOpen && session != null) {
        _justFinished = session.outcome;
      }
    });
    _guideWasOpen = open;
  }

  // ------------------------------------------------------------------ call

  Map<String, String> _callContext() {
    final services = AppScope.of(context);
    final device = {'saathi_device': services.settings.installationId};
    final guide = services.guide;
    final session = guide.session;
    final step = guide.currentStep;
    final def = guide.definition;
    if (_resumeChoiceNeeded == true ||
        session == null ||
        !session.isOpen ||
        step == null ||
        def == null) {
      return device;
    }
    final language = services.settings.language;
    final l10n = AppLocalizations.of(context);
    return {
      ...device,
      'saathi_task': def.title.of(language),
      'saathi_step':
          '${l10n.stepOf(def.indexOf(step.id) + 1, def.steps.length)}: '
          '${step.title.of(language)}',
      'saathi_instruction': step.instruction.of(language),
    };
  }

  Future<void> _call() async {
    final services = AppScope.of(context);
    if (services.voice.status.isBusy) return;
    await services.voice.start(
      language: services.settings.language,
      context: _callContext(),
    );
  }

  // ------------------------------------------------------------------ guide

  Future<void> _startGuide(RideApp app, {required bool fromInstall}) async {
    final services = AppScope.of(context);
    setState(() => _busy = true);
    final outcome = await services.guide.startNew(
      definition: WorkflowRegistry.find(
        app.workflowId(fromInstall: fromInstall),
      )!,
      sessionId: SettingsController.randomId(),
      installationId: services.settings.installationId,
      language: services.settings.language,
      userId: services.userId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome is SaveFailed) _toast(AppLocalizations.of(context).saveFailed);
  }

  Future<void> _run(WorkflowCommand command) async {
    if (_busy) return; // no double taps
    setState(() => _busy = true);
    final outcome = await AppScope.of(context).guide.apply(command);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case Applied():
        break; // the guide listener updates the screen
      case SaveFailed():
        _toast(l10n.saveFailed);
      case Refused() || InvalidRequest():
        _toast(l10n.actionNotPossible);
      case NeedsUserConfirmation():
        break;
    }
  }

  void _newRide() => setState(() {
    _justFinished = null;
    _pickedApp = null;
    _resumeChoiceNeeded = false;
    _forcePicker = true;
  });

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onSettings: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
            _CallBar(onCall: _call),
            const Divider(height: 1),
            Expanded(
              child: ListenableBuilder(
                listenable: services.guide,
                builder: (context, _) {
                  final guide = services.guide;
                  final session = guide.session;
                  final Widget content;
                  if (_justFinished != null) {
                    content = _Finished(
                      outcome: _justFinished!,
                      appName:
                          RideApp.fromWorkflowId(
                            session?.workflowId ?? '',
                          )?.displayName ??
                          '',
                      onNewRide: _newRide,
                    );
                  } else if (!_forcePicker &&
                      session != null &&
                      session.isOpen &&
                      _resumeChoiceNeeded == true) {
                    content = _ResumeChoice(
                      onContinue: () async {
                        if (session.status == SessionStatus.paused) {
                          await guide.apply(const Resume());
                        }
                        setState(() => _resumeChoiceNeeded = false);
                      },
                      onNew: _newRide,
                    );
                  } else if (!_forcePicker &&
                      session != null &&
                      session.isOpen &&
                      _pickedApp == null) {
                    content = _StepView(
                      busy: _busy,
                      onDone: (step) => _run(ConfirmStep(step.id)),
                      onBack: (step) => _run(GoBack(step.id)),
                      onOutcome: (step, o) => _run(ReportOutcome(step.id, o)),
                      onNew: _newRide,
                    );
                  } else if (_pickedApp != null) {
                    content = _SetupQuestion(
                      app: _pickedApp!,
                      busy: _busy,
                      onAnswer: (fromInstall) =>
                          _startGuide(_pickedApp!, fromInstall: fromInstall),
                      onBack: () => setState(() => _pickedApp = null),
                    );
                  } else {
                    content = _AppPicker(
                      title: l10n.taskBookCab,
                      onPick: (app) => setState(() => _pickedApp = app),
                    );
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${content.runtimeType}-${session?.currentStepId}',
                      ),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pagePaddingCompact,
      AppSpacing.xs,
      AppSpacing.xs,
      0,
    ),
    child: Row(
      children: [
        const Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SaathiLogo(size: 24),
            ),
          ),
        ),
        const Flexible(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: LanguageToggle(compact: true),
            ),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: onSettings,
        ),
      ],
    ),
  );
}

/// Compact, always-visible call status with the one action that matters now.
class _CallBar extends StatelessWidget {
  const _CallBar({required this.onCall});
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final voice = services.voice;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final status = voice.status;
        final text = VoiceStatusText.of(l10n, status);
        final failed = status.phase == VoicePhase.failed;
        final micDenied = status.failure == VoiceFailure.microphoneDenied;

        final Widget action;
        if (status.isLive) {
          action = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: voice.muted ? l10n.unmute : l10n.mute,
                onPressed: status.phase == VoicePhase.connecting
                    ? null
                    : () => voice.setMuted(!voice.muted),
                icon: Icon(
                  voice.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                ),
              ),
              IconButton.filled(
                tooltip: l10n.endCall,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.roseStrong,
                  foregroundColor: AppColors.onPrimaryAction,
                ),
                onPressed: voice.end,
                icon: const Icon(Icons.call_end_rounded),
              ),
            ],
          );
        } else if (status.phase == VoicePhase.requestingPermission) {
          action = const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (micDenied) {
          action = FilledButton(
            onPressed: services.android.openAppSettings,
            child: Text(l10n.allowMic),
          );
        } else if (failed && status.failure == VoiceFailure.notConfigured) {
          action = const SizedBox.shrink();
        } else {
          action = FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded, size: 20),
            label: Text(
              status.phase == VoicePhase.idle
                  ? l10n.callSaathi
                  : l10n.callAgain,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePaddingCompact,
            AppSpacing.xxs,
            AppSpacing.pagePaddingCompact,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              VoiceOrb(status: status, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.title, style: theme.textTheme.titleMedium),
                      // Only failures need an explanation; normal states speak
                      // for themselves.
                      if (failed)
                        Text(
                          text.hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: action),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppPicker extends StatelessWidget {
  const _AppPicker({required this.title, required this.onPick});
  final String title;
  final ValueChanged<RideApp> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        for (final app in RideApp.values) ...[
          _BigChoice(
            icon: Icons.local_taxi_outlined,
            label: app.displayName,
            onTap: () => onPick(app),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SetupQuestion extends StatelessWidget {
  const _SetupQuestion({
    required this.app,
    required this.busy,
    required this.onAnswer,
    required this.onBack,
  });

  final RideApp app;
  final bool busy;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: Text(l10n.back),
          ),
        ),
        Text(
          l10n.alreadyUsing(app.displayName),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.yesShort,
          busy: busy,
          onPressed: () => onAnswer(false),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: l10n.noNewUser,
          onPressed: busy ? null : () => onAnswer(true),
        ),
      ],
    );
  }
}

class _ResumeChoice extends StatelessWidget {
  const _ResumeChoice({required this.onContinue, required this.onNew});
  final VoidCallback onContinue;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final guide = services.guide;
    final def = guide.definition!;
    final step = guide.currentStep!;
    final app = RideApp.fromWorkflowId(def.id)?.displayName ?? '';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text(l10n.resumeTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$app · ${l10n.stepOf(def.indexOf(step.id) + 1, def.steps.length)}'
          ' · ${step.title.of(services.settings.language)}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: l10n.continueGuide, onPressed: onContinue),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(label: l10n.resumeNew, onPressed: onNew),
      ],
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.busy,
    required this.onDone,
    required this.onBack,
    required this.onOutcome,
    required this.onNew,
  });

  final bool busy;
  final ValueChanged<WorkflowStep> onDone;
  final ValueChanged<WorkflowStep> onBack;
  final void Function(WorkflowStep, Outcome) onOutcome;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = services.settings.language;
    final guide = services.guide;
    final def = guide.definition!;
    final step = guide.currentStep!;
    final index = def.indexOf(step.id);
    final app = RideApp.fromWorkflowId(def.id)?.displayName ?? '';

    final layout = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.xs,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$app · ${l10n.stepOf(index + 1, def.steps.length)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(onPressed: onNew, child: Text(l10n.newRide)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (index + 1) / def.steps.length,
              minHeight: 5,
            ),
          ),
        ),
        // Text on top (scrolls only with very large fonts), screenshot fills the
        // rest: everything is visible at once, no scrolling needed.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.3,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    step.title.of(language),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  step.instruction.of(language),
                  style: theme.textTheme.bodyLarge!.copyWith(fontSize: 16),
                ),
                if (step.sensitivity == Sensitivity.secretCode) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InlineNotice(
                    icon: Icons.lock_outline_rounded,
                    text: l10n.secretCodeNote,
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: step.screenshot == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.sm,
                    AppSpacing.pagePadding,
                    AppSpacing.sm,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => ScreenshotGuide(
                      screenshot: step.screenshot!,
                      language: language,
                      maxHeight: constraints.maxHeight,
                    ),
                  ),
                ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: step.kind == StepKind.outcome
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PrimaryButton(
                        label: l10n.outcomeBooked,
                        icon: Icons.check_rounded,
                        busy: busy,
                        onPressed: () => onOutcome(step, Outcome.succeeded),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SecondaryButton(
                        label: l10n.outcomeNotBooked,
                        onPressed: busy
                            ? null
                            : () => onOutcome(step, Outcome.notCompleted),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (index > 0) ...[
                        SizedBox(
                          width: 64,
                          child: OutlinedButton(
                            onPressed: busy ? null : () => onBack(step),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              semanticLabel: l10n.back,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.done,
                          icon: Icons.check_rounded,
                          busy: busy,
                          onPressed: () => onDone(step),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
    // Everything fits without scrolling on normal phones. Only very large text
    // on a small screen falls back to scrolling, instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxHeight >= 480
          ? layout
          : SingleChildScrollView(child: SizedBox(height: 760, child: layout)),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({
    required this.outcome,
    required this.appName,
    required this.onNewRide,
  });

  final Outcome outcome;
  final String appName;
  final VoidCallback onNewRide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final success = outcome == Outcome.succeeded;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Icon(
          success ? Icons.check_circle_rounded : Icons.self_improvement_rounded,
          size: 56,
          color: success ? AppColors.mintStrong : AppColors.lavenderStrong,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          success ? l10n.completedTitle : l10n.notCompletedTitle,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          success ? l10n.completedBody(appName) : l10n.notCompletedBody,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: l10n.newRide, onPressed: onNewRide),
      ],
    );
  }
}

class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceMuted,
    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}
