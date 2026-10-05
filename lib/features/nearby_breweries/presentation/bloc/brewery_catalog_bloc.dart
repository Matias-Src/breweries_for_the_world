import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/usecases/get_brewery_page.dart';
import '../../domain/usecases/search_breweries.dart';
import 'brewery_catalog_event.dart';
import 'brewery_catalog_state.dart';

@injectable
class BreweryCatalogBloc
    extends Bloc<BreweryCatalogEvent, BreweryCatalogState> {
  BreweryCatalogBloc({
    required GetBreweryPage getBreweries,
    required SearchBreweries searchBreweries,
    @ignoreParam this.pageSize = 20,
  }) : _getBreweries = getBreweries,
       _searchBreweries = searchBreweries,
       super(const BreweryCatalogState()) {
    on<BreweryCatalogStarted>(_onStarted, transformer: droppable());
    on<BreweryCatalogNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<BreweryCatalogRetryRequested>(_onRetryRequested);
    on<BreweryCatalogSearchChanged>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<BreweryCatalogTypesChanged>(_onTypesChanged);
    on<BreweryCatalogFiltersCleared>(_onFiltersCleared);
    on<BreweryCatalogSortChanged>(_onSortChanged);
  }

  final GetBreweryPage _getBreweries;
  final SearchBreweries _searchBreweries;
  final int pageSize;
  static const _searchDebounce = Duration(milliseconds: 300);

  final List<Brewery> _catalogBreweries = [];
  List<Brewery> _searchResults = const [];
  bool _searchActive = false;
  bool _catalogHasMore = true;

  Future<void> _onStarted(
    BreweryCatalogStarted event,
    Emitter<BreweryCatalogState> emit,
  ) async {
    if (state.currentPage != 0 || state.isLoading) return;
    emit(
      state.copyWith(status: BreweryCatalogStatus.loading, clearError: true),
    );
    await _loadPage(1, emit);
  }

  Future<void> _onNextPageRequested(
    BreweryCatalogNextPageRequested event,
    Emitter<BreweryCatalogState> emit,
  ) async {
    if (_searchActive ||
        !state.hasMore ||
        state.currentPage == 0 ||
        state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    await _loadPage(state.currentPage + 1, emit);
  }

  Future<void> _onRetryRequested(
    BreweryCatalogRetryRequested event,
    Emitter<BreweryCatalogState> emit,
  ) {
    if (state.query.isNotEmpty) {
      return _onSearchChanged(BreweryCatalogSearchChanged(state.query), emit);
    }
    return state.currentPage == 0
        ? _onStarted(const BreweryCatalogStarted(), emit)
        : _onNextPageRequested(const BreweryCatalogNextPageRequested(), emit);
  }

  Future<void> _onSearchChanged(
    BreweryCatalogSearchChanged event,
    Emitter<BreweryCatalogState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      _searchActive = false;
      _searchResults = const [];
      _emitVisibleBreweries(emit, query: '');
      return;
    }

    await Future<void>.delayed(_searchDebounce);
    if (emit.isDone) return;

    _searchActive = true;
    emit(
      state.copyWith(
        status: BreweryCatalogStatus.loading,
        breweries: const [],
        query: query,
        hasMore: false,
        isLoadingMore: false,
        clearError: true,
      ),
    );
    try {
      _searchResults = await _searchBreweries(query: query);
      if (emit.isDone) return;
      _emitVisibleBreweries(emit, query: query);
    } on Exception catch (exception) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: BreweryCatalogStatus.error,
          query: query,
          error: exception,
        ),
      );
    }
  }

  void _onTypesChanged(
    BreweryCatalogTypesChanged event,
    Emitter<BreweryCatalogState> emit,
  ) {
    _emitVisibleBreweries(emit, activeTypes: Set.unmodifiable(event.types));
  }

  void _onFiltersCleared(
    BreweryCatalogFiltersCleared event,
    Emitter<BreweryCatalogState> emit,
  ) {
    _emitVisibleBreweries(emit, activeTypes: const {});
  }

  void _onSortChanged(
    BreweryCatalogSortChanged event,
    Emitter<BreweryCatalogState> emit,
  ) {
    _emitVisibleBreweries(emit, sortOrder: event.sortOrder);
  }

  void _emitVisibleBreweries(
    Emitter<BreweryCatalogState> emit, {
    String? query,
    Set<String>? activeTypes,
    BreweryCatalogSortOrder? sortOrder,
    int? currentPage,
  }) {
    final selectedTypes = activeTypes ?? state.activeTypes;
    final selectedSortOrder = sortOrder ?? state.sortOrder;
    final source = _searchActive ? _searchResults : _catalogBreweries;
    final filtered = source
        .where(
          (brewery) =>
              selectedTypes.isEmpty ||
              selectedTypes.contains(brewery.breweryType),
        )
        .toList();
    _sortBreweries(filtered, selectedSortOrder);
    emit(
      state.copyWith(
        status: BreweryCatalogStatus.success,
        breweries: filtered,
        currentPage: currentPage,
        query: query ?? state.query,
        activeTypes: selectedTypes,
        sortOrder: selectedSortOrder,
        hasMore: _searchActive ? false : _catalogHasMore,
        isLoadingMore: false,
        clearError: true,
      ),
    );
  }

  void _sortBreweries(
    List<Brewery> breweries,
    BreweryCatalogSortOrder sortOrder,
  ) {
    if (sortOrder == BreweryCatalogSortOrder.defaultOrder) return;

    int compareText(String? first, String? second) =>
        (first ?? '').toLowerCase().compareTo((second ?? '').toLowerCase());

    breweries.sort((first, second) {
      final comparison = switch (sortOrder) {
        BreweryCatalogSortOrder.defaultOrder => 0,
        BreweryCatalogSortOrder.nameAscending => compareText(
          first.name,
          second.name,
        ),
        BreweryCatalogSortOrder.nameDescending => compareText(
          second.name,
          first.name,
        ),
        BreweryCatalogSortOrder.cityAscending => compareText(
          first.city,
          second.city,
        ),
        BreweryCatalogSortOrder.typeAscending => compareText(
          first.breweryType,
          second.breweryType,
        ),
      };
      return comparison == 0
          ? compareText(first.name, second.name)
          : comparison;
    });
  }

  Future<void> _loadPage(int page, Emitter<BreweryCatalogState> emit) async {
    try {
      final breweries = await _getBreweries(page: page, perPage: pageSize);
      _catalogBreweries.addAll(breweries);
      _catalogHasMore = breweries.length == pageSize;
      _emitVisibleBreweries(emit, currentPage: page);
    } on Exception catch (exception) {
      emit(
        state.copyWith(
          status: state.currentPage == 0
              ? BreweryCatalogStatus.error
              : BreweryCatalogStatus.success,
          isLoadingMore: false,
          error: exception,
        ),
      );
    }
  }
}
