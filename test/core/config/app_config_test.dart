import 'package:breweries_for_the_world/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the Mapbox token from the environment', () {
    final config = AppConfig.fromEnvironment({
      'MAPBOX_ACCESS_TOKEN': 'pk.test-token',
    });

    expect(config.mapboxAccessToken, 'pk.test-token');
  });

  test('fails clearly when the Mapbox token is missing', () {
    expect(
      () => AppConfig.fromEnvironment(const {}),
      throwsA(isA<StateError>()),
    );
  });

  test('fails clearly when the Mapbox token is blank', () {
    expect(
      () => AppConfig.fromEnvironment({'MAPBOX_ACCESS_TOKEN': '  '}),
      throwsA(isA<StateError>()),
    );
  });
}
