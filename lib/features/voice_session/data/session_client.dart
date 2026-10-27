import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches a short-lived (~120 s), single-use Bolna web-call session from OUR backend,
/// which holds the Bolna API key. This client never sees that key.
class SessionClient {
  SessionClient({required this.url, required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String url;
  final String token;
  final http.Client _client;

  /// [language] null = the agent's default language. [context] is forwarded as
  /// Bolna `user_data` (the backend whitelists keys).
  Future<Map<String, Object?>> mint({
    String? language,
    Map<String, String> context = const {},
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'X-Dev-Token': token},
            body: jsonEncode({
              'language': ?language,
              if (context.isNotEmpty) 'user_data': context,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw SessionException(
        'Backend unreachable at $url ($e). Check the internet connection and that '
        'the session server (worker/ or server/session_server.mjs) is running.',
        unreachable: true,
      );
    }
    if (response.statusCode != 200) {
      throw SessionException(
        'Mint failed: HTTP ${response.statusCode} ${_trim(response.body)}',
        statusCode: response.statusCode,
      );
    }
    final session = jsonDecode(response.body) as Map<String, Object?>;
    // Same shape check as the SDK's own fetchSession().
    for (final key in ['run_id', 'wss_url', 'sip_username', 'ice_servers']) {
      if (session[key] == null) {
        throw SessionException('Mint response missing $key');
      }
    }
    return session;
  }

  static String _trim(String s) =>
      s.length > 300 ? '${s.substring(0, 300)}…' : s;
}

class SessionException implements Exception {
  const SessionException(
    this.message, {
    this.statusCode,
    this.unreachable = false,
  });
  final String message;
  final int? statusCode;
  final bool unreachable;
  @override
  String toString() => message;
}
