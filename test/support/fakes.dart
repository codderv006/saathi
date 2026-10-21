import 'package:flutter/widgets.dart';
import 'package:saathi_poc/app/app.dart';
import 'package:saathi_poc/app/app_scope.dart';
import 'package:saathi_poc/core/services/android_bridge.dart';
import 'package:saathi_poc/core/services/settings_controller.dart';
import 'package:saathi_poc/features/guided_workflow/data/workflow_registry.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_controller.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_store.dart';
import 'package:saathi_poc/features/voice_session/domain/voice_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test double. Never used in the app; status is set by the test.
class FakeVoice extends VoiceSessionService {
  VoiceStatus _status = const VoiceStatus(VoicePhase.idle);
  bool _muted = false;
  int starts = 0;
  Map<String, String>? lastContext;

  void emit(VoiceStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  VoiceStatus get status => _status;
  @override
  bool get muted => _muted;

  @override
  Future<void> start({
    required String language,
    Map<String, String> context = const {},
  }) async {
    starts++;
    lastContext = context;
    emit(const VoiceStatus(VoicePhase.listening));
  }

  @override
  Future<void> end() async => emit(const VoiceStatus(VoicePhase.ended));

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    emit(VoiceStatus(muted ? VoicePhase.muted : VoicePhase.listening));
  }

  @override
  Widget buildHost() => const SizedBox.shrink();
}

class FakeAndroid extends AndroidBridge {
  bool micGranted = true;
  int settingsOpened = 0;

  @override
  Future<Map<Object?, Object?>> permissionState() async => {
    'microphone': micGranted,
  };
  @override
  Future<Map<Object?, Object?>> requestPermissions() async => {
    'microphone': micGranted,
  };
  @override
  Future<void> openAppSettings() async => settingsOpened++;
  @override
  Future<void> stopVoiceService() async {}
}

class MemoryStore implements WorkflowStore {
  WorkflowSession? stored;
  bool failNextSave = false;

  @override
  String get name => 'memory';

  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('offline');
    }
    final current = stored?.id == session.id ? stored!.revision : 0;
    if (current != expectedRevision) {
      throw StaleRevisionException(expectedRevision, current);
    }
    stored = session;
  }

  @override
  Future<WorkflowSession?> loadActive() async => stored;

  @override
  Future<void> clear() async => stored = null;
}

class TestApp {
  TestApp._(this.services, this.voice, this.android, this.store);

  final AppServices services;
  final FakeVoice voice;
  final FakeAndroid android;
  final MemoryStore store;

  static Future<TestApp> create({
    bool onboarded = true,
    String language = 'en',
    MemoryStore? store,
  }) async {
    SharedPreferences.setMockInitialValues({
      'saathi.onboardingDone': onboarded,
      'saathi.language': language,
    });
    final settings = await SettingsController.load();
    final voice = FakeVoice();
    final android = FakeAndroid();
    final memory = store ?? MemoryStore();
    final guide = WorkflowController(
      store: memory,
      findDefinition: WorkflowRegistry.find,
    );
    final restore = await guide.restore();
    return TestApp._(
      AppServices(
        settings: settings,
        voice: voice,
        guide: guide,
        android: android,
        startupRestore: restore,
      ),
      voice,
      android,
      memory,
    );
  }

  Widget get widget => SaathiApp(services: services);
}
