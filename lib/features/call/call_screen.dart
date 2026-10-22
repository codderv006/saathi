import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/config.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/saathi_logo.dart';
import '../../core/widgets/status_message.dart';
import '../../l10n/app_localizations.dart';
import '../guided_workflow/data/guide_catalog.dart';
import '../guided_workflow/domain/workflow.dart';
import '../guided_workflow/domain/workflow_controller.dart';
import '../settings/settings_screen.dart';
import '../voice_session/domain/voice_session_service.dart';
import '../voice_session/presentation/hero_orb.dart';
import '../voice_session/presentation/voice_status_text.dart';
import 'browse_screen.dart';
import 'guide_events_client.dart';
import 'guide_tool_handler.dart';
import 'guide_visual.dart';

/// The whole app in one screen. Tap the orb to talk; while the call runs, the
/// guide the agent opens appears here and follows the conversation by itself.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _busy = false;
  bool? _resumeChoiceNeeded;
  Outcome? _justFinished;
  bool _finishedWasRide = false;
  String _finishedApp = '';
  bool _guideWasOpen = false;
  WorkflowController? _guide;
  GuideEventsClient? _agentEvents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeChoiceNeeded != null) return;
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
        catalog: services.catalog,
        userId: () => services.userId,
      );
      _agentEvents = GuideEventsClient(
        baseUrl: PocConfig.serverBase,
        token: PocConfig.devSessionToken,
        deviceId: services.settings.installationId,
        onEvent: handler.handle,
      )..start();
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
        _resumeChoiceNeeded = false;
        _justFinished = null;
      } else if (_guideWasOpen && session != null) {
        _justFinished = session.outcome;
        _finishedWasRide = _guide?.definition?.topic == 'book_ride';
        final appId = _guide?.definition?.app;
        _finishedApp = appId == null
            ? ''
            : AppScope.of(context).catalog.apps[appId]?.name ?? '';
      }
    });
    _guideWasOpen = open;
  }

  // ------------------------------------------------------------------ call

  Map<String, String> _callContext() {
    final services = AppScope.of(context);
    final device = {
      'saathi_device': services.settings.installationId,
      // Spoken first, so the call opens in the language selected on screen.
      'saathi_welcome': AppLocalizations.of(context).agentGreeting,
    };
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

  Future<void> _run(WorkflowCommand command) async {
    if (_busy) return; // no double taps
    setState(() => _busy = true);
    final outcome = await AppScope.of(context).guide.apply(command);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case SaveFailed():
        _toast(l10n.saveFailed);
      case Refused() || InvalidRequest():
        _toast(l10n.actionNotPossible);
      default:
        break; // the guide listener updates the screen
    }
  }

  Future<void> _backToHero() async {
    final guide = AppScope.of(context).guide;
    if (guide.session?.isOpen ?? false) await guide.clear();
    setState(() {
      _justFinished = null;
      _resumeChoiceNeeded = false;
    });
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _openBrowse() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const BrowseScreen()),
  );

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onSettings: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    services.guide,
                    services.voice,
                  ]),
                  builder: (context, _) {
                    final session = services.guide.session;
                    final open = session != null && session.isOpen;
                    final Widget content;
                    final String key;
                    if (_justFinished != null) {
                      key = 'done';
                      content = _FinishedView(
                        outcome: _justFinished!,
                        wasRide: _finishedWasRide,
                        appName: _finishedApp,
                        onNext: _backToHero,
                      );
                    } else if (open && _resumeChoiceNeeded == true) {
                      key = 'resume';
                      content = _ResumeChoice(
                        onContinue: () async {
                          if (session.status == SessionStatus.paused) {
                            await services.guide.apply(const Resume());
                          }
                          setState(() => _resumeChoiceNeeded = false);
                        },
                        onNew: _backToHero,
                      );
                    } else if (open) {
                      key = 'guide-${session.workflowId}';
                      content = _GuideView(
                        busy: _busy,
                        onCall: _call,
                        onDone: (s) => _run(ConfirmStep(s.id)),
                        onBack: (s) => _run(GoBack(s.id)),
                        onOutcome: (s, o) => _run(ReportOutcome(s.id, o)),
                        onClose: _backToHero,
                      );
                    } else {
                      key = 'hero';
                      content = _HeroView(onCall: _call, onBrowse: _openBrowse);
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(a),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(key: ValueKey(key), child: content),
                    );
                  },
                ),
              ),
            ],
          ),
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

