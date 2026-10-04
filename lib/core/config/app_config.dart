import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({required this.mapboxAccessToken});

  final String mapboxAccessToken;

  static AppConfig fromEnvironment(Map<String, String> environment) {
    final token = environment['MAPBOX_ACCESS_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is required. Set it in the local .env file.',
      );
    }
    return AppConfig(mapboxAccessToken: token);
  }

  static Future<AppConfig> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    return fromEnvironment(dotenv.env);
  }
}
