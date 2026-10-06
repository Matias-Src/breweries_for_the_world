import 'brewery_catalog_state.dart';

sealed class BreweryCatalogEvent {
  const BreweryCatalogEvent();
}

final class BreweryCatalogStarted extends BreweryCatalogEvent {
  const BreweryCatalogStarted();
}

final class BreweryCatalogNextPageRequested extends BreweryCatalogEvent {
  const BreweryCatalogNextPageRequested();
}

final class BreweryCatalogRetryRequested extends BreweryCatalogEvent {
  const BreweryCatalogRetryRequested();
}

final class BreweryCatalogSearchChanged extends BreweryCatalogEvent {
  const BreweryCatalogSearchChanged(this.query);

  final String query;
}

final class BreweryCatalogTypesChanged extends BreweryCatalogEvent {
  const BreweryCatalogTypesChanged(this.types);

  final Set<String> types;
}

final class BreweryCatalogFiltersCleared extends BreweryCatalogEvent {
  const BreweryCatalogFiltersCleared();
}

final class BreweryCatalogSortChanged extends BreweryCatalogEvent {
  const BreweryCatalogSortChanged(this.sortOrder);

  final BreweryCatalogSortOrder sortOrder;
}
