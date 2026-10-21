import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/status_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../voice_session/domain/voice_session_service.dart';
import '../../voice_session/presentation/voice_actions.dart';
import '../../voice_session/presentation/voice_status_text.dart';
import '../data/ride_workflow.dart';
import '../domain/workflow.dart';
import '../domain/workflow_controller.dart';
import '../domain/workflow_engine.dart';
import 'completion_screen.dart';
import 'help_sheets.dart';
import 'screenshot_guide.dart';

/// One instruction at a time: read → (look at the picture) → do it in the app →
/// confirm.
class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  static const routeName = '/guide';

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final _scroll = ScrollController();
  bool _busy = false;
  bool _showSimpler = false;
  int _repeatTick = 0;
  int _pulseTick = 0;
  WorkflowController? _workflow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_workflow == null) {
      _workflow = AppScope.of(context).guide;
      // Coming back to a paused guide resumes it.
      if (_workflow!.session?.status == SessionStatus.paused) {
        _workflow!.apply(const Resume());
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String get _language => AppScope.of(context).settings.language;

  String get _appName =>
      RideApp.fromWorkflowId(
        _workflow!.session?.workflowId ?? '',
      )?.displayName ??
      '';

  Future<void> _run(WorkflowCommand command) async {
    if (_busy) return; // no double submissions
    setState(() => _busy = true);
    final outcome = await _workflow!.apply(command);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case Applied(:final effect):
        switch (effect) {
          case Effect.advanced || Effect.wentBack:
            setState(() => _showSimpler = false);
            _scrollToTop();
            _announceStep();
          case Effect.completed:
            _finish(Outcome.succeeded);
          case Effect.endedWithoutSuccess:
            _finish(Outcome.notCompleted);
          default:
            break;
        }
      case SaveFailed():
        _toast(l10n.saveFailed);
      case Refused() || InvalidRequest():
        _toast(l10n.actionNotPossible);
      case NeedsUserConfirmation():
        break;
    }
  }

  void _finish(Outcome outcome) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CompletionScreen(outcome: outcome, appName: _appName),
      ),
    );
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _announceStep() {
    final step = _workflow!.currentStep;
    if (step == null) return;
    SemanticsService.announce(
      '${step.title.of(_language)}. ${step.instruction.of(_language)}',
      Directionality.of(context),
    );
  }

  void _repeat() {
    _workflow!.apply(const RepeatInstruction());
    setState(() => _repeatTick++);
    _scrollToTop();
    _announceStep();
  }

  void _simpler() {
    _workflow!.apply(const ExplainSimpler());
    setState(() => _showSimpler = true);
  }

  Future<void> _stopForNow() async {
    await _workflow!.apply(const Pause());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.progressSaved)));
  }

  Future<void> _help() async {
    final step = _workflow!.currentStep!;
    _workflow!.apply(const RequestHelp());
    final choice = await showHelpSheet(
      context,
      canGoBack: _workflow!.definition!.previousStepId(step.id) != null,
      hasScreenshot: step.screenshot != null,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case HelpChoice.repeat:
        _repeat();
      case HelpChoice.simpler:
        _simpler();
      case HelpChoice.showAgain:
        setState(() => _pulseTick++);
      case HelpChoice.goBack:
        _run(GoBack(step.id));
      case HelpChoice.talk:
        startVoiceSession(context, fromGuide: true);
      case HelpChoice.stop:
        _stopForNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _workflow!,
      builder: (context, _) {
        final session = _workflow!.session;
        final step = _workflow!.currentStep;
        if (session == null || step == null || !session.isOpen) {
          return Scaffold(
            appBar: AppBar(),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: StatusMessage(
                icon: Icons.info_outline_rounded,
                title: l10n.workflowMissing,
                actions: [
                  PrimaryButton(
                    label: l10n.returnHome,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
        final definition = _workflow!.definition!;
        final index = definition.indexOf(step.id);
        final total = definition.steps.length;

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            // Leaving the guide by system back pauses it so progress is kept.
            if (didPop && _workflow!.session?.status == SessionStatus.active) {
              _workflow!.apply(const Pause());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: l10n.exitGuide,
                icon: const Icon(Icons.close_rounded),
                onPressed: _stopForNow,
              ),
              title: Text(
                definition.title.of(_language),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              actions: const [
                _VoicePill(),
                SizedBox(width: AppSpacing.xs),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  _ProgressHeader(
                    index: index,
                    total: total,
                    onBack: index > 0 && !_busy
                        ? () => _run(GoBack(step.id))
                        : null,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.02),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _StepBody(
                          key: ValueKey('${step.id}#$_repeatTick'),
                          step: step,
                          language: _language,
                          showSimpler: _showSimpler,
                          pulse: _pulseTick,
                          pendingVoiceConfirmation:
                              _workflow!.pendingVoiceConfirmation == step.id,
                          onVoiceConfirm: () => _run(ConfirmStep(step.id)),
                          onVoiceDismiss: _workflow!.dismissVoiceConfirmation,
                        ),
                      ),
                    ),
                  ),
                  _ActionBar(
                    step: step,
                    busy: _busy,
                    onConfirm: () => _run(ConfirmStep(step.id)),
                    onOutcome: (o) => _run(ReportOutcome(step.id, o)),
                    onRepeat: _repeat,
                    onHelp: _help,
                    voiceLive: services.voice.status.isLive,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.index,
    required this.total,
    required this.onBack,
  });

  final int index;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingCompact,
        0,
        AppSpacing.pagePadding,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                Flexible(
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: Text(l10n.back, overflow: TextOverflow.ellipsis),
                  ),
                )
              else
                const SizedBox(height: AppSpacing.minTouchTarget, width: 8),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.stepOf(index + 1, total),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (index + 1) / total),
                duration: const Duration(milliseconds: 300),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  semanticsLabel: l10n.stepOf(index + 1, total),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.step,
    required this.language,
    required this.showSimpler,
    required this.pulse,
    required this.pendingVoiceConfirmation,
    required this.onVoiceConfirm,
    required this.onVoiceDismiss,
  });

  final WorkflowStep step;
  final String language;
  final bool showSimpler;
  final int pulse;
  final bool pendingVoiceConfirmation;
  final VoidCallback onVoiceConfirm;
  final VoidCallback onVoiceDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            step.title.of(language),
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          step.instruction.of(language),
          style: theme.textTheme.bodyLarge!.copyWith(fontSize: 18),
        ),
        if (showSimpler) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.simplerHeading,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  step.simplerInstruction.of(language),
                  style: theme.textTheme.bodyLarge!.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
        if (step.isSensitive) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNotice(
            icon: step.sensitivity == Sensitivity.secretCode
                ? Icons.lock_outline_rounded
                : Icons.shield_outlined,
            text: step.sensitivity == Sensitivity.secretCode
                ? l10n.secretCodeNote
                : l10n.sensitiveNote,
          ),
        ],
        if (pendingVoiceConfirmation) ...[
          const SizedBox(height: AppSpacing.md),
          _VoiceConfirmBanner(onYes: onVoiceConfirm, onNo: onVoiceDismiss),
        ],
        if (step.helpers.contains(StepHelper.copyText)) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => showCopyTextSheet(context),
            icon: const Icon(Icons.content_copy_rounded, size: 20),
            label: Text(l10n.copyHelperButton),
          ),
        ],
        if (step.screenshot != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ScreenshotGuide(
            screenshot: step.screenshot!,
            language: language,
            pulse: pulse,
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
        ],
      ],
    );
  }
}

