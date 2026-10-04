import '../../domain/entities/brewery.dart';

enum BreweryCatalogStatus { initial, loading, success, error }

enum BreweryCatalogSortOrder {
  defaultOrder,
  nameAscending,
  nameDescending,
  cityAscending,
  typeAscending,
}

class BreweryCatalogState {
  const BreweryCatalogState({
    this.status = BreweryCatalogStatus.initial,
    this.breweries = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.activeTypes = const {},
    this.sortOrder = BreweryCatalogSortOrder.defaultOrder,
  });

  final BreweryCatalogStatus status;
  final List<Brewery> breweries;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;
  final String query;
  final Set<String> activeTypes;
  final BreweryCatalogSortOrder sortOrder;

  bool get isLoading => status == BreweryCatalogStatus.loading;

  BreweryCatalogState copyWith({
    BreweryCatalogStatus? status,
    List<Brewery>? breweries,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    Object? error,
    String? query,
    Set<String>? activeTypes,
    BreweryCatalogSortOrder? sortOrder,
    bool clearError = false,
  }) => BreweryCatalogState(
    status: status ?? this.status,
    breweries: breweries ?? this.breweries,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : error ?? this.error,
    query: query ?? this.query,
    activeTypes: activeTypes ?? this.activeTypes,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}
