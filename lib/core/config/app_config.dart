import 'app_environment.dart';

class AppConfig {
  const AppConfig({required this.mapboxAccessToken});

  final String mapboxAccessToken;

  static AppConfig fromEnvironment(Map<String, String> environment) {
    return fromMapboxToken(environment['MAPBOX_ACCESS_TOKEN']);
  }

  static AppConfig fromMapboxToken(String? value) {
    final token = value?.trim();
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is required. Provide it with '
        'the .env file and run code generation.',
      );
    }
    return AppConfig(mapboxAccessToken: token);
  }

  static Future<AppConfig> load() async {
    return fromMapboxToken(AppEnvironment.mapboxAccessToken);
  }
}