// ==================================================================== hero

class _HeroView extends StatelessWidget {
  const _HeroView({required this.onCall, required this.onBrowse});
  final VoidCallback onCall;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final voice = services.voice;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = voice.status;
    final live = status.isBusy;
    final failed = status.phase == VoicePhase.failed;
    final text = VoiceStatusText.of(l10n, status);

    return LayoutBuilder(
      builder: (context, c) {
        final orb = math.min(c.maxWidth * 0.72, c.maxHeight * 0.42);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    children: [
                      HeroOrb(
                        status: status,
                        size: orb,
                        onTap: live ? null : onCall,
                        semanticLabel: '${l10n.heroTapEn}. ${l10n.heroTapMr}',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        liveRegion: true,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: live || failed
                              ? Column(
                                  key: ValueKey(status),
                                  children: [
                                    Text(
                                      text.title,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      failed ? text.hint : l10n.askAnything,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge!
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                )
                              // The one-line invitation, always in both languages.
                              : Column(
                                  key: const ValueKey('invite'),
                                  children: [
                                    Text(
                                      l10n.heroTapEn,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      l10n.heroTapMr,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleLarge!
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      bottom: AppSpacing.md,
                    ),
                    child: live
                        ? _CallControls(voice: voice)
                        : failed &&
                              status.failure == VoiceFailure.microphoneDenied
                        ? PrimaryButton(
                            label: l10n.allowMic,
                            onPressed: services.android.openAppSettings,
                          )
                        : TextButton.icon(
                            onPressed: onBrowse,
                            icon: const Icon(Icons.grid_view_rounded, size: 20),
                            label: Text(l10n.browseGuides),
                          ),
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

class _CallControls extends StatelessWidget {
  const _CallControls({required this.voice});
  final VoiceSessionService voice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connecting = voice.status.phase == VoicePhase.connecting;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: voice.muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
          label: voice.muted ? l10n.unmute : l10n.mute,
          onTap: connecting ? null : () => voice.setMuted(!voice.muted),
        ),
        const SizedBox(width: AppSpacing.xl),
        _RoundButton(
          icon: Icons.call_end_rounded,
          label: l10n.endCall,
          background: AppColors.roseStrong,
          foreground: Colors.white,
          onTap: voice.end,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = Colors.white,
    this.foreground = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  static const size = 64.0;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: foreground, size: size * 0.42),
          ),
        ),
      ),
    ),
  );
}

// ==================================================================== guide

class _GuideView extends StatelessWidget {
  const _GuideView({
    required this.busy,
    required this.onCall,
    required this.onDone,
    required this.onBack,
    required this.onOutcome,
    required this.onClose,
  });

  final bool busy;
  final VoidCallback onCall;
  final ValueChanged<WorkflowStep> onDone;
  final ValueChanged<WorkflowStep> onBack;
  final void Function(WorkflowStep, Outcome) onOutcome;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = services.settings.language;
    final def = services.guide.definition!;
    final step = services.guide.currentStep!;
    final index = def.indexOf(step.id);
    final app = def.app == null ? null : services.catalog.apps[def.app];

    final layout = Column(
      children: [
        _CallPill(onCall: onCall),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.xs,
            AppSpacing.xs,
            0,
          ),
          child: Row(
            children: [
              if (app != null)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Color(app.color),
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  def.title.of(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: l10n.exitGuide,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingCompact,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween(begin: 0.98, end: 1.0).animate(a),
                  child: child,
                ),
              ),
              child: _StepCard(
                key: ValueKey(step.id),
                step: step,
                app: app,
                language: language,
              ),
            ),
          ),
        ),
        _StepFooter(
          index: index,
          total: def.steps.length,
          step: step,
          busy: busy,
          onDone: onDone,
          onBack: onBack,
          onOutcome: onOutcome,
        ),
      ],
    );
    // Very large text on a small screen scrolls instead of overflowing.
    return LayoutBuilder(
      builder: (context, c) => c.maxHeight >= 480
          ? layout
          : SingleChildScrollView(child: SizedBox(height: 780, child: layout)),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.step,
    required this.app,
    required this.language,
  });

  final WorkflowStep step;
  final AppInfo? app;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5B4BC4),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: LayoutBuilder(
                builder: (context, c) => GuideVisual(
                  step: step,
                  app: app,
                  language: language,
                  maxHeight: c.maxHeight,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.26,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
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
        ],
      ),
    );
  }
}

