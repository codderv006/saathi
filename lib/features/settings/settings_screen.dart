import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/config.dart';
import '../../core/widgets/language_toggle.dart';
import '../../l10n/app_localizations.dart';
import '../diagnostics/voice_diagnostics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            section(l10n.settingsLanguage, const LanguageToggle()),
            section(
              l10n.settingsPrivacy,
              Text(l10n.settingsPrivacyBody, style: theme.textTheme.bodyLarge),
            ),
            section(
              l10n.settingsVersion,
              Text(PocConfig.appVersion, style: theme.textTheme.bodyLarge),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.developer_mode_outlined),
              title: Text(
                l10n.settingsDiagnostics,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const VoiceDiagnosticsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
