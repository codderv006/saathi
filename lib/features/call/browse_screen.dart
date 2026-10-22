import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/services/settings_controller.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../guided_workflow/data/guide_catalog.dart';
import '../guided_workflow/domain/workflow_controller.dart';

/// Tap-only way in: app → topic → the guide opens on the main screen. Voice is
/// the main way; this is for when talking isn't possible.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = AppScope.of(context).catalog;
    final language = AppScope.of(context).settings.language;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.browseGuides),
      ),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.xxl + AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            children: [
              for (final cat in catalog.categories.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    cat.value.of(language),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.8,
                  children: [
                    for (final app in catalog.apps.values.where(
                      (a) => a.category == cat.key,
                    ))
                      _AppTile(
                        app: app,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => _TopicsScreen(app: app),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap});
  final AppInfo app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(app.color);
    final onColor = color.computeLuminance() > 0.5
        ? AppColors.textPrimary
        : Colors.white;
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    app.name.substring(0, 1),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: onColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  app.name,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsScreen extends StatelessWidget {
  const _TopicsScreen({required this.app});
  final AppInfo app;

  Future<void> _open(BuildContext context, TopicInfo topic) async {
    final services = AppScope.of(context);
    var newUser = false;
    if (topic.id == 'book_ride') {
      final answer = await showModalBottomSheet<bool>(
        context: context,
        builder: (_) => _NewUserSheet(app: app),
      );
      if (answer == null) return;
      newUser = answer;
    }
    final def = services.catalog.definitionFor(
      app.id,
      topic.id,
      newUser: newUser,
    );
    if (def == null || !context.mounted) return;
    final outcome = await services.guide.startNew(
      definition: def,
      sessionId: SettingsController.randomId(),
      installationId: services.settings.installationId,
      language: services.settings.language,
      userId: services.userId,
    );
    if (!context.mounted) return;
    if (outcome is SaveFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
      );
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final language = services.settings.language;
    final l10n = AppLocalizations.of(context);
    final topics = services.catalog.topicsFor(app.id);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidesFor(app.name))),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingCompact),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) {
          final t = topics[i];
          return Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minVerticalPadding: AppSpacing.sm,
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(app.color),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                t.title.of(language),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _open(context, t),
            ),
          );
        },
      ),
    );
  }
}

class _NewUserSheet extends StatelessWidget {
  const _NewUserSheet({required this.app});
  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.alreadyUsing(app.name),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.yesShort,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: l10n.noNewUser,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
