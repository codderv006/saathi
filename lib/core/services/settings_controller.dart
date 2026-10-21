import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences: onboarding, language, installation id.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs);

  static const _kOnboarded = 'saathi.onboardingDone';
  static const _kLanguage = 'saathi.language';
  static const _kInstallation = 'saathi.installationId';
  static const supportedLanguages = ['en', 'mr'];

  final SharedPreferences _prefs;

  static Future<SettingsController> load() async {
    final controller = SettingsController._(
      await SharedPreferences.getInstance(),
    );
    if (controller._prefs.getString(_kInstallation) == null) {
      await controller._prefs.setString(_kInstallation, randomId());
    }
    return controller;
  }

  bool get onboardingDone => _prefs.getBool(_kOnboarded) ?? false;

  String get language {
    final saved = _prefs.getString(_kLanguage);
    return supportedLanguages.contains(saved) ? saved! : 'en';
  }

  /// Organisational aid only — never treated as proof of identity.
  String get installationId => _prefs.getString(_kInstallation)!;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.contains(code) || code == language) return;
    await _prefs.setString(_kLanguage, code);
    notifyListeners();
  }

  static String randomId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
