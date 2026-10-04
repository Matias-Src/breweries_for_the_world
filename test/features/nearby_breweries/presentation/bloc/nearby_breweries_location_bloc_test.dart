import 'package:bloc_test/bloc_test.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/location_permission_denied_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/location_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_current_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_event.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBreweryRepository extends Mock implements BreweryRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockBreweryRepository breweryRepository;
  late MockLocationRepository locationRepository;
  late GetNearestBreweries getNearestBreweries;
  late GetCurrentLocation getCurrentLocation;

  const location = UserLocation(latitude: 50.241246, longitude: 11.327765);
  const brewery = Brewery(
    id: 'brewery-1',
    name: 'Example Brewery',
    breweryType: 'micro',
    latitude: 50.241246,
    longitude: 11.327765,
  );

  setUp(() {
    breweryRepository = MockBreweryRepository();
    locationRepository = MockLocationRepository();
    getNearestBreweries = GetNearestBreweries(breweryRepository);
    getCurrentLocation = GetCurrentLocation(locationRepository);
  });

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'gets location before requesting the 40 nearest breweries',
    setUp: () {
      when(
        () => locationRepository.getCurrentLocation(),
      ).thenAnswer((_) async => location);
      when(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [brewery]);
    },
    build: () => NearbyBreweriesBloc(
      getCurrentLocation: getCurrentLocation,
      getNearestBreweries: getNearestBreweries,
    ),
    act: (bloc) => bloc.add(const LocationRequested()),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'breweries',
        [brewery],
      ),
    ],
    verify: (_) {
      verify(() => locationRepository.getCurrentLocation()).called(1);
      verify(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).called(1);
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'refreshes location without reloading nearby breweries',
    setUp: () {
      const refreshedLocation = UserLocation(latitude: 51.0, longitude: 12.0);
      var locationRequests = 0;
      when(() => locationRepository.getCurrentLocation()).thenAnswer((_) async {
        locationRequests++;
        return locationRequests == 1 ? location : refreshedLocation;
      });
      when(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [brewery]);
    },
    build: () => NearbyBreweriesBloc(
      getCurrentLocation: getCurrentLocation,
      getNearestBreweries: getNearestBreweries,
    ),
    act: (bloc) async {
      final initialLoad = bloc.stream.firstWhere(
        (state) => state is NearbyBreweriesSuccess,
      );
      bloc.add(const LocationRequested());
      await initialLoad;
      final refreshed = bloc.stream.firstWhere(
        (state) => state.location?.latitude == 51.0,
      );
      bloc.add(const LocationRefreshRequested());
      await refreshed;
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.location,
        'initial location',
        location,
      ),
      isA<NearbyBreweriesSuccess>()
          .having(
            (state) => state.isRefreshingLocation,
            'refreshing location',
            true,
          )
          .having((state) => state.breweries, 'retained breweries', [brewery]),
      isA<NearbyBreweriesSuccess>()
          .having(
            (state) => state.location?.latitude,
            'refreshed latitude',
            51.0,
          )
          .having(
            (state) => state.isRefreshingLocation,
            'refresh complete',
            false,
          ),
    ],
    verify: (_) {
      verify(() => locationRepository.getCurrentLocation()).called(2);
      verify(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).called(1);
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'does not request nearby breweries when location permission is denied',
    setUp: () {
      when(
        () => locationRepository.getCurrentLocation(),
      ).thenThrow(const LocationPermissionDeniedException());
    },
    build: () => NearbyBreweriesBloc(
      getCurrentLocation: getCurrentLocation,
      getNearestBreweries: getNearestBreweries,
    ),
    act: (bloc) => bloc.add(const LocationRequested()),
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesError>().having(
        (state) => state.exception,
        'exception',
        isA<LocationPermissionDeniedException>(),
      ),
    ],
    verify: (_) {
      verify(() => locationRepository.getCurrentLocation()).called(1);
      verifyNever(
        () => breweryRepository.getNearestBreweries(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      );
    },
  );

  blocTest<NearbyBreweriesBloc, NearbyBreweriesState>(
    'retries location and fetches breweries after an earlier denial',
    setUp: () {
      var locationAttempts = 0;
      when(() => locationRepository.getCurrentLocation()).thenAnswer((_) async {
        locationAttempts++;
        if (locationAttempts == 1) {
          throw const LocationPermissionDeniedException();
        }
        return location;
      });
      when(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [brewery]);
    },
    build: () => NearbyBreweriesBloc(
      getCurrentLocation: getCurrentLocation,
      getNearestBreweries: getNearestBreweries,
    ),
    act: (bloc) async {
      final locationError = bloc.stream.firstWhere(
        (state) => state is NearbyBreweriesError,
      );
      bloc.add(const LocationRequested());
      await locationError;
      bloc.add(const RetryRequested());
    },
    expect: () => [
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesError>(),
      isA<NearbyBreweriesLoading>(),
      isA<NearbyBreweriesSuccess>(),
    ],
    verify: (_) {
      verify(() => locationRepository.getCurrentLocation()).called(2);
      verify(
        () => breweryRepository.getNearestBreweries(
          latitude: location.latitude,
          longitude: location.longitude,
          limit: 40,
        ),
      ).called(1);
    },
  );
}
