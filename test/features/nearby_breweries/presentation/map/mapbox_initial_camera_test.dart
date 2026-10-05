// ignore_for_file: depend_on_referenced_packages

import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/route_mode.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/map/mapbox_brewery_map_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';

base class _RecordingMapboxPlatform extends MapboxMapsFlutterPlatform {
  final List<ViewportState?> viewports = [];

  @override
  Widget buildView({
    required String styleUri,
    PlatformMapCreatedCallback? onMapCreated,
    ViewportState? viewport,
    ViewportTransition? viewportTransition,
    void Function(bool)? viewportTransitionCompletion,
    void Function(MapEvent)? onMapEvent,
    MapOptions? mapOptions,
    bool? textureView,
    // ignore: experimental_member_use
    required AndroidPlatformViewHostingMode androidHostingMode,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? isOpaque = true,
  }) {
    viewports.add(viewport);
    return const ColoredBox(color: Colors.black);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('uses a regional center and non-global zoom without location', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: adapter.buildMap(
            userLocation: null,
            initialCameraLocation: null,
            breweries: const [],
            selectedBreweryId: null,
            onBrewerySelected: (_) {},
          ),
        ),
      ),
    );

    final camera = platform.viewports.single! as CameraViewportState;
    expect(camera.center, isNotNull);
    final center = camera.center!.coordinates;
    expect(center.lat, inInclusiveRange(-90, 90));
    expect(center.lng, inInclusiveRange(-180, 180));
    expect(center.lat == 0 && center.lng == 0, isFalse);
    expect(center.lat, 39.8283);
    expect(center.lng, -98.5795);
    expect(camera.zoom, 5.5);
  });

  testWidgets('uses a regional zoom level when location is unavailable', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: adapter.buildMap(
            userLocation: null,
            initialCameraLocation: null,
            breweries: const [],
            selectedBreweryId: null,
            onBrewerySelected: (_) {},
          ),
        ),
      ),
    );

    final camera = platform.viewports.single! as CameraViewportState;
    expect(camera.zoom, 5.5);
  });

  testWidgets('invalid initial coordinates use the regional camera fallback', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();
    const invalidLocation = UserLocation(latitude: 91, longitude: 200);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: adapter.buildMap(
            userLocation: invalidLocation,
            initialCameraLocation: invalidLocation,
            breweries: const [],
            selectedBreweryId: null,
            onBrewerySelected: (_) {},
          ),
        ),
      ),
    );

    final camera = platform.viewports.single! as CameraViewportState;
    expect(camera.zoom, 5.5);
    expect(camera.center, isNotNull);
    final center = camera.center!.coordinates;
    expect(center.lat, 39.8283);
    expect(center.lng, -98.5795);
  });

  testWidgets('prefers a valid user location for the initial camera', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();
    const location = UserLocation(latitude: 40.7, longitude: -73.9);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: adapter.buildMap(
            userLocation: location,
            initialCameraLocation: location,
            breweries: const [],
            selectedBreweryId: null,
            onBrewerySelected: (_) {},
          ),
        ),
      ),
    );

    final camera = platform.viewports.single! as CameraViewportState;
    expect(camera.zoom, 12);
    expect(camera.center!.coordinates.lat, location.latitude);
    expect(camera.center!.coordinates.lng, location.longitude);
  });

  testWidgets('centers the brewery when its route is unavailable', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();
    const userLocation = UserLocation(latitude: 40.7, longitude: -73.9);
    const brewery = Brewery(
      id: 'selected-brewery',
      name: 'Selected Brewery',
      breweryType: 'micro',
      latitude: 41.3,
      longitude: -72.5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: adapter.buildBreweryMap(
            brewery: brewery,
            userLocation: userLocation,
            route: null,
            bottomPanelHeight: 200,
          ),
        ),
      ),
    );

    final camera = platform.viewports.single! as CameraViewportState;
    expect(camera.center!.coordinates.lat, brewery.latitude);
    expect(camera.center!.coordinates.lng, brewery.longitude);
    expect(camera.center!.coordinates.lat, isNot(userLocation.latitude));
    expect(camera.zoom, 12);
  });

  testWidgets('keeps the brewery as initial camera target when route loads', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();
    const userLocation = UserLocation(latitude: 40.7, longitude: -73.9);
    const brewery = Brewery(
      id: 'selected-brewery',
      name: 'Selected Brewery',
      breweryType: 'micro',
      latitude: 41.3,
      longitude: -72.5,
    );
    BreweryRoute? route;
    late StateSetter rebuildMap;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuildMap = setState;
            return SizedBox.expand(
              child: adapter.buildBreweryMap(
                brewery: brewery,
                userLocation: userLocation,
                route: route,
                bottomPanelHeight: 200,
              ),
            );
          },
        ),
      ),
    );

    route = const BreweryRoute(
      mode: RouteMode.walking,
      coordinates: [
        userLocation,
        UserLocation(latitude: 41.3, longitude: -72.5),
      ],
      distanceMeters: 1000,
      durationSeconds: 600,
    );
    rebuildMap(() {});
    await tester.pumpAndSettle();

    final camera = platform.viewports.last! as CameraViewportState;
    expect(camera.center!.coordinates.lat, brewery.latitude);
    expect(camera.center!.coordinates.lng, brewery.longitude);
  });

  testWidgets('does not reset a user-moved camera when brewery data changes', (
    tester,
  ) async {
    final platform = _RecordingMapboxPlatform();
    final previousPlatform = _installPlatform(platform);
    addTearDown(() => _restorePlatform(previousPlatform));
    final adapter = MapboxBreweryMapAdapter();
    const initialLocation = UserLocation(latitude: 40.7, longitude: -73.9);
    const movedLocation = UserLocation(latitude: 41.2, longitude: -72.4);
    var breweries = const <Brewery>[];
    late StateSetter rebuildMap;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuildMap = setState;
            return SizedBox.expand(
              child: adapter.buildMap(
                userLocation: initialLocation,
                initialCameraLocation: initialLocation,
                breweries: breweries,
                selectedBreweryId: null,
                onBrewerySelected: (_) {},
              ),
            );
          },
        ),
      ),
    );

    await adapter.recenter(movedLocation);
    await tester.pumpAndSettle();
    breweries = const [
      Brewery(
        id: 'new-result',
        name: 'New result',
        breweryType: 'micro',
        latitude: 41.3,
        longitude: -72.5,
      ),
    ];
    rebuildMap(() {});
    await tester.pumpAndSettle();

    final camera = platform.viewports.last! as CameraViewportState;
    expect(camera.center!.coordinates.lat, movedLocation.latitude);
    expect(camera.center!.coordinates.lng, movedLocation.longitude);
  });
}

MapboxMapsFlutterPlatform? _installPlatform(
  MapboxMapsFlutterPlatform platform,
) {
  MapboxMapsFlutterPlatform? previousPlatform;
  try {
    previousPlatform = MapboxMapsFlutterPlatform.instance;
  } on AssertionError {
    previousPlatform = null;
  }
  MapboxMapsFlutterPlatform.instance = platform;
  return previousPlatform;
}

void _restorePlatform(MapboxMapsFlutterPlatform? platform) {
  if (platform != null) MapboxMapsFlutterPlatform.instance = platform;
}
