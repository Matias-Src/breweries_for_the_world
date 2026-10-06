import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/brewery.dart';
import '../../../domain/entities/user_location.dart';
import '../../../domain/errors/location_unavailable_exception.dart';
import '../../../domain/usecases/get_current_location.dart';
import '../../../domain/usecases/get_nearest_breweries.dart';
import '../../../domain/usecases/search_breweries.dart';
part 'nearby_breweries_event.dart';
part 'nearby_breweries_state.dart';

@injectable
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
    on<LocationRefreshRequested>(
      _onLocationRefreshRequested,
      transformer: droppable(),
    );
    on<RetryRequested>(_onRetryRequested);
    on<NearbyBreweriesNextPageRequested>(_onNextPageRequested);
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
  int _nearbyPage = 0;
  bool _hasMoreNearby = true;
  bool _isLoadingNextPage = false;
  bool _nextPageFailed = false;
  int _searchRequestId = 0;
  String? _selectedBreweryId;
  String? _activeSearchQuery;
  LocationRequested? _lastLocationRequest;
  bool _isRefreshingLocation = false;
  Object? _locationRefreshError;

  Future<void> _onLocationRequested(
    LocationRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) {
    _lastLocationRequest = event;
    _activeSearchQuery = null;
    return _loadBreweries(event, emit);
  }

  Future<void> _onLocationRefreshRequested(
    LocationRefreshRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    final getCurrentLocation = _getCurrentLocation;
    if (getCurrentLocation == null) {
      _locationRefreshError = const LocationUnavailableException(
        'A location provider has not been configured.',
      );
      _emitCurrentResults(emit);
      return;
    }

    _isRefreshingLocation = true;
    _locationRefreshError = null;
    _emitCurrentResults(emit);
    try {
      final location = await getCurrentLocation();
      if (!location.isValid) throw const LocationUnavailableException();
      _location = location;
      _isRefreshingLocation = false;
      _emitCurrentResults(emit);
    } on Exception catch (exception) {
      _isRefreshingLocation = false;
      _locationRefreshError = exception;
      _emitCurrentResults(emit);
    }
  }

  Future<void> _onRetryRequested(
    RetryRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) {
    final query = _activeSearchQuery;
    if (query != null) {
      return _onSearchQueryChanged(SearchQueryChanged(query), emit);
    }
    if (_nextPageFailed) {
      return _onNextPageRequested(
        const NearbyBreweriesNextPageRequested(),
        emit,
      );
    }
    return _loadBreweries(
      _lastLocationRequest ?? const LocationRequested(),
      emit,
    );
  }

  Future<void> _loadBreweries(
    LocationRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    _emitLoading(emit);
    try {
      final location = await _resolveLocation(event);
      final breweries = await _getNearestBreweries(
        latitude: location.latitude,
        longitude: location.longitude,
        page: 1,
      );
      _location = location;
      _nearbyBreweries = breweries;
      _nearbyPage = 1;
      _hasMoreNearby = breweries.length == 40;
      _isLoadingNextPage = false;
      _nextPageFailed = false;
      _searchActive = false;
      _activeSearchQuery = null;
      _hasLoadedResults = true;
      _emitResults(breweries, emit, location: location);
    } on Exception catch (exception) {
      _emitError(exception, emit);
    }
  }

  Future<void> _onNextPageRequested(
    NearbyBreweriesNextPageRequested event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    final location = _location;
    if (_searchActive ||
        _activeSearchQuery != null ||
        location == null ||
        !_hasLoadedResults ||
        !_hasMoreNearby ||
        _isLoadingNextPage ||
        _nearbyPage == 0) {
      return;
    }

    _isLoadingNextPage = true;
    _emitLoading(emit);
    try {
      final nextPage = _nearbyPage + 1;
      final breweries = await _getNearestBreweries(
        latitude: location.latitude,
        longitude: location.longitude,
        page: nextPage,
      );
      _nearbyPage = nextPage;
      _hasMoreNearby = breweries.length == 40;
      _nearbyBreweries = [
        ..._nearbyBreweries,
        ...breweries.where(
          (brewery) =>
              !_nearbyBreweries.any((existing) => existing.id == brewery.id),
        ),
      ];
      _nextPageFailed = false;
      _emitResults(_nearbyBreweries, emit, location: location);
    } on Exception catch (exception) {
      _nextPageFailed = true;
      _emitError(exception, emit);
    } finally {
      _isLoadingNextPage = false;
    }
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<NearbyBreweriesState> emit,
  ) async {
    final requestId = ++_searchRequestId;
    final query = event.query.trim();
    if (query.isEmpty) {
      _activeSearchQuery = null;
      _searchActive = false;
      if (_hasLoadedResults) {
        _emitResults(_nearbyBreweries, emit, location: _location);
      }
      return;
    }
    _activeSearchQuery = query;

    await Future<void>.delayed(_searchDebounce);
    if (emit.isDone || requestId != _searchRequestId) return;

    final searchBreweries = _searchBreweries;
    if (searchBreweries == null) {
      emit(
        NearbyBreweriesError(
          exception: StateError('A brewery search provider is not configured.'),
          isSearchError: true,
          breweries: _visibleBreweries(_currentBreweries),
          location: _location,
          activeTypes: Set.unmodifiable(_activeTypes),
          selectedBreweryId: _selectedBreweryId,
          isRefreshingLocation: _isRefreshingLocation,
          locationRefreshError: _locationRefreshError,
        ),
      );
      return;
    }

    _emitLoading(emit);
    try {
      final breweries = await searchBreweries(query: query);
      if (emit.isDone || requestId != _searchRequestId) return;
      _searchResults = breweries;
      _searchActive = true;
      _hasLoadedResults = true;
      _emitResults(breweries, emit, location: _location);
    } on Exception catch (exception) {
      if (emit.isDone || requestId != _searchRequestId) return;
      _emitError(exception, emit, isSearchError: true);
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
    final visibleBreweries = _visibleBreweries(breweries);
    final activeTypes = Set<String>.unmodifiable(_activeTypes);

    if (visibleBreweries.isEmpty) {
      emit(
        NearbyBreweriesEmpty(
          location: location,
          activeTypes: activeTypes,
          isRefreshingLocation: _isRefreshingLocation,
          locationRefreshError: _locationRefreshError,
        ),
      );
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
          isRefreshingLocation: _isRefreshingLocation,
          locationRefreshError: _locationRefreshError,
        ),
      );
    }
  }

  NearbyBreweriesLoading _loadingState() => NearbyBreweriesLoading(
    breweries: _visibleBreweries(_currentBreweries),
    location: _location,
    activeTypes: Set.unmodifiable(_activeTypes),
    selectedBreweryId: _selectedBreweryId,
    isRefreshingLocation: _isRefreshingLocation,
    locationRefreshError: _locationRefreshError,
  );

  void _emitLoading(Emitter<NearbyBreweriesState> emit) {
    if (state is NearbyBreweriesLoading) return;
    emit(_loadingState());
  }

  List<Brewery> _visibleBreweries(List<Brewery> breweries) => List.unmodifiable(
    _activeTypes.isEmpty
        ? breweries
        : breweries.where(
            (brewery) => _activeTypes.contains(brewery.breweryType),
          ),
  );

  List<Brewery> get _currentBreweries =>
      _searchActive ? _searchResults : _nearbyBreweries;

  void _emitError(
    Exception exception,
    Emitter<NearbyBreweriesState> emit, {
    bool isSearchError = false,
  }) {
    emit(
      NearbyBreweriesError(
        exception: exception,
        isSearchError: isSearchError,
        breweries: _visibleBreweries(_currentBreweries),
        location: _location,
        activeTypes: Set.unmodifiable(_activeTypes),
        selectedBreweryId: _selectedBreweryId,
        isRefreshingLocation: _isRefreshingLocation,
        locationRefreshError: _locationRefreshError,
      ),
    );
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
