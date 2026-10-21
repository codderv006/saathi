/// Build-time config: `flutter run --dart-define-from-file=poc_config.json`
/// (copy poc_config.example.json). No Bolna API key ever lives in the app.
class PocConfig {
  static const appVersion = '0.1.0';

  /// Backend that mints Bolna web-call sessions (server/session_server.mjs in dev).
  static const sessionUrl = String.fromEnvironment('SESSION_URL');

  /// Shared token for the local dev backend. Not a Bolna credential.
  static const devSessionToken = String.fromEnvironment('DEV_SESSION_TOKEN');

  static List<String> get missing => [
    if (sessionUrl.isEmpty) 'SESSION_URL',
    if (devSessionToken.isEmpty) 'DEV_SESSION_TOKEN',
  ];
}
