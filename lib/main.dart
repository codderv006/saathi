import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'core/config.dart';
import 'core/services/android_bridge.dart';
import 'core/services/debug_log.dart';
import 'core/services/settings_controller.dart';
import 'features/guided_workflow/data/firestore_workflow_store.dart';
import 'features/guided_workflow/data/local_workflow_store.dart';
import 'features/guided_workflow/data/synced_workflow_store.dart';
import 'features/guided_workflow/data/workflow_registry.dart';
import 'features/guided_workflow/domain/workflow_controller.dart';
import 'features/voice_session/data/bolna_webview_voice_service.dart';
import 'features/voice_session/data/session_client.dart';

/// Startup only waits for on-phone data. Firebase signs in in the background and
/// attaches cloud sync when ready, so the first screen (and the call) start fast.
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

  final catalog = await WorkflowRegistry.load();
  final store = SyncedWorkflowStore(local: LocalWorkflowStore());
  final guide = WorkflowController(
    store: store,
    findDefinition: WorkflowRegistry.find,
  );
  final restore = await guide.restore();
  log('init', 'restore → ${restore.name} ${guide.session ?? ''}');

  final services = AppServices(
    settings: settings,
    voice: voice,
    guide: guide,
    android: android,
    catalog: catalog,
    startupRestore: restore,
  );
  runApp(SaathiApp(services: services));

  final uid = await _signInAnonymously();
  if (uid != null) {
    store.attachRemote(FirestoreWorkflowStore(FirebaseFirestore.instance, uid));
    services.userId = uid;
    log('init', 'cloud sync attached for uid=$uid');
  }
}

/// Anonymous Firebase identity (Spark plan, free). Returns null if Firebase isn't
/// configured or can't start (e.g. offline on first launch): progress then stays
/// on the phone only for this run.
Future<String?> _signInAnonymously() async {
  if (!PocConfig.firebaseConfigured) {
    log('init', 'Firebase not configured: progress stays on this phone');
    return null;
  }
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: PocConfig.firebaseApiKey,
        appId: PocConfig.firebaseAppId,
        projectId: PocConfig.firebaseProjectId,
        messagingSenderId: PocConfig.firebaseSenderId,
      ),
    );
    final auth = FirebaseAuth.instance;
    final existing = auth.currentUser;
    final user =
        existing ??
        (await auth.signInAnonymously().timeout(
          const Duration(seconds: 8),
        )).user!;
    return user.uid;
  } catch (e) {
    log('init', 'Firebase unavailable, using phone-only progress: $e');
    return null;
  }
}
