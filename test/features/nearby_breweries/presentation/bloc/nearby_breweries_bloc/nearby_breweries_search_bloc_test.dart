import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/network_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc/nearby_breweries_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBreweryRepository extends Mock implements BreweryRepository {}

void main() {
  late MockBreweryRepository repository;
  late GetNearestBreweries getNearestBreweries;
  late SearchBreweries searchBreweries;
  late Completer<List<Brewery>> oldSearch;
  late Completer<List<Brewery>> newSearch;

  const latitude = 50.241246;
  const longitude = 11.327765;
  const nearbyBreweries = [
    Brewery(id: 'micro-1', name: 'Micro One', breweryType: 'micro'),
    Brewery(id: 'nano-1', name: 'Nano One', breweryType: 'nano'),
    Brewery(id: 'brewpub-1', name: 'Brewpub One', breweryType: 'brewpub'),
  ];
  const searchResult = Brewery(
    id: 'search-1',
    name: 'Brewery Search Result',
    breweryType: 'micro',
  );

  setUp(() {
    repository = MockBreweryRepository();
    getNearestBreweries = GetNearestBreweries(repository);
    searchBreweries = SearchBreweries(repository);
  });

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'debounces search input and requests only the latest non-empty query',
    setUp: () {
      when(
        () => repository.searchBreweries(query: 'brewery'),
      ).thenAnswer((_) async => [searchResult]);
    },
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) {
      bloc
        ..add(const SearchQueryChanged('b'))
        ..add(const SearchQueryChanged('brew'))
        ..add(const SearchQueryChanged('brewery'));
    },
    wait: const Duration(milliseconds: 500),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'breweries',
        [searchResult],
      ),
    ],
    verify: (_) {
      verify(() => repository.searchBreweries(query: 'brewery')).called(1);
      verifyNever(() => repository.searchBreweries(query: 'b'));
      verifyNever(() => repository.searchBreweries(query: 'brew'));
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'does not search when the query contains only whitespace',
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
    wait: const Duration(milliseconds: 500),
    expect: () => [],
    verify: (_) {
      verifyNever(() => repository.searchBreweries(query: any(named: 'query')));
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'emits Empty when a search has no matches',
    setUp: () {
      when(
        () => repository.searchBreweries(query: 'no match'),
      ).thenAnswer((_) async => []);
    },
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) => bloc.add(const SearchQueryChanged('no match')),
    wait: const Duration(milliseconds: 500),
    expect: () => [isA<NearbyBreweriesLoading>(), isA<NearbyBreweriesEmpty>()],
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'preserves a typed error when a search fails',
    setUp: () {
      when(
        () => repository.searchBreweries(query: 'brewery'),
      ).thenThrow(const NetworkException());
    },
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) => bloc.add(const SearchQueryChanged('brewery')),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesError>().having(
        (state) => state.exception,
        'exception',
        isA<NetworkException>(),
      ),
    ],
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'retries the failed search query instead of loading nearby breweries',
    setUp: () {
      var attempts = 0;
      when(() => repository.searchBreweries(query: 'brewery')).thenAnswer((
        _,
      ) async {
        attempts++;
        if (attempts == 1) throw const NetworkException();
        return [searchResult];
      });
    },
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) async {
      final failed = bloc.stream.firstWhere(
        (state) => state is NearbyBreweriesError,
      );
      bloc.add(const SearchQueryChanged('brewery'));
      await failed;

      final retried = bloc.stream.firstWhere(
        (state) =>
            state is NearbyBreweriesSuccess &&
            state.breweries.single.id == searchResult.id,
      );
      bloc.add(const RetryRequested());
      await retried;
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesError>(),
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'retried search results',
        [searchResult],
      ),
    ],
    verify: (_) =>
        verify(() => repository.searchBreweries(query: 'brewery')).called(2),
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'ignores an older search response after a newer query completes',
    setUp: () {
      oldSearch = Completer<List<Brewery>>();
      newSearch = Completer<List<Brewery>>();
      when(
        () => repository.searchBreweries(query: 'old'),
      ).thenAnswer((_) => oldSearch.future);
      when(
        () => repository.searchBreweries(query: 'new'),
      ).thenAnswer((_) => newSearch.future);
    },
    build: () => NearbyBreweriesBloc(
      getNearestBreweries: getNearestBreweries,
      searchBreweries: searchBreweries,
    ),
    act: (bloc) async {
      final newResult = const Brewery(
        id: 'new',
        name: 'New result',
        breweryType: 'micro',
      );
      final oldResult = const Brewery(
        id: 'old',
        name: 'Old result',
        breweryType: 'micro',
      );

      final latestSuccess = bloc.stream.firstWhere(
        (state) =>
            state is NearbyBreweriesSuccess &&
            state.breweries.single.id == 'new',
      );
      bloc.add(const SearchQueryChanged('old'));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      bloc.add(const SearchQueryChanged('new'));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      newSearch.complete([newResult]);
      await latestSuccess;
      oldSearch.complete([oldResult]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'breweries',
        [const Brewery(id: 'new', name: 'New result', breweryType: 'micro')],
      ),
    ],
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'filters multiple types locally in existing order and restores all on clear',
    setUp: () {
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => nearbyBreweries);
    },
    build: () => NearbyBreweriesBloc(getNearestBreweries: getNearestBreweries),
    act: (bloc) async {
      final loaded = bloc.stream.firstWhere(
        (state) => state is NearbyBreweriesSuccess,
      );
      bloc.add(
        const LocationRequested(latitude: latitude, longitude: longitude),
      );
      await loaded;

      final filtered = bloc.stream.firstWhere(
        (state) =>
            state is NearbyBreweriesSuccess && state.activeTypes.length == 2,
      );
      bloc.add(const BreweryTypesChanged({'micro', 'nano'}));
      await filtered;

      final cleared = bloc.stream.firstWhere(
        (state) => state is NearbyBreweriesSuccess && state.activeTypes.isEmpty,
      );
      bloc.add(const FiltersCleared());
      await cleared;
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'initial nearby breweries',
        nearbyBreweries,
      ),
      isA<NearbyBreweriesSuccess>()
          .having(
            (state) => state.breweries.map((brewery) => brewery.id).toList(),
            'filtered breweries in original order',
            ['micro-1', 'nano-1'],
          )
          .having((state) => state.activeTypes, 'active types', {
            'micro',
            'nano',
          }),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'restored nearby breweries',
        nearbyBreweries,
      ),
    ],
  );
}
