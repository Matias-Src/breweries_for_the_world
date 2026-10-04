sealed class NearbyBreweriesEvent {
  const NearbyBreweriesEvent();
}

final class LocationRequested extends NearbyBreweriesEvent {
  const LocationRequested({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;
}

final class LocationRefreshRequested extends NearbyBreweriesEvent {
  const LocationRefreshRequested();
}

final class RetryRequested extends NearbyBreweriesEvent {
  const RetryRequested();
}

final class NearbyBreweriesNextPageRequested extends NearbyBreweriesEvent {
  const NearbyBreweriesNextPageRequested();
}

final class SearchQueryChanged extends NearbyBreweriesEvent {
  const SearchQueryChanged(this.query);

  final String query;
}

final class BreweryTypesChanged extends NearbyBreweriesEvent {
  const BreweryTypesChanged(this.types);

  final Set<String> types;
}

final class FiltersCleared extends NearbyBreweriesEvent {
  const FiltersCleared();
}

final class BrewerySelected extends NearbyBreweriesEvent {
  const BrewerySelected(this.breweryId);

  final String breweryId;
}
