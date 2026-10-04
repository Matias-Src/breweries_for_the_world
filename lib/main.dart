import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/app_startup.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_event.dart';
import 'features/nearby_breweries/presentation/bloc/nearby_breweries_state.dart';
import 'features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import 'features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import 'features/nearby_breweries/presentation/map/mapbox_brewery_map_adapter.dart';
import 'features/nearby_breweries/presentation/pages/nearby_breweries_map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApp(
    loadConfig: AppConfig.load,
    configureDependencies: (config) => configureDependencies(config: config),
    runApp: () {
      MapboxOptions.setAccessToken(getIt<AppConfig>().mapboxAccessToken);
      final bloc = getIt<NearbyBreweriesBloc>()..add(const LocationRequested());
      final getBreweryRoute = getIt<GetBreweryRoute>();
      runApp(
        MyApp(
          nearbyBreweriesBloc: bloc,
          mapAdapter: MapboxBreweryMapAdapter(),
          getBreweryRoute: getBreweryRoute,
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.nearbyBreweriesBloc,
    this.mapAdapter,
    this.getBreweryRoute,
  });

  final NearbyBreweriesBloc nearbyBreweriesBloc;
  final BreweryMapAdapter? mapAdapter;
  final GetBreweryRoute? getBreweryRoute;

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
    return MaterialApp(
      title: 'Breweries For The World',
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: colorScheme,
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
      home: BlocProvider.value(
        value: nearbyBreweriesBloc,
        child: mapAdapter == null
            ? const NearbyBreweriesStartupPage()
            : NearbyBreweriesMapPage(
                mapAdapter: mapAdapter!,
                getBreweryRoute: getBreweryRoute,
              ),
      ),
    );
  }
}

class NearbyBreweriesStartupPage extends StatelessWidget {
  const NearbyBreweriesStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby breweries')),
      body: BlocBuilder<NearbyBreweriesBloc, NearbyBreweriesState>(
        builder: (context, state) => switch (state) {
          NearbyBreweriesInitial() => const Center(
            child: CircularProgressIndicator(),
          ),
          NearbyBreweriesLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          NearbyBreweriesSuccess(:final breweries) => ListView.builder(
            itemCount: breweries.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(breweries[index].name),
              subtitle: Text(breweries[index].breweryType),
            ),
          ),
          NearbyBreweriesEmpty() => const Center(
            child: Text('No nearby breweries found'),
          ),
          NearbyBreweriesError(:final exception) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(exception.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.read<NearbyBreweriesBloc>().add(
                    const RetryRequested(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
