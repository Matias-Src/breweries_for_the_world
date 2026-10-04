import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';

sealed class NearbyBreweriesState {
  const NearbyBreweriesState();
}

final class NearbyBreweriesInitial extends NearbyBreweriesState {
  const NearbyBreweriesInitial();
}

final class NearbyBreweriesLoading extends NearbyBreweriesState {
  const NearbyBreweriesLoading();
}

final class NearbyBreweriesSuccess extends NearbyBreweriesState {
  const NearbyBreweriesSuccess(
    this.breweries, {
    this.location,
    this.activeTypes = const {},
    this.selectedBreweryId,
  });

  final List<Brewery> breweries;
  final UserLocation? location;
  final Set<String> activeTypes;
  final String? selectedBreweryId;
}

final class NearbyBreweriesEmpty extends NearbyBreweriesState {
  const NearbyBreweriesEmpty({this.location, this.activeTypes = const {}});

  final UserLocation? location;
  final Set<String> activeTypes;
}

final class NearbyBreweriesError extends NearbyBreweriesState {
  const NearbyBreweriesError({required this.exception});

  final Object exception;
}
