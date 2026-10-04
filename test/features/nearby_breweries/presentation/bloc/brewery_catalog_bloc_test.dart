import 'package:bloc_test/bloc_test.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_page.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_event.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreweryRepository extends Mock implements BreweryRepository {}

void main() {
  late _MockBreweryRepository repository;

  const firstPageBreweries = [
    Brewery(id: 'one', name: 'One', breweryType: 'micro'),
    Brewery(id: 'two', name: 'Two', breweryType: 'brewpub'),
  ];
  const secondPageBreweries = [
    Brewery(id: 'three', name: 'Three', breweryType: 'regional'),
  ];

  setUp(() {
    repository = _MockBreweryRepository();
  });

  blocTest<BreweryCatalogBloc, BreweryCatalogState>(
    'loads the first page and marks a short page as the end of the catalog',
    setUp: () {
      when(
        () => repository.getBreweries(page: 1, perPage: 2),
      ).thenAnswer((_) async => firstPageBreweries);
    },
    build: () => BreweryCatalogBloc(
      getBreweries: GetBreweryPage(repository),
      searchBreweries: SearchBreweries(repository),
      pageSize: 2,
    ),
    act: (bloc) => bloc.add(const BreweryCatalogStarted()),
    expect: () => [
      isA<BreweryCatalogState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<BreweryCatalogState>()
          .having((state) => state.breweries, 'first page', firstPageBreweries)
          .having((state) => state.currentPage, 'page', 1)
          .having((state) => state.hasMore, 'has more pages', true),
    ],
    verify: (_) =>
        verify(() => repository.getBreweries(page: 1, perPage: 2)).called(1),
  );

  blocTest<BreweryCatalogBloc, BreweryCatalogState>(
    'appends the next page and stops when that page is short',
    setUp: () {
      when(
        () => repository.getBreweries(page: 1, perPage: 2),
      ).thenAnswer((_) async => firstPageBreweries);
      when(
        () => repository.getBreweries(page: 2, perPage: 2),
      ).thenAnswer((_) async => secondPageBreweries);
    },
    build: () => BreweryCatalogBloc(
      getBreweries: GetBreweryPage(repository),
      searchBreweries: SearchBreweries(repository),
      pageSize: 2,
    ),
    act: (bloc) async {
      bloc.add(const BreweryCatalogStarted());
      await bloc.stream.firstWhere((state) => state.currentPage == 1);
      bloc.add(const BreweryCatalogNextPageRequested());
    },
    expect: () => [
      isA<BreweryCatalogState>().having(
        (state) => state.isLoading,
        'initial loading',
        true,
      ),
      isA<BreweryCatalogState>()
          .having((state) => state.breweries, 'first page', firstPageBreweries)
          .having((state) => state.currentPage, 'first page number', 1),
      isA<BreweryCatalogState>().having(
        (state) => state.isLoadingMore,
        'loading next page',
        true,
      ),
      isA<BreweryCatalogState>()
          .having((state) => state.breweries, 'all breweries', [
            ...firstPageBreweries,
            ...secondPageBreweries,
          ])
          .having((state) => state.currentPage, 'page', 2)
          .having((state) => state.hasMore, 'has more pages', false)
          .having((state) => state.isLoadingMore, 'loading more', false),
    ],
  );

  blocTest<BreweryCatalogBloc, BreweryCatalogState>(
    'filters by multiple types and sorts the visible catalog by name',
    setUp: () {
      when(() => repository.getBreweries(page: 1, perPage: 4)).thenAnswer(
        (_) async => const [
          Brewery(id: 'z', name: 'Zulu', breweryType: 'micro'),
          Brewery(id: 'a', name: 'Alpha', breweryType: 'brewpub'),
          Brewery(id: 'b', name: 'Bravo', breweryType: 'micro'),
          Brewery(id: 'c', name: 'Charlie', breweryType: 'closed'),
        ],
      );
    },
    build: () => BreweryCatalogBloc(
      getBreweries: GetBreweryPage(repository),
      searchBreweries: SearchBreweries(repository),
      pageSize: 4,
    ),
    act: (bloc) async {
      bloc.add(const BreweryCatalogStarted());
      await bloc.stream.firstWhere((state) => state.currentPage == 1);
      bloc.add(const BreweryCatalogTypesChanged({'micro', 'brewpub'}));
      await bloc.stream.firstWhere((state) => state.activeTypes.isNotEmpty);
      bloc.add(
        const BreweryCatalogSortChanged(BreweryCatalogSortOrder.nameAscending),
      );
      await bloc.stream.firstWhere(
        (state) => state.sortOrder == BreweryCatalogSortOrder.nameAscending,
      );
      bloc.add(const BreweryCatalogFiltersCleared());
    },
    expect: () => [
      isA<BreweryCatalogState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<BreweryCatalogState>()
          .having((state) => state.currentPage, 'first page loaded', 1)
          .having(
            (state) => state.breweries.map((brewery) => brewery.id).toList(),
            'first page results',
            ['z', 'a', 'b', 'c'],
          ),
      isA<BreweryCatalogState>().having(
        (state) => state.breweries.map((brewery) => brewery.id).toList(),
        'filtered breweries',
        ['z', 'a', 'b'],
      ),
      isA<BreweryCatalogState>()
          .having(
            (state) => state.breweries.map((brewery) => brewery.id).toList(),
            'sorted breweries',
            ['a', 'b', 'z'],
          )
          .having(
            (state) => state.sortOrder,
            'sort order',
            BreweryCatalogSortOrder.nameAscending,
          ),
      isA<BreweryCatalogState>()
          .having((state) => state.activeTypes, 'cleared types', isEmpty)
          .having(
            (state) => state.breweries.map((brewery) => brewery.id).toList(),
            'all breweries after clearing filters',
            ['a', 'b', 'c', 'z'],
          ),
    ],
  );

  blocTest<BreweryCatalogBloc, BreweryCatalogState>(
    'searches the catalog by name after the debounce',
    setUp: () {
      when(() => repository.searchBreweries(query: 'stone')).thenAnswer(
        (_) async => const [
          Brewery(id: 'stone', name: 'Stone Brewing', breweryType: 'regional'),
        ],
      );
    },
    build: () => BreweryCatalogBloc(
      getBreweries: GetBreweryPage(repository),
      searchBreweries: SearchBreweries(repository),
    ),
    act: (bloc) => bloc.add(const BreweryCatalogSearchChanged('stone')),
    wait: const Duration(milliseconds: 350),
    expect: () => [
      isA<BreweryCatalogState>().having(
        (state) => state.isLoading,
        'search loading',
        true,
      ),
      isA<BreweryCatalogState>()
          .having((state) => state.query, 'query', 'stone')
          .having(
            (state) => state.breweries.map((brewery) => brewery.id).toList(),
            'search results',
            ['stone'],
          ),
    ],
    verify: (_) =>
        verify(() => repository.searchBreweries(query: 'stone')).called(1),
  );
}
