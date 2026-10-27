import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/services/debug_log.dart';

/// Receives guide actions the voice agent requested (relayed by the local server)
/// and posts back the app's answer. Long-polls while running.
class GuideEventsClient {
  GuideEventsClient({
    required this.baseUrl,
    required this.token,
    required this.deviceId,
    required this.onEvent,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final String deviceId;
  final Future<Map<String, Object?>> Function(Map<String, Object?> event)
  onEvent;
  final http.Client _client;
  bool _running = false;
  // Bumped on every start, so a loop still waiting on an old poll exits instead of
  // running alongside the new one.
  int _generation = 0;

  bool get running => _running;

  void start() {
    if (_running) return;
    _running = true;
    unawaited(_loop(++_generation));
  }

  void stop() => _running = false;

  Future<void> _loop(int generation) async {
    final headers = {'X-Dev-Token': token, 'Content-Type': 'application/json'};
    bool current() => _running && generation == _generation;
    while (current()) {
      try {
        final r = await _client
            .get(
              Uri.parse('$baseUrl/events?device=$deviceId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 35));
        if (!current()) break;
        if (r.statusCode == 204) continue;
        if (r.statusCode != 200) {
          await Future<void>.delayed(const Duration(seconds: 3));
          continue;
        }
        final event = jsonDecode(r.body) as Map<String, Object?>;
        log('guide-tool', 'agent asked: $event');
        Map<String, Object?> result;
        try {
          result = await onEvent(event);
        } catch (e) {
          result = {'ok': false, 'message': 'App error: $e'};
        }
        log('guide-tool', 'answer: $result');
        await _client.post(
          Uri.parse('$baseUrl/events/result'),
          headers: headers,
          body: jsonEncode({'id': event['id'], 'result': result}),
        );
      } catch (_) {
        // Server not running or phone not connected: retry quietly.
        if (current()) await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
  }
}
