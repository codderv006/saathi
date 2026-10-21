import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/config.dart';
import '../../core/services/debug_log.dart';
import '../guided_workflow/data/synced_workflow_store.dart';
import '../voice_session/data/bolna_webview_voice_service.dart';

/// Developer screen carried over from the device-verified PoC: raw log, language,
/// opt-in mic foreground service, Android audio state. Uses the app's single voice
/// service (one WebView), so results reflect the real app path.
class VoiceDiagnosticsScreen extends StatefulWidget {
  const VoiceDiagnosticsScreen({super.key});

  @override
  State<VoiceDiagnosticsScreen> createState() => _VoiceDiagnosticsScreenState();
}

class _VoiceDiagnosticsScreenState extends State<VoiceDiagnosticsScreen>
    with WidgetsBindingObserver {
  StreamSubscription<Object?>? _androidSub;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final android = AppScope.of(context).android;
      _androidSub = android.events.listen((e) => log('android', '$e'));
      log('diag', 'device ${await android.deviceInfo()}');
      log(
        'diag',
        'sessionUrl=${PocConfig.sessionUrl} missing=${PocConfig.missing}',
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log(
      'lifecycle',
      '${state.name} voice=${AppScope.of(context).voice.status}',
    );
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _logAudio();
    }
  }

  /// Reads the session back from Firestore (through the real security rules) and
  /// compares it with the phone copy.
  Future<void> _checkCloud() async {
    final services = AppScope.of(context);
    final store = services.guide.store;
    final remote = store is SyncedWorkflowStore ? store.remote : null;
    if (store is! SyncedWorkflowStore || remote == null) {
      log(
        'cloud',
        'cloud sync is off (Firebase not configured or unavailable)',
      );
      return;
    }
    log('cloud', 'uid=${services.userId} lastSyncError=${store.lastSyncError}');
    final phone = await store.local.loadActive();
    try {
      final cloud = await remote.loadActive();
      log('cloud', 'phone: ${phone ?? 'none'}');
      log('cloud', 'cloud: ${cloud ?? 'none'}');
      log(
        'cloud',
        cloud?.id == phone?.id && cloud?.revision == phone?.revision
            ? 'IN SYNC'
            : 'DIFFERENT (sync pending or failed)',
      );
    } catch (e) {
      log('cloud', 'cloud read failed: $e');
    }
  }

  Future<void> _logAudio() async =>
      log('audio', '${await AppScope.of(context).android.audioSnapshot()}');

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _androidSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = AppScope.of(context).voice;
    final bolna = voice is BolnaVoiceService ? voice : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Voice diagnostics')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: voice,
          builder: (context, _) {
            final status = voice.status;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Status: $status',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: _language,
                        onChanged: status.isBusy
                            ? null
                            : (v) => setState(() => _language = v!),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                        ],
                      ),
                      if (bolna != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: bolna.useForegroundService,
                              onChanged: status.isBusy
                                  ? null
                                  : (v) => setState(
                                      () => bolna.useForegroundService = v!,
                                    ),
                            ),
                            const Text('mic foreground service'),
                          ],
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: status.isBusy
                              ? null
                              : () => voice.start(language: _language),
                          child: const Text('Start'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: status.isBusy ? voice.end : null,
                          child: const Text('End'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Log audio state',
                        onPressed: _logAudio,
                        icon: const Icon(Icons.mic_external_on),
                      ),
                      IconButton(
                        tooltip: 'Check cloud copy',
                        onPressed: _checkCloud,
                        icon: const Icon(Icons.cloud_sync_outlined),
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                  Expanded(
                    child: ValueListenableBuilder<List<String>>(
                      valueListenable: log.lines,
                      builder: (_, lines, _) => ListView.builder(
                        reverse: true,
                        itemCount: lines.length,
                        itemBuilder: (_, i) => Text(
                          lines[lines.length - 1 - i],
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
