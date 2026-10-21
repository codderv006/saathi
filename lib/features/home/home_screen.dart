import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/services/settings_controller.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/saathi_logo.dart';
import '../../core/widgets/status_message.dart';
import '../../l10n/app_localizations.dart';
import '../guided_workflow/data/ride_workflow.dart';
import '../guided_workflow/data/workflow_registry.dart';
import '../guided_workflow/domain/workflow_controller.dart';
import '../guided_workflow/presentation/workflow_screen.dart';
import '../settings/settings_screen.dart';
import '../voice_session/domain/voice_session_service.dart';
import '../voice_session/presentation/voice_actions.dart';
import '../voice_session/presentation/voice_orb.dart';
import '../voice_session/presentation/voice_status_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _starting = false;

  Future<void> _openGuide() async {
    final services = AppScope.of(context);
    final guide = services.guide;
    var fresh = !(guide.session?.isOpen ?? false);
    if (!fresh) {
      // Never resume silently: let the user choose.
      final resume = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _ResumeChoiceSheet(),
      );
      if (resume == null || !mounted) return;
      fresh = !resume;
    }
    if (fresh) {
      final app = await showModalBottomSheet<RideApp>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _AppPickerSheet(),
      );
      if (app == null || !mounted) return;
      final fromInstall = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _SetupChoiceSheet(app: app),
      );
      if (fromInstall == null || !mounted) return;
      setState(() => _starting = true);
      final outcome = await guide.startNew(
        definition: WorkflowRegistry.find(
          app.workflowId(fromInstall: fromInstall),
        )!,
        sessionId: SettingsController.randomId(),
        installationId: services.settings.installationId,
        language: services.settings.language,
        userId: services.userId,
      );
      if (!mounted) return;
      setState(() => _starting = false);
      if (outcome is SaveFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: WorkflowScreen.routeName),
        builder: (_) => const WorkflowScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePaddingCompact,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    // Logo yields space first on narrow screens / large fonts.
                    const Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SaathiLogo(size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
                      tooltip: l10n.settings,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.homeHeading,
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.homeSubheading,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _RestoreNotice(),
                  const _VoiceCard(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.guidesHeading, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      services.guide,
                      services.settings,
                    ]),
                    builder: (context, _) =>
                        _TaskTile(busy: _starting, onOpen: _openGuide),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains, once, if saved progress couldn't be restored at launch.
class _RestoreNotice extends StatefulWidget {
  const _RestoreNotice();

  @override
  State<_RestoreNotice> createState() => _RestoreNoticeState();
}

class _RestoreNoticeState extends State<_RestoreNotice> {
  RestoreResult? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _shown ??= services.startupRestore;
    services.startupRestore = RestoreResult.none;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (_shown) {
      RestoreResult.incompatible => l10n.restoreIncompatible,
      RestoreResult.failed => l10n.restoreFailed,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: InlineNotice(icon: Icons.info_outline_rounded, text: message),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard();

  @override
  Widget build(BuildContext context) {
    final voice = AppScope.of(context).voice;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final status = voice.status;
        final live = status.isBusy;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VoiceOrb(
                    // Past calls are explained on the voice screen; Home stays calm.
                    status: live ? status : const VoiceStatus(VoicePhase.idle),
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.talkToSaathi,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (live)
                          Text(
                            VoiceStatusText.of(l10n, status).title,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.voiceCardBody,
                style: theme.textTheme.bodyLarge!.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: live ? l10n.openCall : l10n.startTalking,
                icon: live ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                onPressed: () => startVoiceSession(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.busy, required this.onOpen});

  final bool busy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final guide = services.guide;
    final session = guide.session;
    final definition = guide.definition;
    final inProgress = session != null && session.isOpen && definition != null;
    final app = inProgress ? RideApp.fromWorkflowId(session.workflowId) : null;
    final stepIndex = inProgress
        ? definition.indexOf(session.currentStepId)
        : -1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy ? null : onOpen,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.paleYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_taxi_outlined, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.taskBookCab,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            inProgress && app != null
                                ? '${l10n.inProgressApp(app.displayName)} · '
                                      '${l10n.stepOf(stepIndex + 1, definition.steps.length)}'
                                : l10n.taskBookCabDetail,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which ride app the user already uses. Brand names are shown as-is.
class _AppPickerSheet extends StatelessWidget {
  const _AppPickerSheet();

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
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chooseAppTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.chooseAppBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            for (final app in RideApp.values) ...[
              Material(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pop(context, app),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.buttonHeight + 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_taxi_outlined),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              app.displayName,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fresh install / sign-up path, or straight to booking for people already signed in.
class _SetupChoiceSheet extends StatelessWidget {
  const _SetupChoiceSheet({required this.app});

  final RideApp app;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget option(
      bool fromInstall,
      IconData icon,
      String title,
      String detail,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context, fromInstall),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(detail, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );

    return SafeArea(
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
              l10n.setupQuestion(app.displayName),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            option(
              false,
              Icons.check_circle_outline_rounded,
              l10n.setupYes,
              l10n.setupYesDetail,
            ),
            option(
              true,
              Icons.download_rounded,
              l10n.setupNo,
              l10n.setupNoDetail,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a guide is already in progress: continue it, or start a new one.
class _ResumeChoiceSheet extends StatelessWidget {
  const _ResumeChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final guide = services.guide;
    final session = guide.session!;
    final definition = guide.definition!;
    final step = guide.currentStep!;
    final language = services.settings.language;
    final app = RideApp.fromWorkflowId(session.workflowId);

    return SafeArea(
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
            Text(l10n.resumeTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${app?.displayName ?? ''} · '
                    '${l10n.stepOf(definition.indexOf(step.id) + 1, definition.steps.length)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    step.title.of(language),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.continueGuide,
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: l10n.resumeNew,
              icon: Icons.add_rounded,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
