import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_settings_repository.dart';

class AppSettingsState {
  const AppSettingsState({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale locale;
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._repository)
    : super(
        AppSettingsState(
          themeMode: _repository.themeMode,
          locale: _repository.locale,
        ),
      );

  final AppSettingsRepository _repository;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(AppSettingsState(themeMode: themeMode, locale: state.locale));
    await _repository.saveThemeMode(themeMode);
  }

  Future<void> setLocale(Locale locale) async {
    if (!const {'en', 'es'}.contains(locale.languageCode)) return;
    emit(AppSettingsState(themeMode: state.themeMode, locale: locale));
    await _repository.saveLocale(locale);
  }
}
