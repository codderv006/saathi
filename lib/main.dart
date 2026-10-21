import 'dart:async';

import 'package:flutter/material.dart';

import 'config.dart';
import 'debug_log.dart';
import 'platform/android_bridge.dart';
import 'voice/session_client.dart';
import 'voice/voice_adapter.dart';
import 'voice/webview_bolna_adapter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: DebugScreen()),
  );
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> with WidgetsBindingObserver {
  final _android = AndroidBridge();
  final VoiceAdapter _voice = WebViewBolnaAdapter();
  final _sessions = SessionClient(
    url: PocConfig.sessionUrl,
    token: PocConfig.devSessionToken,
  );
  StreamSubscription<Object?>? _androidSub;

  /// null = agent's default language; otherwise sent as agent_data.language.
  String? _language;
  bool _useForegroundService = false;
  bool _starting = false;
  String? _appError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voice.state.addListener(_onVoiceState);
    _voice.lastError.addListener(() => setState(() {}));
    _androidSub = _android.events.listen((e) => log('android', '$e'));
    _init();
  }

  Future<void> _init() async {
    log('init', 'device ${await _android.deviceInfo()}');
    log('init', 'voice=${_voice.name} sessionUrl=${PocConfig.sessionUrl}');
    if (PocConfig.missing.isNotEmpty) {
      setState(
        () => _appError =
            'NOT CONFIGURED: missing ${PocConfig.missing.join(', ')}. '
            'Run with --dart-define-from-file=poc_config.json',
      );
      log('init', _appError!);
    }
  }

  // ------------------------------------------------------------------ lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log('lifecycle', '${state.name} voice=${_voice.state.value.name}');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _logAudio();
    }
  }

  void _onVoiceState() {
    if (_voice.state.value == VoiceState.ended) {
      log(
        'voice',
        'call ENDED while app lifecycle='
            '${WidgetsBinding.instance.lifecycleState?.name}',
      );
      _android.stopVoiceService();
      // Cleanup check: Android should report no active recording from us.
      Future.delayed(const Duration(seconds: 1), _logAudio);
    }
    setState(() {});
  }

  Future<void> _logAudio() async =>
      log('audio', '${await _android.audioSnapshot()}');

  // ------------------------------------------------------------------ voice

  Future<void> _start() async {
    if (PocConfig.missing.isNotEmpty) return;
    setState(() {
      _starting = true;
      _appError = null;
    });
    try {
      final perms = await _android.requestPermissions();
      log('perm', '$perms');
      if (perms['microphone'] != true) {
        throw const SessionException('Microphone permission denied');
      }
      if (_useForegroundService) {
        log('fgs', 'start → ${await _android.startVoiceService()}');
      }
      final session = await _sessions.mint(language: _language);
      log(
        'voice',
        'minted run_id=${session['run_id']} expires_in=${session['expires_in']}',
      );
      await _voice.start(session);
    } catch (e) {
      log('voice', 'START FAILED: $e');
      setState(() => _appError = '$e');
      await _android.stopVoiceService();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    log('voice', 'end requested');
    await _voice.stop();
    await _android.stopVoiceService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _androidSub?.cancel();
    _voice.stop();
    _android.stopVoiceService();
    super.dispose();
  }

  // ------------------------------------------------------------------ UI (plain on purpose)

  @override
  Widget build(BuildContext context) {
    final voiceState = _voice.state.value;
    final inCall =
        voiceState == VoiceState.connecting ||
        voiceState == VoiceState.ringing ||
        voiceState == VoiceState.active;
    final error = _appError ?? _voice.lastError.value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status: ${voiceState.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (error != null)
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String?>(
                    value: _language,
                    onChanged: inCall
                        ? null
                        : (v) => setState(() => _language = v),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Agent default language'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('Start in English'),
                      ),
                      DropdownMenuItem(
                        value: 'mr',
                        child: Text('Start in मराठी'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _useForegroundService,
                        onChanged: inCall
                            ? null
                            : (v) => setState(() => _useForegroundService = v!),
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
                      onPressed: inCall || _starting ? null : _start,
                      child: const Text('Start Voice Session'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: inCall ? _stop : null,
                      child: const Text('End Voice Session'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log audio state',
                    onPressed: _logAudio,
                    icon: const Icon(Icons.mic_external_on),
                  ),
                ],
              ),
              // The WebView *is* the call and must stay mounted. Kept tiny on purpose.
              SizedBox(height: 24, child: _voice.buildHost()),
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
        ),
      ),
    );
  }
}
