import 'package:flutter/widgets.dart';

/// What the user should be told about the voice call. Provider-agnostic.
enum VoicePhase {
  idle,
  requestingPermission,
  connecting,
  listening,

  /// Agent audio is playing (derived from the SDK's agent volume level).
  speaking,
  muted,

  /// Ended by the user.
  ended,

  /// Ended from the other side or the connection dropped.
  disconnected,
  failed,
}

enum VoiceFailure {
  microphoneDenied,
  notConfigured,
  network,
  busy,
  unavailable,
  generic,
}

@immutable
class VoiceStatus {
  const VoiceStatus(this.phase, {this.failure});

  final VoicePhase phase;
  final VoiceFailure? failure;

  bool get isLive => switch (phase) {
    VoicePhase.connecting ||
    VoicePhase.listening ||
    VoicePhase.speaking ||
    VoicePhase.muted => true,
    _ => false,
  };

  bool get isBusy => isLive || phase == VoicePhase.requestingPermission;

  @override
  String toString() =>
      'VoiceStatus(${phase.name}${failure == null ? '' : ', ${failure!.name}'})';
}

/// The app talks to voice only through this. The Bolna WebView implementation can be
/// swapped (e.g. for a native SDK) without touching screens or the workflow engine.
abstract class VoiceSessionService extends ChangeNotifier {
  VoiceStatus get status;
  bool get muted;

  /// [context] is short, non-secret text the agent may use (current task/step).
  /// It informs the conversation; it never controls workflow state.
  Future<void> start({
    required String language,
    Map<String, String> context = const {},
  });

  Future<void> end();
  Future<void> setMuted(bool muted);

  /// Some implementations need a widget kept mounted for the whole app lifetime
  /// (the WebView *is* the call). Others return an empty box.
  Widget buildHost();
}
