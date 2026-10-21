import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../core/services/android_bridge.dart';
import '../../../core/services/debug_log.dart';
import '../domain/voice_session_service.dart';
import 'session_client.dart';

/// Runs the official @bolna/web-call v3.0.1 browser SDK inside an Android WebView —
/// the approach verified on device (Realme 6 / Android 11: EN + MR, app switching,
/// short screen lock, clean mic release).
///
/// The WebView *is* the call: [buildHost] must stay mounted for the app's lifetime
/// (SaathiApp keeps it under the navigator), or navigating would end the call.
class BolnaVoiceService extends VoiceSessionService {
  BolnaVoiceService({
    required SessionClient? sessions,
    required AndroidBridge android,
  }) : _sessions = sessions,
       _android = android {
    _controller =
        WebViewController(
            onPermissionRequest: (request) {
              // Only our own generated page runs here; grant mic, refuse anything else.
              final micOnly = request.types.every(
                (t) => t == WebViewPermissionResourceType.microphone,
              );
              log('webview', 'permission ${micOnly ? 'granted' : 'denied'}');
              micOnly ? request.grant() : request.deny();
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'SaathiBridge',
            onMessageReceived: (m) => _onMessage(m.message),
          );

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      // start() runs via runJavaScript, which isn't a user gesture; without this the
      // agent's audio would fail with autoplay_blocked.
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnConsoleMessage((m) {
        if (m.level == JavaScriptLogLevel.error ||
            m.level == JavaScriptLogLevel.warning) {
          log('js-console', '${m.level.name}: ${m.message}');
        }
      });
    }
  }

  /// Speaking/listening threshold on the SDK's agent volume level (0–1). Heuristic
  /// from device logs: silence ≈ 0.10, speech 0.3–0.6.
  static const _speakingLevel = 0.2;
  static const _quietBeforeListening = Duration(milliseconds: 700);

  final SessionClient? _sessions;
  final AndroidBridge _android;
  late final WebViewController _controller;
  final _ready = Completer<bool>();
  bool _loading = false;
  int? _lastHeartbeat;

  VoiceStatus _status = const VoiceStatus(VoicePhase.idle);
  bool _muted = false;
  bool _endRequested = false;
  DateTime? _lastLoud;

  /// Diagnostics only: run the opt-in microphone foreground service during calls.
  /// The verified product path does not use it.
  bool useForegroundService = false;

  @override
  VoiceStatus get status => _status;

  @override
  bool get muted => _muted;

