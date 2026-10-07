import 'config/app_config.dart';

typedef AppConfigLoader = Future<AppConfig> Function();
typedef DependencyConfigurator = Future<void> Function(AppConfig config);
typedef AppRunner = void Function();

Future<void> initializeApp ({
  required AppConfigLoader loadConfig,
  required DependencyConfigurator configureDependencies,
  required AppRunner runApp,
}) async {
  final config = await loadConfig();
  await configureDependencies(config);
  runApp();
}
