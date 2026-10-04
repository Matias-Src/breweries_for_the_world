import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  const AppSettingsState({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale locale;
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._preferences)
    : super(
        AppSettingsState(
          themeMode: _themeModeFrom(_preferences.getString('themeMode')),
          locale: Locale(_localeFrom(_preferences.getString('locale'))),
        ),
      );

  final SharedPreferences _preferences;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(AppSettingsState(themeMode: themeMode, locale: state.locale));
    await _preferences.setString('themeMode', themeMode.name);
  }

  Future<void> setLocale(Locale locale) async {
    if (!const {'en', 'es'}.contains(locale.languageCode)) return;
    emit(AppSettingsState(themeMode: state.themeMode, locale: locale));
    await _preferences.setString('locale', locale.languageCode);
  }

  static ThemeMode _themeModeFrom(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static String _localeFrom(String? value) => value == 'es' ? 'es' : 'en';
}
