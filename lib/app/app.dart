import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/call/call_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_scope.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class SaathiApp extends StatelessWidget {
  const SaathiApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appName,
          theme: AppTheme.light(),
          locale: Locale(settings.language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // One screen: the call starts on open, steps show beneath it.
          home: const CallScreen(),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: AppColors.background,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: AppColors.background,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: Stack(
              children: [
                // The voice call lives here, beneath every screen, so moving
                // between screens never tears it down. It's covered and inert.
                const Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: ExcludeSemantics(
                    child: IgnorePointer(child: _VoiceHost()),
                  ),
                ),
                Positioned.fill(child: child!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceHost extends StatefulWidget {
  const _VoiceHost();

  @override
  State<_VoiceHost> createState() => _VoiceHostState();
}

class _VoiceHostState extends State<_VoiceHost> {
  Widget? _host;

  @override
  Widget build(BuildContext context) =>
      _host ??= AppScope.of(context).voice.buildHost();
}
