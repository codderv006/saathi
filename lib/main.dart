import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'core/config.dart';
import 'core/services/android_bridge.dart';
import 'core/services/debug_log.dart';
import 'core/services/settings_controller.dart';
import 'features/guided_workflow/data/local_workflow_store.dart';
import 'features/guided_workflow/domain/workflow_controller.dart';
import 'features/guided_workflow/data/workflow_registry.dart';
import 'features/voice_session/data/bolna_webview_voice_service.dart';
import 'features/voice_session/data/session_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final android = AndroidBridge();
  final settings = await SettingsController.load();

  final voiceConfigured = PocConfig.missing.isEmpty;
  if (!voiceConfigured) {
    log('init', 'voice NOT configured: missing ${PocConfig.missing}');
  }
  final voice = BolnaVoiceService(
    android: android,
    sessions: voiceConfigured
        ? SessionClient(
            url: PocConfig.sessionUrl,
            token: PocConfig.devSessionToken,
          )
        : null,
  );

  final guide = WorkflowController(
    store: LocalWorkflowStore(),
    findDefinition: WorkflowRegistry.find,
  );
  final restore = await guide.restore();
  log('init', 'restore → ${restore.name} ${guide.session ?? ''}');

  runApp(
    SaathiApp(
      services: AppServices(
        settings: settings,
        voice: voice,
        guide: guide,
        android: android,
        startupRestore: restore,
      ),
    ),
  );
}
