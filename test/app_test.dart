import 'package:breweries_for_the_world/app.dart';
import 'package:breweries_for_the_world/core/navigation/app_router.dart';
import 'package:breweries_for_the_world/core/settings/app_settings_cubit.dart';
import 'package:breweries_for_the_world/core/settings/app_settings_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc/nearby_breweries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('MyApp builds its localized router with injected blocs', (
    tester,
  ) async {
    final repository = _AppTestBreweryRepository();
    final nearbyBreweriesBloc = NearbyBreweriesBloc(
      getNearestBreweries: GetNearestBreweriesUseCase(repository),
    );
    final appSettingsCubit = AppSettingsCubit(_AppTestSettingsRepository());
    final appRouter = _AppTestRouter();
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(
      MyApp(
        nearbyBreweriesBloc: nearbyBreweriesBloc,
        appSettingsCubit: appSettingsCubit,
        appRouter: appRouter,
      ),
    );
    await tester.pump();

    expect(find.text('App root mounted'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _AppTestSettingsRepository implements AppSettingsRepository {
  @override
  ThemeMode get themeMode => ThemeMode.dark;

  @override
  Locale get locale => const Locale('en');

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {}

  @override
  Future<void> saveLocale(Locale locale) async {}
}

class _AppTestBreweryRepository implements BreweryRepository {
  @override
  Future<Brewery> getBreweryById({required String id}) async =>
      const Brewery(id: 'test', name: 'Test Brewery', breweryType: 'micro');

  @override
  Future<List<Brewery>> getBreweries({
    required int page,
    int perPage = 20,
  }) async => [];

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

class _AppTestRouter implements AppRouter {
  _AppTestRouter()
    : router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('App root mounted')),
          ),
        ],
      );

  @override
  final String initialLocation = '/';

  @override
  final GoRouter router;

  @override
  void dispose() => router.dispose();
}
