import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/route_mode.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/get_brewery_by_id.dart';
import '../../domain/usecases/get_brewery_route.dart';

enum BreweryDetailStatus { loading, success, error }

class BreweryDetailState {
  const BreweryDetailState({
    required this.status,
    this.brewery,
    this.error,
    this.selectedMode = RouteMode.walking,
    this.route,
    this.routeError,
    this.isLoadingRoute = false,
  });

  final BreweryDetailStatus status;
  final Brewery? brewery;
  final Object? error;
  final RouteMode selectedMode;
  final BreweryRoute? route;
  final Object? routeError;
  final bool isLoadingRoute;

  BreweryDetailState copyWith({
    BreweryDetailStatus? status,
    Brewery? brewery,
    Object? error,
    bool clearError = false,
    RouteMode? selectedMode,
    BreweryRoute? route,
    bool clearRoute = false,
    Object? routeError,
    bool clearRouteError = false,
    bool? isLoadingRoute,
  }) => BreweryDetailState(
    status: status ?? this.status,
    brewery: brewery ?? this.brewery,
    error: clearError ? null : error ?? this.error,
    selectedMode: selectedMode ?? this.selectedMode,
    route: clearRoute ? null : route ?? this.route,
    routeError: clearRouteError ? null : routeError ?? this.routeError,
    isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
  );
}

class BreweryDetailCubit extends Cubit<BreweryDetailState> {
  BreweryDetailCubit({
    required this.breweryId,
    required GetBreweryById getBreweryById,
    required this.mapRoute,
    this.userLocation,
    Brewery? initialBrewery,
  }) : _getBreweryById = getBreweryById,
       super(
         BreweryDetailState(
           status: initialBrewery == null
               ? BreweryDetailStatus.loading
               : BreweryDetailStatus.success,
           brewery: initialBrewery,
         ),
       );

  final String breweryId;
  final GetBreweryById _getBreweryById;
  final GetBreweryRoute? mapRoute;
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
    if (state.brewery != null) {
      await requestRoute(state.selectedMode);
      return;
    }

    emit(state.copyWith(status: BreweryDetailStatus.loading, clearError: true));
    try {
      final brewery = await _getBreweryById(id: breweryId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: BreweryDetailStatus.success,
          brewery: brewery,
          clearError: true,
        ),
      );
      await requestRoute(state.selectedMode);
    } on Exception catch (exception) {
      if (isClosed) return;
      emit(state.copyWith(status: BreweryDetailStatus.error, error: exception));
    }
  }

  Future<void> selectMode(RouteMode mode) => requestRoute(mode);

  Future<void> retryRoute() => requestRoute(state.selectedMode);

  Future<void> requestRoute(RouteMode mode) async {
    final brewery = state.brewery;
    final origin = userLocation;
    final getRoute = mapRoute;
    final latitude = brewery?.latitude;
    final longitude = brewery?.longitude;
    if (brewery == null ||
        origin == null ||
        getRoute == null ||
        latitude == null ||
        longitude == null ||
        !canRequestRoute(brewery)) {
      return;
    }

    final requestId = ++_routeRequestId;
    emit(
      state.copyWith(
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
      emit(state.copyWith(route: route, isLoadingRoute: false));
    } on Exception catch (exception) {
      if (isClosed || requestId != _routeRequestId) return;
      emit(state.copyWith(routeError: exception, isLoadingRoute: false));
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
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
