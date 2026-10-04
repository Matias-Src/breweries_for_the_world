class AppConfig {
  const AppConfig({required this.mapboxAccessToken});

  final String mapboxAccessToken;

  static AppConfig fromEnvironment(Map<String, String> environment) {
    final token = environment['MAPBOX_ACCESS_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is required. Provide it with '
        '--dart-define-from-file=.env.',
      );
    }
    return AppConfig(mapboxAccessToken: token);
  }

  static Future<AppConfig> load() async {
    return fromEnvironment({
      'MAPBOX_ACCESS_TOKEN': const String.fromEnvironment(
        'MAPBOX_ACCESS_TOKEN',
      ),
    });
  }
}
