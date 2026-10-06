import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/brewery.dart';
import '../../../domain/entities/brewery_route.dart';
import '../../../domain/entities/route_mode.dart';
import '../../../domain/entities/user_location.dart';
import '../../../domain/errors/brewery_not_found_exception.dart';
import '../../../domain/usecases/get_brewery_by_id.dart';
import '../../../domain/usecases/get_brewery_route.dart';
import '../../../domain/services/website_launcher.dart';

part 'brewery_detail_state.dart';

class BreweryDetailCubit extends Cubit<BreweryDetailState> {
  BreweryDetailCubit({
    required this.breweryId,
    required GetBreweryById getBreweryById,
    required this.mapRoute,
    required WebsiteLauncher websiteLauncher,
    this.userLocation,
    Brewery? initialBrewery,
  }) : _getBreweryById = getBreweryById,
       _websiteLauncher = websiteLauncher,
       super(
         initialBrewery == null
             ? const BreweryDetailLoading()
             : BreweryDetailSuccess(brewery: initialBrewery),
       );

  final String breweryId;
  final GetBreweryById _getBreweryById;
  final GetBreweryRoute? mapRoute;
  final WebsiteLauncher _websiteLauncher;
  final UserLocation? userLocation;
  int _routeRequestId = 0;

  bool canRequestRoute(Brewery brewery) {
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    final location = userLocation;
    return mapRoute != null &&
        location != null &&
        location.isValid &&
        latitude != null &&
        longitude != null &&
        UserLocation.areCoordinatesValid(latitude, longitude);
  }

  Future<void> load() async {
    if (state is BreweryDetailSuccess) {
      await requestRoute(state.selectedMode);
      return;
    }

    final selectedMode = state.selectedMode;
    emit(BreweryDetailLoading(selectedMode: selectedMode));
    try {
      final brewery = await _getBreweryById(id: breweryId);
      if (isClosed) return;
      emit(BreweryDetailSuccess(brewery: brewery, selectedMode: selectedMode));
      await requestRoute(selectedMode);
    } on BreweryNotFoundException catch (exception) {
      if (isClosed) return;
      emit(
        BreweryDetailEmpty(
          breweryId: exception.breweryId,
          selectedMode: selectedMode,
        ),
      );
    } on Exception catch (exception) {
      if (isClosed) return;
      emit(
        BreweryDetailError(
          breweryId: breweryId,
          error: exception,
          selectedMode: selectedMode,
        ),
      );
    }
  }

  Future<void> selectMode(RouteMode mode) => requestRoute(mode);

  Future<void> retryRoute() => requestRoute(state.selectedMode);

  Future<void> requestRoute(RouteMode mode) async {
    final currentState = state;
    if (currentState is! BreweryDetailSuccess) return;
    final brewery = currentState.brewery;
    final origin = userLocation;
    final getRoute = mapRoute;
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    if (origin == null ||
        getRoute == null ||
        latitude == null ||
        longitude == null ||
        !canRequestRoute(brewery)) {
      return;
    }

    final requestId = ++_routeRequestId;
    emit(
      currentState.copyWith(
        selectedMode: mode,
        clearRoute: true,
        clearRouteError: true,
        isLoadingRoute: true,
      ),
    );
    try {
      final route = await getRoute(
        origin: origin,
        destination: UserLocation(latitude: latitude, longitude: longitude),
        mode: mode,
      );
      if (isClosed || requestId != _routeRequestId) return;
      final latestState = state;
      if (latestState is! BreweryDetailSuccess) return;
      emit(latestState.copyWith(route: route, isLoadingRoute: false));
    } on Exception catch (exception) {
      if (isClosed || requestId != _routeRequestId) return;
      final latestState = state;
      if (latestState is! BreweryDetailSuccess) return;
      emit(latestState.copyWith(routeError: exception, isLoadingRoute: false));
    }
  }

  Future<void> openWebsite(String websiteUrl) async {
    final trimmedUrl = websiteUrl.trim();
    final parsedUrl = Uri.tryParse(trimmedUrl);
    final uri = parsedUrl != null && parsedUrl.hasScheme
        ? parsedUrl
        : Uri.tryParse('https://$trimmedUrl');
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      return;
    }
    await _websiteLauncher.launch(uri);
  }
}
