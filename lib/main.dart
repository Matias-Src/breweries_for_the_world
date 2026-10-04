import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_startup.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/l10n/app_localizations.dart';
import 'core/navigation/app_router.dart';
import 'core/settings/app_settings_cubit.dart';
import 'features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_event.dart';
import 'features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import 'features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import 'features/nearby_breweries/presentation/map/mapbox_brewery_map_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await bootstrapApp(
    loadConfig: AppConfig.load,
    configureDependencies: (config) => configureDependencies(config: config),
    runApp: () {
      MapboxOptions.setAccessToken(getIt<AppConfig>().mapboxAccessToken);
      final bloc = getIt<NearbyBreweriesBloc>()..add(const LocationRequested());
      final settingsCubit = AppSettingsCubit(preferences);
      final appRouter = AppRouter(
        mapAdapter: MapboxBreweryMapAdapter(),
        getBreweryById: getIt<GetBreweryById>(),
        createCatalogBloc: () => getIt<BreweryCatalogBloc>(),
        getBreweryRoute: getIt<GetBreweryRoute>(),
      );
      runApp(
        MyApp(
          nearbyBreweriesBloc: bloc,
          appSettingsCubit: settingsCubit,
          appRouter: appRouter,
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.nearbyBreweriesBloc,
    required this.appSettingsCubit,
    required this.appRouter,
  });

  final NearbyBreweriesBloc nearbyBreweriesBloc;
  final AppSettingsCubit appSettingsCubit;
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    const mapBlue = Color(0xff8ab4f8);
    const mapSurface = Color(0xff202124);
    const mapElevatedSurface = Color(0xff303134);
    const mapText = Color(0xffe8eaed);
    const mapMutedText = Color(0xffbdc1c6);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: mapBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: mapBlue,
          onPrimary: mapSurface,
          secondary: mapBlue,
          surface: mapSurface,
          onSurface: mapText,
          surfaceContainer: mapSurface,
          surfaceContainerHigh: mapElevatedSurface,
          surfaceContainerHighest: const Color(0xff3c4043),
          onSurfaceVariant: mapMutedText,
        );
    final darkScheme = colorScheme;
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xffa94f18),
      brightness: Brightness.light,
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: nearbyBreweriesBloc),
        BlocProvider.value(value: appSettingsCubit),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        bloc: appSettingsCubit,
        builder: (context, settings) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: lightScheme,
            scaffoldBackgroundColor: const Color(0xfff6f5f1),
            appBarTheme: AppBarTheme(
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
              scrolledUnderElevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            scaffoldBackgroundColor: const Color(0xff17181a),
            appBarTheme: const AppBarTheme(
              backgroundColor: mapSurface,
              foregroundColor: Colors.white,
              scrolledUnderElevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: mapBlue,
              foregroundColor: mapSurface,
            ),
          ),
          routerConfig: appRouter.router,
        ),
      ),
    );
  }
}
