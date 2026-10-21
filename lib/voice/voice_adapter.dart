import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Mirrors the Bolna SDK's CallState plus 'unavailable' for adapters that can't run.
enum VoiceState { idle, connecting, ringing, active, ended, unavailable }

/// Voice integration port. The current implementation is WebViewBolnaAdapter (official
/// browser SDK); a native SIP/WebRTC adapter could replace it without touching the
/// rest of the app.
abstract class VoiceAdapter {
  String get name;
  ValueListenable<VoiceState> get state;

  /// Last SDK / environment error, cleared when a call connects.
  ValueListenable<String?> get lastError;

  /// Some adapters need a widget mounted (a WebView). Others return SizedBox.shrink().
  Widget buildHost();

  /// [session] is a freshly minted, single-use Bolna web-call session.
  Future<void> start(Map<String, Object?> session);
  Future<void> stop();
  Future<void> setMuted(bool muted);
}
