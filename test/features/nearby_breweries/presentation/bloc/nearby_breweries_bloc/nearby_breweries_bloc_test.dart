import 'package:bloc_test/bloc_test.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/network_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc/nearby_breweries_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBreweryRepository extends Mock implements BreweryRepository {}

void main() {
  late MockBreweryRepository repository;
  late GetNearestBreweries getNearestBreweries;

  const latitude = 50.241246;
  const longitude = 11.327765;
  const brewery = Brewery(
    id: 'ae7b3174-8be8-4d53-a3a5-9b8240970eea',
    name: "'s",
    breweryType: 'brewpub',
    address1: 'Friesener Straße 1',
    city: 'Kronach',
    stateProvince: 'Bayern',
    postalCode: '96317',
    country: 'Germany',
    latitude: latitude,
    longitude: longitude,
    phone: '+49 9261 628000',
    websiteUrl: 'http://www.antla.de',
  );

  setUp(() {
    repository = MockBreweryRepository();
    getNearestBreweries = GetNearestBreweries(repository);
  });

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'emits Loading then Success with the nearest breweries',
    setUp: () {
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [brewery]);
    },
    build: () => NearbyBreweriesBloc(getNearestBreweries: getNearestBreweries),
    act: (bloc) => bloc.add(
      const LocationRequested(latitude: latitude, longitude: longitude),
    ),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'breweries',
        [brewery],
      ),
    ],
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'appends the next page of nearby breweries when requested',
    setUp: () {
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
          page: 1,
        ),
      ).thenAnswer(
        (_) async => List.generate(
          40,
          (index) => Brewery(
            id: 'page-one-$index',
            name: 'Page one brewery $index',
            breweryType: 'micro',
          ),
        ),
      );
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
          page: 2,
        ),
      ).thenAnswer(
        (_) async => [
          const Brewery(
            id: 'page-two-1',
            name: 'Page two brewery',
            breweryType: 'micro',
          ),
        ],
      );
    },
    build: () => NearbyBreweriesBloc(getNearestBreweries: getNearestBreweries),
    act: (bloc) async {
      bloc.add(
        const LocationRequested(latitude: latitude, longitude: longitude),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NearbyBreweriesNextPageRequested());
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'initial page',
        hasLength(40),
      ),
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'appended pages',
        hasLength(41),
      ),
    ],
    verify: (_) {
      verify(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
          page: 2,
        ),
      ).called(1);
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'emits Loading then Empty when there are no nearby breweries',
    setUp: () {
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => <Brewery>[]);
    },
    build: () => NearbyBreweriesBloc(getNearestBreweries: getNearestBreweries),
    act: (bloc) => bloc.add(
      const LocationRequested(latitude: latitude, longitude: longitude),
    ),
    expect: () => [isA<NearbyBreweriesLoading>(), isA<NearbyBreweriesEmpty>()],
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'emits Loading then Error with the typed repository exception',
    setUp: () {
      when(
        () => repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenThrow(const NetworkException());
    },
    build: () => NearbyBreweriesBloc(getNearestBreweries: getNearestBreweries),
    act: (bloc) => bloc.add(
      const LocationRequested(latitude: latitude, longitude: longitude),
    ),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesError>().having(
        (state) => state.exception,
        'exception',
        isA<NetworkException>(),
      ),
    ],
  );
}
