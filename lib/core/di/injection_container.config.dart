// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:breweries_for_the_world/core/config/app_config.dart' as _i183;
import 'package:breweries_for_the_world/core/di/injection_container.dart'
    as _i426;
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/brewery_remote_data_source.dart'
    as _i49;
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/location_data_source.dart'
    as _i225;
import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart'
    as _i172;
import 'package:breweries_for_the_world/features/nearby_breweries/data/repositories/brewery_repository_impl.dart'
    as _i890;
import 'package:breweries_for_the_world/features/nearby_breweries/data/repositories/location_repository_impl.dart'
    as _i392;
import 'package:breweries_for_the_world/features/nearby_breweries/data/repositories/mapbox_directions_repository_impl.dart'
    as _i43;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart'
    as _i457;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_route_repository.dart'
    as _i355;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/location_repository.dart'
    as _i528;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_by_id.dart'
    as _i932;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_page.dart'
    as _i1050;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_route.dart'
    as _i770;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_current_location.dart'
    as _i909;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart'
    as _i915;
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart'
    as _i60;
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart'
    as _i81;
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart'
    as _i664;
import 'package:dio/dio.dart' as _i361;
import 'package:geolocator/geolocator.dart' as _i699;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final externalDependenciesModule = _$ExternalDependenciesModule();
    gh.lazySingleton<_i361.Dio>(() => externalDependenciesModule.dio);
    gh.lazySingleton<_i699.GeolocatorPlatform>(
      () => externalDependenciesModule.geolocatorPlatform,
    );
    gh.lazySingleton<_i172.MapboxDirectionsRemoteDataSource>(
      () => externalDependenciesModule.mapboxDirectionsRemoteDataSource(
        gh<_i361.Dio>(),
        gh<_i183.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i355.BreweryRouteRepository>(
      () => _i43.MapboxDirectionsRepositoryImpl(
        dataSource: gh<_i172.MapboxDirectionsRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i770.GetBreweryRoute>(
      () => _i770.GetBreweryRoute(gh<_i355.BreweryRouteRepository>()),
    );
    gh.lazySingleton<_i49.BreweryRemoteDataSource>(
      () => _i49.BreweryRemoteDataSourceImpl(dio: gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i225.LocationDataSource>(
      () => _i225.LocationDataSourceImpl(
        geolocatorPlatform: gh<_i699.GeolocatorPlatform>(),
      ),
    );
    gh.lazySingleton<_i457.BreweryRepository>(
      () => _i890.BreweryRepositoryImpl(
        remoteDataSource: gh<_i49.BreweryRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i932.GetBreweryById>(
      () => _i932.GetBreweryById(gh<_i457.BreweryRepository>()),
    );
    gh.lazySingleton<_i1050.GetBreweryPage>(
      () => _i1050.GetBreweryPage(gh<_i457.BreweryRepository>()),
    );
    gh.lazySingleton<_i915.GetNearestBreweries>(
      () => _i915.GetNearestBreweries(gh<_i457.BreweryRepository>()),
    );
    gh.lazySingleton<_i60.SearchBreweries>(
      () => _i60.SearchBreweries(gh<_i457.BreweryRepository>()),
    );
    gh.lazySingleton<_i528.LocationRepository>(
      () => _i392.LocationRepositoryImpl(
        dataSource: gh<_i225.LocationDataSource>(),
      ),
    );
    gh.factory<_i81.BreweryCatalogBloc>(
      () => _i81.BreweryCatalogBloc(
        getBreweries: gh<_i1050.GetBreweryPage>(),
        searchBreweries: gh<_i60.SearchBreweries>(),
      ),
    );
    gh.lazySingleton<_i909.GetCurrentLocation>(
      () => _i909.GetCurrentLocation(gh<_i528.LocationRepository>()),
    );
    gh.factory<_i664.NearbyBreweriesBloc>(
      () => _i664.NearbyBreweriesBloc(
        getNearestBreweries: gh<_i915.GetNearestBreweries>(),
        getCurrentLocation: gh<_i909.GetCurrentLocation>(),
        searchBreweries: gh<_i60.SearchBreweries>(),
      ),
    );
    return this;
  }
}

class _$ExternalDependenciesModule extends _i426.ExternalDependenciesModule {}
