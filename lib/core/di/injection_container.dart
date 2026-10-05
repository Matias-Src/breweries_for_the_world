import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

import '../../features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
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