  @override
  Widget buildHost() {
    _load();
    return WebViewWidget(controller: _controller);
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final sdk = await rootBundle.loadString(
        'assets/bolna/bolna-web-call.min.js',
      );
      final html = (await rootBundle.loadString(
        'assets/bolna/call.html',
      )).replaceFirst('/*__BOLNA_SDK__*/', sdk);
      // An https base URL gives the page a secure context, which getUserMedia needs.
      await _controller.loadHtmlString(
        html,
        baseUrl: 'https://saathi-poc.local/',
      );
    } catch (e) {
      log('voice', 'could not load call page: $e');
      if (!_ready.isCompleted) _ready.complete(false);
    }
  }

  void _set(VoicePhase phase, {VoiceFailure? failure}) {
    final next = VoiceStatus(phase, failure: failure);
    if (next.phase == _status.phase && next.failure == _status.failure) return;
    _status = next;
    log('voice', '$next');
    notifyListeners();
  }

  @override
  Future<void> start({
    required String language,
    Map<String, String> context = const {},
  }) async {
    if (_status.isBusy) return;
    final sessions = _sessions;
    if (sessions == null) {
      _set(VoicePhase.failed, failure: VoiceFailure.notConfigured);
      return;
    }
    _endRequested = false;
    _muted = false;

    _set(VoicePhase.requestingPermission);
    final Map<Object?, Object?> perms;
    try {
      perms = await _android.requestPermissions();
    } catch (e) {
      log('voice', 'permission request failed: $e');
      _set(VoicePhase.failed, failure: VoiceFailure.generic);
      return;
    }
    if (perms['microphone'] != true) {
      _set(VoicePhase.failed, failure: VoiceFailure.microphoneDenied);
      return;
    }
    if (_endRequested) return _set(VoicePhase.ended);

    _set(VoicePhase.connecting);
    if (useForegroundService) {
      log('fgs', 'start → ${await _android.startVoiceService()}');
    }
    try {
      final session = await sessions.mint(language: language, context: context);
      if (_endRequested) return _finish(VoicePhase.ended);
      final pageOk = await _ready.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!pageOk) {
        return _finish(VoicePhase.failed, failure: VoiceFailure.unavailable);
      }
      log('voice', 'starting run_id=${session['run_id']} language=$language');
      await _controller.runJavaScript('saathiStart(${jsonEncode(session)});');
    } on SessionException catch (e) {
      log('voice', 'mint failed: $e');
      _finish(
        VoicePhase.failed,
        failure: e.statusCode == 429
            ? VoiceFailure.busy
            : e.unreachable
            ? VoiceFailure.network
            : VoiceFailure.generic,
      );
    } catch (e) {
      log('voice', 'start failed: $e');
      _finish(VoicePhase.failed, failure: VoiceFailure.generic);
    }
  }

  @override
  Future<void> end() async {
    _endRequested = true;
    log('voice', 'end requested');
    if (_status.phase == VoicePhase.requestingPermission) {
      return _finish(VoicePhase.ended);
    }
    try {
      await _controller.runJavaScript('saathiStop();');
    } catch (e) {
      log('voice', 'stop failed: $e');
    }
    // call-end from the SDK moves us to ended; cover the case where no call existed.
    if (_status.phase == VoicePhase.connecting) _finish(VoicePhase.ended);
    await _android.stopVoiceService();
  }

  @override
  Future<void> setMuted(bool muted) async {
    if (!_status.isLive) return;
    await _controller.runJavaScript('saathiMute($muted);');
    _muted = muted;
    _set(muted ? VoicePhase.muted : VoicePhase.listening);
  }

  void _finish(VoicePhase phase, {VoiceFailure? failure}) {
    _android.stopVoiceService();
    _muted = false;
    _set(phase, failure: failure);
  }

  void _onMessage(String raw) {
    final msg = jsonDecode(raw) as Map<String, Object?>;
    switch (msg['type']) {
      case 'ready':
        log('webview', 'ready $msg');
        final ok =
            msg['sdkLoaded'] == true &&
            msg['secureContext'] == true &&
            msg['hasRTCPeerConnection'] == true;
        if (!_ready.isCompleted) _ready.complete(ok);
      case 'state':
        log('voice', 'sdk state → ${msg['state']}');
        if (msg['state'] == 'active' &&
            _status.phase == VoicePhase.connecting) {
          _set(_muted ? VoicePhase.muted : VoicePhase.listening);
        }
      case 'call-start':
        log('voice', 'CONNECTED run_id=${msg['runId']}');
      case 'level':
        _onLevel((msg['v'] as num).toDouble());
      case 'call-end':
        log('voice', 'call-end reason=${msg['reason']}');
        if (_status.phase == VoicePhase.failed) {
          _android.stopVoiceService(); // keep the failure visible
          return;
        }
        final byUser = msg['reason'] == 'local-hangup' || _endRequested;
        _finish(byUser ? VoicePhase.ended : VoicePhase.disconnected);
      case 'error':
        log(
          'voice',
          'ERROR ${msg['code']}: ${msg['message']} scope=${msg['scope']}',
        );
        final failure = switch (msg['code']) {
          'microphone_denied' => VoiceFailure.microphoneDenied,
          'at_capacity' => VoiceFailure.busy,
          'connect_failed' || 'mint_failed' => VoiceFailure.network,
          'already_active' => null,
          _ => VoiceFailure.generic,
        };
        // Setup errors become a visible failure. Mid-call errors are followed by
        // call-end, which decides the final state.
        if (failure != null && _status.phase == VoicePhase.connecting) {
          _finish(VoicePhase.failed, failure: failure);
        }
      case 'heartbeat':
        _logHeartbeat(msg);
      default:
        log('voice', '$msg');
    }
  }

  void _onLevel(double level) {
    if (_muted || !_status.isLive || _status.phase == VoicePhase.connecting) {
      return;
    }
    final now = DateTime.now();
    if (level >= _speakingLevel) {
      _lastLoud = now;
      _set(VoicePhase.speaking);
    } else if (_status.phase == VoicePhase.speaking &&
        (_lastLoud == null ||
            now.difference(_lastLoud!) > _quietBeforeListening)) {
      _set(VoicePhase.listening);
    }
  }

  void _logHeartbeat(Map<String, Object?> msg) {
    final t = (msg['t'] as num).toInt();
    final gap = _lastHeartbeat == null ? 0 : t - _lastHeartbeat!;
    _lastHeartbeat = t;
    // Only during a call, or when timers were visibly throttled.
    if (msg['state'] != 'none' && msg['state'] != 'ended' || gap > 4000) {
      log(
        'heartbeat',
        'state=${msg['state']} vis=${msg['visibility']} gap=${gap}ms '
            'agentAudio samples=${msg['samples']} '
            'avg=${(msg['avgLevel'] as num).toStringAsFixed(3)} '
            'max=${(msg['maxLevel'] as num).toStringAsFixed(3)}',
      );
    }
  }
}
