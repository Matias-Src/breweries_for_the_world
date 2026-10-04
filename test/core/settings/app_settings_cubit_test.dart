import 'package:breweries_for_the_world/core/settings/app_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and persists theme and language preferences', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'light',
      'locale': 'es',
    });
    final preferences = await SharedPreferences.getInstance();
    final cubit = AppSettingsCubit(preferences);
    addTearDown(cubit.close);

    expect(cubit.state.themeMode, ThemeMode.light);
    expect(cubit.state.locale, const Locale('es'));

    await cubit.setThemeMode(ThemeMode.dark);
    await cubit.setLocale(const Locale('en'));

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('en'));
    expect(preferences.getString('themeMode'), 'dark');
    expect(preferences.getString('locale'), 'en');
  });
}
