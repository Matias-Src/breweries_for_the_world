import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/route_mode.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_route_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/pages/brewery_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopBreweryMapAdapter implements BreweryMapAdapter {
  const _NoopBreweryMapAdapter();

  @override
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) => const SizedBox.shrink();

  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  }) => const SizedBox.shrink();

  @override
  Future<void> recenter(UserLocation location) async {}
}

class _RecordingBreweryRouteRepository implements BreweryRouteRepository {
  final requestedModes = <RouteMode>[];
  bool failNextRequest = false;

  @override
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  }) async {
    requestedModes.add(mode);
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('Directions unavailable');
    }
    return BreweryRoute(
      mode: mode,
      coordinates: [origin, destination],
      distanceMeters: 1200,
      durationSeconds: mode == RouteMode.walking ? 900 : 300,
    );
  }
}

class _RecordingBreweryMapAdapter implements BreweryMapAdapter {
  BreweryRoute? lastRoute;
  double? lastBottomPanelHeight;

  @override
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) => const SizedBox.shrink();

  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  }) {
    lastRoute = route;
    lastBottomPanelHeight = bottomPanelHeight;
    return const SizedBox.shrink();
  }

  @override
  Future<void> recenter(UserLocation location) async {}
}

void main() {
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  testWidgets('loads a walking route and requests driving when selected', (
    tester,
  ) async {
    const origin = UserLocation(latitude: 37.7, longitude: -122.4);
    const brewery = Brewery(
      id: 'brewery-route',
      name: 'Route Brewery',
      breweryType: 'micro',
      latitude: 37.8,
      longitude: -122.3,
    );
    final repository = _RecordingBreweryRouteRepository();
    final mapAdapter = _RecordingBreweryMapAdapter();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BreweryDetailPage(
          brewery: brewery,
          mapAdapter: mapAdapter,
          userLocation: origin,
          getBreweryRoute: GetBreweryRoute(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedModes, [RouteMode.walking]);
    expect(mapAdapter.lastRoute?.mode, RouteMode.walking);
    expect(mapAdapter.lastBottomPanelHeight, greaterThan(0));
    expect(find.byType(SegmentedButton<RouteMode>), findsOneWidget);
    await tester.tap(find.text('En auto'));
    await tester.pumpAndSettle();

    expect(repository.requestedModes, [RouteMode.walking, RouteMode.driving]);
    expect(find.text('5 min · 1.2 km'), findsOneWidget);
  });

  testWidgets('shows unavailable location without requesting a route', (
    tester,
  ) async {
    const brewery = Brewery(
      id: 'brewery-no-origin',
      name: 'No Origin Brewery',
      breweryType: 'micro',
      latitude: 37.8,
      longitude: -122.3,
    );
    final repository = _RecordingBreweryRouteRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BreweryDetailPage(
          brewery: brewery,
          mapAdapter: const _NoopBreweryMapAdapter(),
          getBreweryRoute: GetBreweryRoute(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location unavailable'), findsOneWidget);
    expect(repository.requestedModes, isEmpty);
  });

  testWidgets('shows a route error and retries the selected mode', (
    tester,
  ) async {
    const origin = UserLocation(latitude: 37.7, longitude: -122.4);
    const brewery = Brewery(
      id: 'brewery-route-retry',
      name: 'Retry Brewery',
      breweryType: 'micro',
      latitude: 37.8,
      longitude: -122.3,
    );
    final repository = _RecordingBreweryRouteRepository()
      ..failNextRequest = true;

    await tester.pumpWidget(
      MaterialApp(
        home: BreweryDetailPage(
          brewery: brewery,
          mapAdapter: const _NoopBreweryMapAdapter(),
          userLocation: origin,
          getBreweryRoute: GetBreweryRoute(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not calculate route'), findsOneWidget);
    await tester.tap(find.byTooltip('Retry route'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.requestedModes, [RouteMode.walking, RouteMode.walking]);
    expect(find.byKey(const ValueKey('route-summary')), findsOneWidget);
  });

  testWidgets('shows a large map above a fixed, non-scrollable detail panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: BreweryDetailPage(
          brewery: Brewery(
            id: 'brewery-layout',
            name: 'Layout Brewery',
            breweryType: 'micro',
            latitude: 37.8,
            longitude: -122.3,
          ),
          mapAdapter: _NoopBreweryMapAdapter(),
        ),
      ),
    );

    final detailView = find.byKey(
      const ValueKey('brewery-detail-view-brewery-layout'),
    );
    final panel = find.byKey(const ValueKey('brewery-detail-panel'));
    expect(find.byKey(const ValueKey('brewery-detail-map')), findsOneWidget);
    expect(panel, findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      tester.getRect(panel).top,
      greaterThan(tester.getRect(detailView).top + 300),
    );
  });

  testWidgets('opens the brewery website in the external browser', (
    tester,
  ) async {
    const websiteUrl = 'https://example.com';
    Object? launchArguments;
    String? launchMethod;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          launchMethod = call.method;
          launchArguments = call.arguments;
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(urlLauncherChannel, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: BreweryDetailPage(
          brewery: Brewery(
            id: 'brewery-1',
            name: 'Example Brewery',
            breweryType: 'micro',
            websiteUrl: websiteUrl,
          ),
          mapAdapter: _NoopBreweryMapAdapter(),
        ),
      ),
    );

    await tester.tap(find.text(websiteUrl));
    await tester.pump();

    expect(launchMethod, 'launch');
    expect(launchArguments.toString(), contains(websiteUrl));
  });
}
