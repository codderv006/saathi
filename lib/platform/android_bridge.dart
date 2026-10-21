import 'package:flutter/services.dart';

/// Thin wrapper over MainActivity.kt's channels.
class AndroidBridge {
  static const _methods = MethodChannel('saathi_poc/android');
  static const _events = EventChannel('saathi_poc/android_events');

  Stream<Map<Object?, Object?>> get events =>
      _events.receiveBroadcastStream().map((e) => e as Map<Object?, Object?>);

  Future<Map<Object?, Object?>> requestPermissions() async => (await _methods
      .invokeMethod<Map<Object?, Object?>>('requestPermissions'))!;

  Future<Map<Object?, Object?>> startVoiceService() async => (await _methods
      .invokeMethod<Map<Object?, Object?>>('startVoiceService'))!;

  Future<void> stopVoiceService() => _methods.invokeMethod('stopVoiceService');

  Future<Map<Object?, Object?>> deviceInfo() async =>
      (await _methods.invokeMethod<Map<Object?, Object?>>('deviceInfo'))!;

  Future<Map<Object?, Object?>> audioSnapshot() async =>
      (await _methods.invokeMethod<Map<Object?, Object?>>('audioSnapshot'))!;
}
