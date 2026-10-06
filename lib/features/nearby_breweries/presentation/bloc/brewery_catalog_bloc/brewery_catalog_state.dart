import '../../../domain/entities/brewery.dart';

enum BreweryCatalogSortOrder {
  defaultOrder,
  nameAscending,
  nameDescending,
  cityAscending,
  typeAscending,
}

sealed class BreweryCatalogState {
  const BreweryCatalogState({
    this.breweries = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.activeTypes = const {},
    this.sortOrder = BreweryCatalogSortOrder.defaultOrder,
  });

  final List<Brewery> breweries;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;
  final String query;
  final Set<String> activeTypes;
  final BreweryCatalogSortOrder sortOrder;

  bool get isLoading => this is BreweryCatalogLoading;
}

final class BreweryCatalogInitial extends BreweryCatalogState {
  const BreweryCatalogInitial();
}

final class BreweryCatalogLoading extends BreweryCatalogState {
  const BreweryCatalogLoading({
    super.breweries,
    super.currentPage,
    super.hasMore,
    super.isLoadingMore,
    super.error,
    super.query,
    super.activeTypes,
    super.sortOrder,
  });
}

final class BreweryCatalogSuccess extends BreweryCatalogState {
  const BreweryCatalogSuccess({
    super.breweries,
    super.currentPage,
    super.hasMore,
    super.isLoadingMore,
    super.query,
    super.activeTypes,
    super.sortOrder,
  });
}

final class BreweryCatalogEmpty extends BreweryCatalogState {
  const BreweryCatalogEmpty({
    super.currentPage,
    super.hasMore,
    super.isLoadingMore,
    super.query,
    super.activeTypes,
    super.sortOrder,
  });
}

final class BreweryCatalogError extends BreweryCatalogState {
  const BreweryCatalogError({
    required super.error,
    super.breweries,
    super.currentPage,
    super.hasMore,
    super.isLoadingMore,
    super.query,
    super.activeTypes,
    super.sortOrder,
  });
}