class _VoiceConfirmBanner extends StatelessWidget {
  const _VoiceConfirmBanner({required this.onYes, required this.onNo});
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceHeardDone,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onYes,
                  child: Text(l10n.yesDone),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton(
                  onPressed: onNo,
                  child: Text(l10n.notYet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.step,
    required this.busy,
    required this.onConfirm,
    required this.onOutcome,
    required this.onRepeat,
    required this.onHelp,
    required this.voiceLive,
  });

  final WorkflowStep step;
  final bool busy;
  final VoidCallback onConfirm;
  final ValueChanged<Outcome> onOutcome;
  final VoidCallback onRepeat;
  final VoidCallback onHelp;
  final bool voiceLive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcomeStep = step.kind == StepKind.outcome;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (outcomeStep) ...[
              PrimaryButton(
                label: l10n.outcomeBooked,
                icon: Icons.check_rounded,
                busy: busy,
                onPressed: () => onOutcome(Outcome.succeeded),
              ),
              const SizedBox(height: AppSpacing.xs),
              SecondaryButton(
                label: l10n.outcomeNotBooked,
                onPressed: busy ? null : () => onOutcome(Outcome.notCompleted),
              ),
            ] else
              PrimaryButton(
                label: l10n.iveDoneThis,
                icon: Icons.check_rounded,
                busy: busy,
                onPressed: onConfirm,
              ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: QuietAction(
                    icon: Icons.replay_rounded,
                    label: l10n.repeatInstructions,
                    onPressed: onRepeat,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: QuietAction(
                    icon: Icons.help_outline_rounded,
                    label: l10n.needHelp,
                    onPressed: onHelp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small voice entry in the guide's top bar; shows live status when a call is on.
class _VoicePill extends StatelessWidget {
  const _VoicePill();

  @override
  Widget build(BuildContext context) {
    final voice = AppScope.of(context).voice;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final status = voice.status;
        final live = status.isLive;
        final text = live
            ? VoiceStatusText.of(l10n, status).title
            : l10n.talkToSaathi;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextButton.icon(
            onPressed: () => startVoiceSession(context, fromGuide: true),
            style: TextButton.styleFrom(
              backgroundColor: live ? AppColors.mint : AppColors.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              textStyle: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),
            ),
            icon: Icon(
              status.phase == VoicePhase.muted
                  ? Icons.mic_off_rounded
                  : live
                  ? Icons.graphic_eq_rounded
                  : Icons.mic_none_rounded,
              size: 18,
            ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(text, overflow: TextOverflow.ellipsis),
            ),
          ),
        );
      },
    );
  }
}
