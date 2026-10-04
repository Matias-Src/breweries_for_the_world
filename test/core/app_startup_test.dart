import 'dart:async';

import 'package:breweries_for_the_world/core/app_startup.dart';
import 'package:breweries_for_the_world/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads config and registers dependencies before starting the app',
    () async {
      final steps = <String>[];
      final pendingNetworkRequest = Completer<void>();

      await bootstrapApp(
        loadConfig: () async {
          steps.add('config');
          return const AppConfig(mapboxAccessToken: 'pk.test-token');
        },
        configureDependencies: (config) async {
          expect(config.mapboxAccessToken, 'pk.test-token');
          steps.add('dependencies');
        },
        runApp: () {
          steps.add('runApp');
          unawaited(pendingNetworkRequest.future);
        },
      );

      expect(steps, ['config', 'dependencies', 'runApp']);
      expect(pendingNetworkRequest.isCompleted, isFalse);
    },
  );

  test('does not start the app when configuration loading fails', () async {
    var appStarted = false;

    await expectLater(
      bootstrapApp(
        loadConfig: () => Future.error(StateError('Missing Mapbox token')),
        configureDependencies: (_) async {},
        runApp: () => appStarted = true,
      ),
      throwsA(isA<StateError>()),
    );

    expect(appStarted, isFalse);
  });
}
