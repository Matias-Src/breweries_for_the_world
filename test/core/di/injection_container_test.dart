import 'package:breweries_for_the_world/core/config/app_config.dart';
import 'package:breweries_for_the_world/core/di/injection_container.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/brewery_remote_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/location_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_route_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/location_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_current_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late GetIt container;

  setUp(() {
    container = GetIt.asNewInstance();
  });

  tearDown(() async {
    await container.reset();
  });

  test(
    'registers dependencies required by the nearby breweries flow',
    () async {
      await configureDependencies(
        container: container,
        config: const AppConfig(mapboxAccessToken: 'pk.test-token'),
      );

      expect(
        container<Dio>().options.baseUrl,
        'https://api.openbrewerydb.org/v1',
      );
      expect(
        container<BreweryRemoteDataSource>(),
        isA<BreweryRemoteDataSource>(),
      );
      expect(container<LocationDataSource>(), isA<LocationDataSource>());
      expect(
        container<MapboxDirectionsRemoteDataSource>(),
        isA<MapboxDirectionsRemoteDataSource>(),
      );
      expect(container<BreweryRepository>(), isA<BreweryRepository>());
      expect(
        container<BreweryRouteRepository>(),
        isA<BreweryRouteRepository>(),
      );
      expect(container<LocationRepository>(), isA<LocationRepository>());
      expect(container<GetNearestBreweries>(), isA<GetNearestBreweries>());
      expect(container<GetBreweryPage>(), isA<GetBreweryPage>());
      expect(container<GetCurrentLocation>(), isA<GetCurrentLocation>());
      expect(container<SearchBreweries>(), isA<SearchBreweries>());
      expect(container<GetBreweryRoute>(), isA<GetBreweryRoute>());
      expect(container<NearbyBreweriesBloc>(), isA<NearbyBreweriesBloc>());
      expect(container<BreweryCatalogBloc>(), isA<BreweryCatalogBloc>());
    },
  );
}
