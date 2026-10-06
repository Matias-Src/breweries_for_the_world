import 'package:breweries_for_the_world/core/navigation/app_router.dart';
import 'package:breweries_for_the_world/core/l10n/app_localizations.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/services/website_launcher.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc/brewery_catalog_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a direct brewery URL loads details using its path id', (
    tester,
  ) async {
    final repository = _RouteTestRepository();
    final appRouter = AppRouter(
      initialLocation: '/breweries/route-brewery',
      mapAdapter: _EmptyMapAdapter(),
      getBreweryById: GetBreweryById(repository),
      websiteLauncher: _EmptyWebsiteLauncher(),
      createCatalogBloc: () => BreweryCatalogBloc(
        getBreweries: GetBreweryPage(repository),
        searchBreweries: SearchBreweries(repository),
      ),
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(_RouterTestApp(appRouter: appRouter));
    await tester.pumpAndSettle();

    expect(repository.requestedId, 'route-brewery');
    expect(find.text('Route Brewery'), findsOneWidget);
  });

  testWidgets('catalog opens a brewery route and back returns to catalog', (
    tester,
  ) async {
    final repository = _RouteTestRepository();
    final appRouter = AppRouter(
      initialLocation: '/breweries',
      mapAdapter: _EmptyMapAdapter(),
      getBreweryById: GetBreweryById(repository),
      websiteLauncher: _EmptyWebsiteLauncher(),
      createCatalogBloc: () => BreweryCatalogBloc(
        getBreweries: GetBreweryPage(repository),
        searchBreweries: SearchBreweries(repository),
      ),
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(_RouterTestApp(appRouter: appRouter));
    await tester.pumpAndSettle();

    expect(find.text('World breweries'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('brewery-catalog-item-route-brewery')),
    );
    await tester.pumpAndSettle();
    expect(repository.requestedId, 'route-brewery');
    expect(
      find.byKey(const ValueKey('brewery-detail-view-route-brewery')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('World breweries'), findsOneWidget);
  });
}

class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: appRouter.router,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

class _RouteTestRepository implements BreweryRepository {
  String? requestedId;

  @override
  Future<Brewery> getBreweryById({required String id}) async {
    requestedId = id;
    return const Brewery(
      id: 'route-brewery',
      name: 'Route Brewery',
      breweryType: 'micro',
    );
  }

  @override
  Future<List<Brewery>> getBreweries({
    required int page,
    int perPage = 20,
  }) async => [
    const Brewery(
      id: 'route-brewery',
      name: 'Route Brewery',
      breweryType: 'micro',
    ),
  ];

  @override
  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int page = 1,
    int limit = 40,
  }) async => [];

  @override
  Future<List<Brewery>> searchBreweries({required String query}) async => [];
}

class _EmptyWebsiteLauncher implements WebsiteLauncher {
  @override
  Future<void> launch(Uri uri) async {}
}

class _EmptyMapAdapter implements BreweryMapAdapter {
  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required userLocation,
    required route,
    required double bottomPanelHeight,
  }) => const SizedBox.expand();

  @override
  Widget buildMap({
    required userLocation,
    required initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) => const SizedBox.expand();

  @override
  Future<void> recenter(location) async {}
}
