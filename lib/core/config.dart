/// Build-time config: `flutter run --dart-define-from-file=poc_config.json`
/// (copy poc_config.example.json). No Bolna API key ever lives in the app.
class PocConfig {
  static const appVersion = '0.1.0';

  /// Backend that mints Bolna web-call sessions (server/session_server.mjs in dev).
  static const sessionUrl = String.fromEnvironment('SESSION_URL');

  /// Shared token for the local dev backend. Not a Bolna credential.
  static const devSessionToken = String.fromEnvironment('DEV_SESSION_TOKEN');

  // Firebase client config (from android/app/google-services.json). Optional:
  // without it the app keeps progress on the phone only.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseSenderId.isNotEmpty;

  static List<String> get missing => [
    if (sessionUrl.isEmpty) 'SESSION_URL',
    if (devSessionToken.isEmpty) 'DEV_SESSION_TOKEN',
  ];
}
