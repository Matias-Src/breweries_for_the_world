import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get_it/get_it.dart';

import '../../features/nearby_breweries/data/datasources/brewery_remote_data_source.dart';
import '../../features/nearby_breweries/data/datasources/location_data_source.dart';
import '../../features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
import '../../features/nearby_breweries/data/repositories/brewery_repository_impl.dart';
import '../../features/nearby_breweries/data/repositories/mapbox_directions_repository_impl.dart';
import '../../features/nearby_breweries/data/repositories/location_repository_impl.dart';
import '../../features/nearby_breweries/domain/repositories/brewery_route_repository.dart';
import '../../features/nearby_breweries/domain/repositories/brewery_repository.dart';
import '../../features/nearby_breweries/domain/repositories/location_repository.dart';
import '../../features/nearby_breweries/domain/usecases/get_current_location.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import '../../features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import '../../features/nearby_breweries/domain/usecases/search_breweries.dart';
import '../../features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import '../../features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import '../config/app_config.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  GetIt? container,
  required AppConfig config,
}) async {
  final services = container ?? getIt;

  services.registerSingleton<AppConfig>(config);
  services.registerLazySingleton<Dio>(
    () => Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1')),
  );
  services.registerLazySingleton<BreweryRemoteDataSource>(
    () => BreweryRemoteDataSourceImpl(dio: services<Dio>()),
  );
  services.registerLazySingleton<MapboxDirectionsRemoteDataSource>(
    () => MapboxDirectionsRemoteDataSourceImpl(
      dio: services<Dio>(),
      accessToken: config.mapboxAccessToken,
    ),
  );
  services.registerLazySingleton<LocationDataSource>(
    () => LocationDataSourceImpl(
      geolocatorPlatform: geo.GeolocatorPlatform.instance,
    ),
  );
  services.registerLazySingleton<BreweryRepository>(
    () => BreweryRepositoryImpl(
      remoteDataSource: services<BreweryRemoteDataSource>(),
    ),
  );
  services.registerLazySingleton<BreweryRouteRepository>(
    () => MapboxDirectionsRepositoryImpl(
      dataSource: services<MapboxDirectionsRemoteDataSource>(),
    ),
  );
  services.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(dataSource: services<LocationDataSource>()),
  );
  services.registerLazySingleton<GetNearestBreweries>(
    () => GetNearestBreweries(services<BreweryRepository>()),
  );
  services.registerLazySingleton<GetBreweryPage>(
    () => GetBreweryPage(services<BreweryRepository>()),
  );
  services.registerLazySingleton<GetBreweryById>(
    () => GetBreweryById(services<BreweryRepository>()),
  );
  services.registerLazySingleton<GetCurrentLocation>(
    () => GetCurrentLocation(services<LocationRepository>()),
  );
  services.registerLazySingleton<SearchBreweries>(
    () => SearchBreweries(services<BreweryRepository>()),
  );
  services.registerLazySingleton<GetBreweryRoute>(
    () => GetBreweryRoute(services<BreweryRouteRepository>()),
  );
  services.registerFactory<NearbyBreweriesBloc>(
    () => NearbyBreweriesBloc(
      getNearestBreweries: services<GetNearestBreweries>(),
      getCurrentLocation: services<GetCurrentLocation>(),
      searchBreweries: services<SearchBreweries>(),
    ),
  );
  services.registerFactory<BreweryCatalogBloc>(
    () => BreweryCatalogBloc(
      getBreweries: services<GetBreweryPage>(),
      searchBreweries: services<SearchBreweries>(),
    ),
  );
}
