import 'package:envied/envied.dart';

part 'app_environment.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class AppEnvironment {
  @EnviedField(varName: 'MAPBOX_ACCESS_TOKEN')
  static final String mapboxAccessToken = _AppEnvironment.mapboxAccessToken;
}