class _StepFooter extends StatelessWidget {
  const _StepFooter({
    required this.index,
    required this.total,
    required this.step,
    required this.busy,
    required this.onDone,
    required this.onBack,
    required this.onOutcome,
  });

  final int index;
  final int total;
  final WorkflowStep step;
  final bool busy;
  final ValueChanged<WorkflowStep> onDone;
  final ValueChanged<WorkflowStep> onBack;
  final void Function(WorkflowStep, Outcome) onOutcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l10n.stepOf(index + 1, total),
            child: ExcludeSemantics(
              child: _StepDots(index: index, total: total),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (step.kind == StepKind.outcome) ...[
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
          ] else
            Row(
              children: [
                if (index > 0) ...[
                  SizedBox(
                    width: 64,
                    child: OutlinedButton(
                      onPressed: busy ? null : () => onBack(step),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
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
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < total; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == index ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i <= index
                ? AppColors.lavenderStrong
                : AppColors.disabledSurface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    ],
  );
}

/// Compact call status above the guide: live orb + state + mute/end, or a
/// "Tap to talk" pill when no call is running.
class _CallPill extends StatelessWidget {
  const _CallPill({required this.onCall});
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final voice = services.voice;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = voice.status;
    final live = status.isBusy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingCompact,
        AppSpacing.xs,
        AppSpacing.pagePaddingCompact,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            HeroOrb(status: status, size: 44, onTap: live ? null : onCall),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  live
                      ? VoiceStatusText.of(l10n, status).title
                      : status.phase == VoicePhase.failed
                      ? VoiceStatusText.of(l10n, status).hint
                      : l10n.tapToTalk,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            if (live) ...[
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
                  foregroundColor: Colors.white,
                ),
                onPressed: voice.end,
                icon: const Icon(Icons.call_end_rounded),
              ),
            ] else if (status.failure == VoiceFailure.microphoneDenied)
              TextButton(
                onPressed: services.android.openAppSettings,
                child: Text(l10n.allowMic),
              )
            else
              IconButton.filled(
                tooltip: l10n.tapToTalk,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lavenderStrong,
                  foregroundColor: Colors.white,
                ),
                onPressed: onCall,
                icon: const Icon(Icons.mic_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== other states

class _ResumeChoice extends StatelessWidget {
  const _ResumeChoice({required this.onContinue, required this.onNew});
  final VoidCallback onContinue;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final def = services.guide.definition!;
    final step = services.guide.currentStep!;
    final language = services.settings.language;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.resumeTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${def.title.of(language)} · '
          '${l10n.stepOf(def.indexOf(step.id) + 1, def.steps.length)}',
          style: theme.textTheme.bodyLarge,
        ),
        Text(step.title.of(language), style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: l10n.continueGuide, onPressed: onContinue),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(label: l10n.resumeNew, onPressed: onNew),
      ],
    );
  }
}

class _FinishedView extends StatefulWidget {
  const _FinishedView({
    required this.outcome,
    required this.wasRide,
    required this.appName,
    required this.onNext,
  });

  final Outcome? outcome;
  final bool wasRide;
  final String appName;
  final VoidCallback onNext;

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Return to the mic by itself, so the conversation can just carry on.
    _timer = Timer(const Duration(seconds: 8), widget.onNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final success = widget.outcome != Outcome.notCompleted;
    final title = !widget.wasRide
        ? l10n.allDone
        : success
        ? l10n.completedTitle
        : l10n.notCompletedTitle;
    final body = !widget.wasRide
        ? l10n.topicDoneBody
        : success
        ? l10n.completedBody(widget.appName)
        : l10n.notCompletedBody;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? AppColors.mint : AppColors.softBlue,
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.self_improvement_rounded,
                size: 48,
                color: success
                    ? AppColors.mintStrong
                    : AppColors.lavenderStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.askSomethingElse,
              onPressed: widget.onNext,
            ),
          ],
        ),
      ),
    );
  }
}
