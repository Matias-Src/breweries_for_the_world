import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_repository.dart';

class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  const SharedPreferencesAppSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  @override
  ThemeMode get themeMode => switch (_preferences.getString('themeMode')) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  @override
  Locale get locale =>
      Locale(_preferences.getString('locale') == 'es' ? 'es' : 'en');

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _preferences.setString('themeMode', themeMode.name);
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    await _preferences.setString('locale', locale.languageCode);
  }
}
