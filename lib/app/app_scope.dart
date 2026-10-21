import 'package:flutter/widgets.dart';

import '../core/services/android_bridge.dart';
import '../core/services/settings_controller.dart';
import '../features/guided_workflow/domain/workflow_controller.dart';
import '../features/voice_session/domain/voice_session_service.dart';

/// App-wide services. Constructed in main() (or a test) and handed down the tree.
class AppServices {
  AppServices({
    required this.settings,
    required this.voice,
    required this.guide,
    required this.android,
    this.startupRestore = RestoreResult.none,
  });

  final SettingsController settings;
  final VoiceSessionService voice;

  /// The active guided workflow (one at a time).
  final WorkflowController guide;
  final AndroidBridge android;

  /// How restoring saved progress went at launch, so Home can explain problems once.
  RestoreResult startupRestore;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
