import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';

sealed class NearbyBreweriesState {
  const NearbyBreweriesState({
    this.breweries = const [],
    this.location,
    this.activeTypes = const {},
    this.selectedBreweryId,
  });

  final List<Brewery> breweries;
  final UserLocation? location;
  final Set<String> activeTypes;
  final String? selectedBreweryId;
}

final class NearbyBreweriesInitial extends NearbyBreweriesState {
  const NearbyBreweriesInitial();
}

final class NearbyBreweriesLoading extends NearbyBreweriesState {
  const NearbyBreweriesLoading({
    super.breweries,
    super.location,
    super.activeTypes,
    super.selectedBreweryId,
  });
}

final class NearbyBreweriesSuccess extends NearbyBreweriesState {
  const NearbyBreweriesSuccess(
    List<Brewery> breweries, {
    super.location,
    super.activeTypes = const {},
    super.selectedBreweryId,
  }) : super(breweries: breweries);
}

final class NearbyBreweriesEmpty extends NearbyBreweriesState {
  const NearbyBreweriesEmpty({super.location, super.activeTypes});
}

final class NearbyBreweriesError extends NearbyBreweriesState {
  const NearbyBreweriesError({
    required this.exception,
    this.isSearchError = false,
    super.breweries,
    super.location,
    super.activeTypes,
    super.selectedBreweryId,
  });

  final Object exception;
  final bool isSearchError;
}
