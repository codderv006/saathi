import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../debug_log.dart';
import 'voice_adapter.dart';

/// Runs the official @bolna/web-call v3.0.1 browser SDK inside an Android WebView.
///
/// Known constraints, by design of this approach:
/// - The WebView must stay mounted; it is the call. Disposing it ends the call.
/// - Android only feeds real mic audio to a backgrounded app that runs a microphone
///   foreground service; that's tested separately (VoiceSessionService toggle).
class WebViewBolnaAdapter implements VoiceAdapter {
  WebViewBolnaAdapter() {
    _controller =
        WebViewController(
            onPermissionRequest: (request) {
              // Only the page we generated runs here; grant mic, refuse anything else.
              final micOnly = request.types.every(
                (t) => t == WebViewPermissionResourceType.microphone,
              );
              log(
                'webview',
                'permission request ${request.types.map((t) => t.name).toList()} → ${micOnly ? 'grant' : 'deny'}',
              );
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
      // start() is invoked via runJavaScript, which isn't a user gesture; without this the
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

  late final WebViewController _controller;
  final _state = ValueNotifier(VoiceState.idle);
  final _lastError = ValueNotifier<String?>(null);
  final _ready = Completer<void>();
  bool _loading = false;
  int? _lastHeartbeat;

  @override
  String get name => 'WebView + @bolna/web-call 3.0.1';

  @override
  ValueListenable<VoiceState> get state => _state;

  @override
  ValueListenable<String?> get lastError => _lastError;

  @override
  Widget buildHost() {
    _load();
    return WebViewWidget(controller: _controller);
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final sdk = await rootBundle.loadString(
      'assets/bolna/bolna-web-call.min.js',
    );
    final html = (await rootBundle.loadString(
      'assets/bolna/call.html',
    )).replaceFirst('/*__BOLNA_SDK__*/', sdk);
    // An https base URL gives the page a secure context, which getUserMedia requires.
    await _controller.loadHtmlString(
      html,
      baseUrl: 'https://saathi-poc.local/',
    );
  }

  @override
  Future<void> start(Map<String, Object?> session) async {
    _lastError.value = null;
    await _ready.future.timeout(const Duration(seconds: 10));
    log('voice', 'starting run_id=${session['run_id']}');
    await _controller.runJavaScript('saathiStart(${jsonEncode(session)});');
  }

  @override
  Future<void> stop() => _controller.runJavaScript('saathiStop();');

  @override
  Future<void> setMuted(bool muted) =>
      _controller.runJavaScript('saathiMute($muted);');

  void _onMessage(String raw) {
    final msg = jsonDecode(raw) as Map<String, Object?>;
    final type = msg['type'];
    switch (type) {
      case 'ready':
        log('webview', 'ready $msg');
        final ok =
            msg['sdkLoaded'] == true &&
            msg['secureContext'] == true &&
            msg['hasRTCPeerConnection'] == true;
        if (!ok) {
          _state.value = VoiceState.unavailable;
          _lastError.value = 'WebView cannot run the SDK: $msg';
        }
        if (!_ready.isCompleted) _ready.complete();
      case 'state':
        final s = msg['state'] as String;
        _state.value = VoiceState.values.asNameMap()[s] ?? _state.value;
        log('voice', 'state → $s');
      case 'heartbeat':
        final t = (msg['t'] as num).toInt();
        final gap = _lastHeartbeat == null ? 0 : t - _lastHeartbeat!;
        _lastHeartbeat = t;
        // Only log heartbeats during a call, or when timers were visibly throttled.
        if (msg['state'] != 'none' && msg['state'] != 'ended' || gap > 4000) {
          final avg = (msg['avgLevel'] as num).toStringAsFixed(3);
          log(
            'heartbeat',
            'state=${msg['state']} vis=${msg['visibility']} gap=${gap}ms '
                'agentAudio samples=${msg['samples']} avg=$avg max=${(msg['maxLevel'] as num).toStringAsFixed(3)}',
          );
        }
      case 'error':
        _lastError.value = '${msg['code']}: ${msg['message']}';
        log('voice', 'ERROR ${_lastError.value} scope=${msg['scope']}');
      case 'call-start':
        _lastError.value = null;
        log('voice', 'CONNECTED run_id=${msg['runId']} (agent answered)');
      default:
        msg.remove('type');
        log('voice', '$type $msg');
    }
  }
}
