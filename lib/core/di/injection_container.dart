import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

import '../../features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
import '../../features/nearby_breweries/domain/repositories/brewery_repository.dart';
import '../../features/nearby_breweries/domain/repositories/brewery_route_repository.dart';
import '../../features/nearby_breweries/domain/repositories/location_repository.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import '../../features/nearby_breweries/domain/usecases/get_current_location.dart';
import '../../features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import '../../features/nearby_breweries/domain/usecases/search_breweries.dart';
import '../config/app_config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(ignoreUnregisteredTypes: [AppConfig])
Future<void> configureDependencies({
  GetIt? container,
  required AppConfig config,
}) async {
  final services = container ?? getIt;
  services.registerSingleton<AppConfig>(config);
  services.init();
}

@module
abstract class ExternalDependenciesModule {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'));

  @lazySingleton
  geo.GeolocatorPlatform get geolocatorPlatform =>
      geo.GeolocatorPlatform.instance;

  @lazySingleton
  MapboxDirectionsRemoteDataSource mapboxDirectionsRemoteDataSource(
    Dio dio,
    AppConfig config,
  ) => MapboxDirectionsRemoteDataSourceImpl(
    dio: dio,
    accessToken: config.mapboxAccessToken,
  );
}

@module
abstract class UseCasesModule {
  @lazySingleton
  GetBreweryByIdUseCase getBreweryById(BreweryRepository repository) =>
      GetBreweryByIdUseCase(repository);

  @lazySingleton
  GetBreweryPageUseCase getBreweryPage(BreweryRepository repository) =>
      GetBreweryPageUseCase(repository);

  @lazySingleton
  GetBreweryRouteUseCase getBreweryRoute(BreweryRouteRepository repository) =>
      GetBreweryRouteUseCase(repository);

  @lazySingleton
  GetCurrentLocationUseCase getCurrentLocation(LocationRepository repository) =>
      GetCurrentLocationUseCase(repository);

  @lazySingleton
  GetNearestBreweriesUseCase getNearestBreweries(BreweryRepository repository) =>
      GetNearestBreweriesUseCase(repository);

  @lazySingleton
  SearchBreweriesUseCase searchBreweries(BreweryRepository repository) =>
      SearchBreweriesUseCase(repository);
}
