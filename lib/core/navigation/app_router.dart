import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../settings/app_settings_cubit.dart';
import '../../features/nearby_breweries/domain/entities/brewery.dart';
import '../../features/nearby_breweries/domain/entities/user_location.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import '../../features/nearby_breweries/domain/usecases/get_brewery_route.dart';
import '../../features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import '../../features/nearby_breweries/presentation/bloc/brewery_catalog_event.dart';
import '../../features/nearby_breweries/presentation/bloc/brewery_detail_cubit.dart';
import '../../features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import '../../features/nearby_breweries/presentation/bloc/nearby_breweries_state.dart';
import '../../features/nearby_breweries/presentation/pages/brewery_catalog_page.dart';
import '../../features/nearby_breweries/presentation/pages/brewery_detail_page.dart';
import '../../features/nearby_breweries/presentation/pages/nearby_breweries_map_page.dart';
import '../../features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import '../../features/nearby_breweries/presentation/map/nearby_breweries_map_controller.dart';

abstract final class AppRoutes {
  static const nearby = '/nearby';
  static const catalog = '/breweries';
  static const breweryDetails = 'brewery-details';

  static String breweryDetailsPath(String id) => '/breweries/$id';
}

class BreweryDetailsExtra {
  const BreweryDetailsExtra({this.brewery, this.userLocation});

  final Brewery? brewery;
  final UserLocation? userLocation;
}

class AppRouter {
  AppRouter({
    required BreweryMapAdapter mapAdapter,
    required GetBreweryById getBreweryById,
    required BreweryCatalogBloc Function() createCatalogBloc,
    GetBreweryRoute? getBreweryRoute,
    this.initialLocation = AppRoutes.nearby,
  }) : router = GoRouter(
         initialLocation: initialLocation,
         routes: [
           GoRoute(path: '/', redirect: (_, _) => AppRoutes.nearby),
           GoRoute(
             path: AppRoutes.nearby,
             name: 'nearby',
             builder: (context, _) => NearbyBreweriesMapPage(
               mapAdapter: mapAdapter,
               mapController: NearbyBreweriesMapController(
                 bloc: context.read(),
                 mapAdapter: mapAdapter,
               ),
               settingsCubit: context.read<AppSettingsCubit>(),
               onOpenCatalog: () {
                 final location = switch (context
                     .read<NearbyBreweriesBloc>()
                     .state) {
                   NearbyBreweriesSuccess(:final location) => location,
                   NearbyBreweriesEmpty(:final location) => location,
                   _ => null,
                 };
                 context.pushNamed('catalog', extra: location);
               },
               onOpenBreweryDetails: (brewery, location) => context.pushNamed(
                 AppRoutes.breweryDetails,
                 pathParameters: {'id': brewery.id},
                 extra: BreweryDetailsExtra(
                   brewery: brewery,
                   userLocation: location,
                 ),
               ),
             ),
           ),
           GoRoute(
             path: AppRoutes.catalog,
             name: 'catalog',
             builder: (context, state) {
               final location = state.extra is UserLocation
                   ? state.extra! as UserLocation
                   : null;
               return BlocProvider(
                 create: (_) =>
                     createCatalogBloc()..add(const BreweryCatalogStarted()),
                 child: BreweryCatalogPage(
                   onBrewerySelected: (brewery) => context.pushNamed(
                     AppRoutes.breweryDetails,
                     pathParameters: {'id': brewery.id},
                     extra: BreweryDetailsExtra(userLocation: location),
                   ),
                 ),
               );
             },
           ),
           GoRoute(
             path: '/breweries/:id',
             name: AppRoutes.breweryDetails,
             builder: (context, state) {
               final id = state.pathParameters['id']!;
               final extra = state.extra is BreweryDetailsExtra
                   ? state.extra! as BreweryDetailsExtra
                   : const BreweryDetailsExtra();
               return BlocProvider(
                 create: (_) => BreweryDetailCubit(
                   breweryId: id,
                   getBreweryById: getBreweryById,
                   mapRoute: getBreweryRoute,
                   userLocation: extra.userLocation,
                   initialBrewery: extra.brewery,
                 )..load(),
                 child: BreweryDetailPage(mapAdapter: mapAdapter),
               );
             },
           ),
         ],
         errorBuilder: (context, state) => const _NotFoundPage(),
       );

  final String initialLocation;
  final GoRouter router;

  void dispose() => router.dispose();
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageNotFound)),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.nearby),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.backToNearby),
        ),
      ),
    );
  }
}
