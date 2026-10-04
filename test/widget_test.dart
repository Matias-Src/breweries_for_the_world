// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breweries_for_the_world/core/navigation/app_router.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import 'package:breweries_for_the_world/core/settings/app_settings_cubit.dart';
import 'package:breweries_for_the_world/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the nearby breweries loading state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final bloc = NearbyBreweriesBloc(
      getNearestBreweries: GetNearestBreweries(_EmptyBreweryRepository()),
    );
    final repository = _EmptyBreweryRepository();
    final appRouter = AppRouter(
      mapAdapter: _EmptyMapAdapter(),
      getBreweryById: GetBreweryById(repository),
      createCatalogBloc: () => BreweryCatalogBloc(
        getBreweries: GetBreweryPage(repository),
        searchBreweries: SearchBreweries(repository),
      ),
    );
    final settingsCubit = AppSettingsCubit(preferences);
    addTearDown(bloc.close);
    addTearDown(settingsCubit.close);
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MyApp(
        nearbyBreweriesBloc: bloc,
        appSettingsCubit: settingsCubit,
        appRouter: appRouter,
      ),
    );

    expect(find.byKey(const ValueKey('brewery-search-field')), findsOneWidget);
    expect(
      Theme.of(
        tester.element(find.byKey(const ValueKey('brewery-search-field'))),
      ).brightness,
      Brightness.dark,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Flutter Demo Home Page'), findsNothing);
  });
}

class _EmptyBreweryRepository implements BreweryRepository {
  @override
  Future<Brewery> getBreweryById({required String id}) async =>
      Brewery(id: id, name: 'Example', breweryType: 'micro');

  @override
  Future<List<Brewery>> getBreweries({
    required int page,
    int perPage = 20,
  }) async => [];

  @override
  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int limit = 40,
  }) async => [];

  @override
  Future<List<Brewery>> searchBreweries({required String query}) async => [];
}

class _EmptyMapAdapter implements BreweryMapAdapter {
  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  }) => const SizedBox.expand();

  @override
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) => const SizedBox.expand();

  @override
  Future<void> recenter(UserLocation location) async {}
}
