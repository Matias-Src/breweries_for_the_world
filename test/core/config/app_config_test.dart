import 'package:breweries_for_the_world/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the Mapbox token from the environment', () {
    final config = AppConfig.fromEnvironment({
      'MAPBOX_ACCESS_TOKEN': 'pk.test-token',
    });

    expect(config.mapboxAccessToken, 'pk.test-token');
  });

  test('accepts and trims a Mapbox token from the generated environment', () {
    final config = AppConfig.fromMapboxToken(' pk.generated-token ');

    expect(config.mapboxAccessToken, 'pk.generated-token');
  });

  test('rejects a missing generated Mapbox token', () {
    expect(() => AppConfig.fromMapboxToken(null), throwsA(isA<StateError>()));
  });

  test('rejects a blank generated Mapbox token', () {
    expect(() => AppConfig.fromMapboxToken('  '), throwsA(isA<StateError>()));
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
