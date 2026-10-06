part of 'brewery_detail_cubit.dart';

sealed class BreweryDetailState {
  const BreweryDetailState({
    this.selectedMode = RouteMode.walking,
    this.route,
    this.routeError,
    this.isLoadingRoute = false,
  });

  final RouteMode selectedMode;
  final BreweryRoute? route;
  final Object? routeError;
  final bool isLoadingRoute;

  Brewery? get brewery => null;
  String? get breweryId => null;
  Object? get error => null;
}

final class BreweryDetailLoading extends BreweryDetailState {
  const BreweryDetailLoading({super.selectedMode});
}

final class BreweryDetailSuccess extends BreweryDetailState {
  const BreweryDetailSuccess({
    required this.brewery,
    super.selectedMode,
    super.route,
    super.routeError,
    super.isLoadingRoute,
  });

  @override
  final Brewery brewery;

  BreweryDetailSuccess copyWith({
    RouteMode? selectedMode,
    BreweryRoute? route,
    bool clearRoute = false,
    Object? routeError,
    bool clearRouteError = false,
    bool? isLoadingRoute,
  }) => BreweryDetailSuccess(
    brewery: brewery,
    selectedMode: selectedMode ?? this.selectedMode,
    route: clearRoute ? null : route ?? this.route,
    routeError: clearRouteError ? null : routeError ?? this.routeError,
    isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
  );
}

final class BreweryDetailEmpty extends BreweryDetailState {
  const BreweryDetailEmpty({required this.breweryId, super.selectedMode});

  @override
  final String breweryId;
}

final class BreweryDetailError extends BreweryDetailState {
  const BreweryDetailError({
    required this.breweryId,
    required this.error,
    super.selectedMode,
  });

  @override
  final String breweryId;

  @override
  final Object error;
}