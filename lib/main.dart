import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_startup.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/navigation/app_router.dart';
import 'core/settings/app_settings_cubit.dart';
import 'core/settings/shared_preferences_app_settings_repository.dart';
import 'features/nearby_breweries/presentation/bloc/brewery_catalog_bloc/brewery_catalog_bloc.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_bloc/nearby_breweries_bloc.dart';
import 'features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import 'features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import 'features/nearby_breweries/domain/services/website_launcher.dart';
import 'features/nearby_breweries/presentation/map/mapbox_brewery_map_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await initializeApp (
    loadConfig: AppConfig.load,
    configureDependencies: (config) => configureDependencies(config: config),
    runApp: () {
      MapboxOptions.setAccessToken(getIt<AppConfig>().mapboxAccessToken);
      final nearbyBreweriesBloc = getIt<NearbyBreweriesBloc>()..add(const LocationRequested());
      final settingsCubit = AppSettingsCubit(
        SharedPreferencesAppSettingsRepository(preferences),
      );
      final appRouter = AppRouter(
        mapAdapter: MapboxBreweryMapAdapter(),
        getBreweryById: getIt<GetBreweryByIdUseCase>(),
        websiteLauncher: getIt<WebsiteLauncher>(),
        createCatalogBloc: () => getIt<BreweryCatalogBloc>(),
        getBreweryRoute: getIt<GetBreweryRouteUseCase>(),
      );
      runApp(
        MyApp(
          nearbyBreweriesBloc: nearbyBreweriesBloc,
          appSettingsCubit: settingsCubit,
          appRouter: appRouter,
        ),
      );
    },
  );
}
