import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/errors/location_unavailable_exception.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_nearest_breweries.dart';
import '../../domain/usecases/search_breweries.dart';
import 'nearby_breweries_event.dart';
import 'nearby_breweries_state.dart';

class NearbyBreweriesBloc
    extends Bloc<NearbyBreweriesEvent, NearbyBreweriesState> {
  NearbyBreweriesBloc({
    required GetNearestBreweries getNearestBreweries,
    GetCurrentLocation? getCurrentLocation,
    SearchBreweries? searchBreweries,
  }) : _getNearestBreweries = getNearestBreweries,
       _getCurrentLocation = getCurrentLocation,
       _searchBreweries = searchBreweries,
       super(const NearbyBreweriesInitial()) {
    on<LocationRequested>(_onLocationRequested);
    on<RetryRequested>(_onRetryRequested);
    on<SearchQueryChanged>(_onSearchQueryChanged, transformer: restartable());
    on<BreweryTypesChanged>(_onBreweryTypesChanged);
    on<FiltersCleared>(_onFiltersCleared);
    on<BrewerySelected>(_onBrewerySelected);
  }

  final GetNearestBreweries _getNearestBreweries;
  final GetCurrentLocation? _getCurrentLocation;
  final SearchBreweries? _searchBreweries;

  static const _searchDebounce = Duration(milliseconds: 300);
  List<Brewery> _nearbyBreweries = const [];
  List<Brewery> _searchResults = const [];
  Set<String> _activeTypes = const {};
  UserLocation? _location;
  bool _searchActive = false;
  bool _hasLoadedResults = false;
  int _searchRequestId = 0;
  String? _selectedBreweryId;

  Future<void> _onLocationRequested(
    LocationRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) => _loadBreweries(event, emit);

  Future<void> _onRetryRequested(
    RetryRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) => _loadBreweries(const LocationRequested(), emit);

  Future<void> _loadBreweries(
    LocationRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    emit(const NearbyBreweriesLoading());
    try {
      final location = await _resolveLocation(event);
      final breweries = await _getNearestBreweries(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _location = location;
      _nearbyBreweries = breweries;
      _searchActive = false;
      _hasLoadedResults = true;
      _emitResults(breweries, emit, location: location);
    } on Exception catch (exception) {
      emit(NearbyBreweriesError(exception: exception));
    }
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    final requestId = ++_searchRequestId;
    final query = event.query.trim();
    if (query.isEmpty) {
      _searchActive = false;
      if (_hasLoadedResults) {
        _emitResults(_nearbyBreweries, emit, location: _location);
      }
      return;
    }

    await Future<void>.delayed(_searchDebounce);
    if (emit.isDone || requestId != _searchRequestId) return;

    final searchBreweries = _searchBreweries;
    if (searchBreweries == null) {
      emit(
        NearbyBreweriesError(
          exception: StateError('A brewery search provider is not configured.'),
        ),
      );
      return;
    }

    emit(const NearbyBreweriesLoading());
    try {
      final breweries = await searchBreweries(query: query);
      if (emit.isDone || requestId != _searchRequestId) return;
      _searchResults = breweries;
      _searchActive = true;
      _hasLoadedResults = true;
      _emitResults(breweries, emit, location: _location);
    } on Exception catch (exception) {
      if (emit.isDone || requestId != _searchRequestId) return;
      emit(NearbyBreweriesError(exception: exception));
    }
  }

  void _onBreweryTypesChanged(
    BreweryTypesChanged event,
    Emitter<NearbyBreweriesState> emit,
  ) {
    _activeTypes = Set.unmodifiable(event.types);
    final selectedBreweryId = _selectedBreweryId;
    if (selectedBreweryId != null && _activeTypes.isNotEmpty) {
      final breweries = _searchActive ? _searchResults : _nearbyBreweries;
      final selectionMatchesFilter = breweries.any(
        (brewery) =>
            brewery.id == selectedBreweryId &&
            _activeTypes.contains(brewery.breweryType),
      );
      if (!selectionMatchesFilter) _selectedBreweryId = null;
    }
    if (_hasLoadedResults) {
      _emitCurrentResults(emit);
    }
  }

  void _onFiltersCleared(
    FiltersCleared event,
    Emitter<NearbyBreweriesState> emit,
  ) {
    _activeTypes = const {};
    if (_hasLoadedResults) {
      _emitCurrentResults(emit);
    }
  }

  void _onBrewerySelected(
    BrewerySelected event,
    Emitter<NearbyBreweriesState> emit,
  ) {
    final breweries = _searchActive ? _searchResults : _nearbyBreweries;
    if (!breweries.any((brewery) => brewery.id == event.breweryId)) return;
    _selectedBreweryId = _selectedBreweryId == event.breweryId
        ? null
        : event.breweryId;
    _emitCurrentResults(emit);
  }

  void _emitCurrentResults(Emitter<NearbyBreweriesState> emit) {
    final breweries = _searchActive ? _searchResults : _nearbyBreweries;
    _emitResults(breweries, emit, location: _location);
  }

  void _emitResults(
    List<Brewery> breweries,
    Emitter<NearbyBreweriesState> emit, {
    required UserLocation? location,
  }) {
    final visibleBreweries = _activeTypes.isEmpty
        ? breweries
        : breweries
              .where((brewery) => _activeTypes.contains(brewery.breweryType))
              .toList(growable: false);
    final activeTypes = Set<String>.unmodifiable(_activeTypes);

    if (visibleBreweries.isEmpty) {
      emit(NearbyBreweriesEmpty(location: location, activeTypes: activeTypes));
    } else {
      emit(
        NearbyBreweriesSuccess(
          visibleBreweries,
          location: location,
          activeTypes: activeTypes,
          selectedBreweryId:
              visibleBreweries.any(
                (brewery) => brewery.id == _selectedBreweryId,
              )
              ? _selectedBreweryId
              : null,
        ),
      );
    }
  }

  Future<UserLocation> _resolveLocation(LocationRequested event) async {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude != null && longitude != null) {
      return UserLocation(latitude: latitude, longitude: longitude);
    }
    if (latitude != null || longitude != null) {
      throw const LocationUnavailableException(
        'Both latitude and longitude are required.',
      );
    }
    if (_getCurrentLocation == null) {
      throw const LocationUnavailableException(
        'A location provider has not been configured.',
      );
    }
    return _getCurrentLocation();
  }
}
