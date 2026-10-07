import 'package:breweries_for_the_world/core/settings/app_settings_cubit.dart';
import 'package:breweries_for_the_world/core/settings/app_settings_repository.dart';
import 'package:breweries_for_the_world/core/settings/shared_preferences_app_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads settings and delegates updates to its repository', () async {
    final repository = _InMemoryAppSettingsRepository(
      themeMode: ThemeMode.light,
      locale: const Locale('es'),
    );
    final cubit = AppSettingsCubit(repository);
    addTearDown(cubit.close);

    expect(cubit.state.themeMode, ThemeMode.light);
    expect(cubit.state.locale, const Locale('es'));

    await cubit.setThemeMode(ThemeMode.dark);
    await cubit.setLocale(const Locale('en'));

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('en'));
    expect(repository.themeMode, ThemeMode.dark);
    expect(repository.locale, const Locale('en'));
  });

  test('SharedPreferences repository restores and persists settings', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'light',
      'locale': 'es',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesAppSettingsRepository(preferences);

    expect(repository.themeMode, ThemeMode.light);
    expect(repository.locale, const Locale('es'));

    await repository.saveThemeMode(ThemeMode.dark);
    await repository.saveLocale(const Locale('en'));

    expect(preferences.getString('themeMode'), 'dark');
    expect(preferences.getString('locale'), 'en');
  });
}

class _InMemoryAppSettingsRepository implements AppSettingsRepository {
  _InMemoryAppSettingsRepository({
    required this.themeMode,
    required this.locale,
  });

  @override
  ThemeMode themeMode;

  @override
  Locale locale;

  @override
  Future<void> saveThemeMode(ThemeMode value) async {
    themeMode = value;
  }

  @override
  Future<void> saveLocale(Locale value) async {
    locale = value;
  }
}
