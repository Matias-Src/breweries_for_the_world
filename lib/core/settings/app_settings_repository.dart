import 'package:flutter/material.dart';

abstract interface class AppSettingsRepository {
  ThemeMode get themeMode;

  Locale get locale;

  Future<void> saveThemeMode(ThemeMode themeMode);

  Future<void> saveLocale(Locale locale);
}
