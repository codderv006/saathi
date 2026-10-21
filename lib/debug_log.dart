import 'package:flutter/foundation.dart';

/// In-app log mirror. Every line also goes to `flutter logs` / logcat with a `[saathi]`
/// prefix so device runs can be captured with: adb logcat | grep saathi
class DebugLog {
  final lines = ValueNotifier<List<String>>(const []);
  final _start = DateTime.now();

  void call(String tag, String message) {
    final now = DateTime.now();
    final clock = '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}';
    final elapsed = (now.difference(_start).inMilliseconds / 1000)
        .toStringAsFixed(1);
    final line = '$clock +${elapsed}s [$tag] $message';
    debugPrint('[saathi] $line');
    final next = [...lines.value, line];
    lines.value = next.length > 500 ? next.sublist(next.length - 500) : next;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

final log = DebugLog();
