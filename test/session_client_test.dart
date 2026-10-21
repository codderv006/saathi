import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saathi_poc/features/voice_session/data/session_client.dart';

void main() {
  const validSession = {
    'run_id': 'r1',
    'agent_id': 'a1',
    'sip_username': 'u',
    'sip_password': 'p',
    'sip_domain': 'd',
    'wss_url': 'wss://example.invalid',
    'sip_register': false,
    'expires_in': 120,
    'ice_servers': <Object>[],
  };

  SessionClient client(Future<http.Response> Function(http.Request) handler) =>
      SessionClient(
        url: 'http://localhost:8787/session',
        token: 'tok',
        client: MockClient(handler),
      );

  test('sends token header and omits language when null', () async {
    late http.Request seen;
    final session = await client((req) async {
      seen = req;
      return http.Response(jsonEncode(validSession), 200);
    }).mint();
    expect(session['run_id'], 'r1');
    expect(seen.headers['X-Dev-Token'], 'tok');
    expect(jsonDecode(seen.body), isEmpty);
  });

  test('sends requested language', () async {
    late http.Request seen;
    await client((req) async {
      seen = req;
      return http.Response(jsonEncode(validSession), 200);
    }).mint(language: 'mr');
    expect(jsonDecode(seen.body), {'language': 'mr'});
  });

  test('non-200 from backend surfaces as an error, never a session', () {
    expect(
      client(
        (_) async => http.Response('{"detail":"Invalid access token"}', 403),
      ).mint(),
      throwsA(
        isA<SessionException>().having(
          (e) => e.message,
          'message',
          contains('403'),
        ),
      ),
    );
  });

  test('unexpected response shape is rejected', () {
    expect(
      client((_) async => http.Response('{"run_id":"r1"}', 200)).mint(),
      throwsA(isA<SessionException>()),
    );
  });

  test('unreachable backend gives an actionable error', () {
    expect(
      client((_) async => throw http.ClientException('refused')).mint(),
      throwsA(
        isA<SessionException>().having(
          (e) => e.message,
          'message',
          contains('adb reverse'),
        ),
      ),
    );
  });
}
