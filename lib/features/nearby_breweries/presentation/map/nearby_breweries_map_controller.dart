import 'dart:async';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';
import '../bloc/nearby_breweries_bloc.dart';
import '../bloc/nearby_breweries_event.dart';
import '../bloc/nearby_breweries_state.dart';
import 'brewery_map_adapter.dart';

class NearbyBreweriesMapController {
  const NearbyBreweriesMapController({
    required NearbyBreweriesBloc bloc,
    required BreweryMapAdapter mapAdapter,
  }) : _bloc = bloc,
       _mapAdapter = mapAdapter;

  final NearbyBreweriesBloc _bloc;
  final BreweryMapAdapter _mapAdapter;

  void search(String query) => _bloc.add(SearchQueryChanged(query));

  void clearSearch() => _bloc.add(const SearchQueryChanged(''));

  void clearFilters() => _bloc.add(const FiltersCleared());

  void toggleBreweryType(String type, Set<String> activeTypes) {
    final nextTypes = Set<String>.of(activeTypes);
    if (!nextTypes.add(type)) nextTypes.remove(type);
    applyBreweryTypeFilter(nextTypes);
  }

  void onMarkerSelected(List<Brewery> breweries, String breweryId) {
    final index = breweries.indexWhere((brewery) => brewery.id == breweryId);
    if (index < 0) return;
    selectBrewery(breweries[index], recenterMap: false);
  }

  void selectBrewery(Brewery brewery, {bool recenterMap = true}) {
    final currentState = _bloc.state;
    final isDeselecting =
        currentState is NearbyBreweriesSuccess &&
        currentState.selectedBreweryId == brewery.id;
    _bloc.add(BrewerySelected(brewery.id));
    if (!recenterMap) return;
    if (isDeselecting) {
      recenterOnUserLocation(currentState);
      return;
    }
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    if (latitude == null ||
        longitude == null ||
        !_isValidCoordinates(latitude, longitude)) {
      return;
    }
    unawaited(
      _mapAdapter.recenter(
        UserLocation(latitude: latitude, longitude: longitude),
      ),
    );
  }

  void applyBreweryTypeFilter(Set<String> types) {
    final currentState = _bloc.state;
    if (currentState is NearbyBreweriesSuccess) {
      final selectedBreweryId = currentState.selectedBreweryId;
      final selectionMatchesFilter = currentState.breweries.any(
        (brewery) =>
            brewery.id == selectedBreweryId &&
            types.contains(brewery.breweryType),
      );
      if (selectedBreweryId != null &&
          types.isNotEmpty &&
          !selectionMatchesFilter) {
        recenterOnUserLocation(currentState);
      }
    }
    _bloc.add(BreweryTypesChanged(types));
  }

  void recenterOnUserLocation(NearbyBreweriesState state) {
    final location = switch (state) {
      NearbyBreweriesSuccess(:final location) => location,
      NearbyBreweriesEmpty(:final location) => location,
      _ => null,
    };
    if (location != null && _isValidLocation(location)) {
      unawaited(_mapAdapter.recenter(location));
    }
  }

  void recenter(UserLocation location) {
    if (_isValidLocation(location)) {
      unawaited(_mapAdapter.recenter(location));
    }
  }
}

bool _isValidLocation(UserLocation location) =>
    _isValidCoordinates(location.latitude, location.longitude);

bool _isValidCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;
