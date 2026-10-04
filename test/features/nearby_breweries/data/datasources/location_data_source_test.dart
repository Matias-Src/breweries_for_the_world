import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/location_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/location_permission_denied_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/location_service_disabled_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:mocktail/mocktail.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform platform;
  late LocationDataSourceImpl dataSource;

  setUp(() {
    platform = MockGeolocatorPlatform();
    dataSource = LocationDataSourceImpl(geolocatorPlatform: platform);
  });

  test(
    'returns a typed service error without checking permission if disabled',
    () async {
      when(
        () => platform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      await expectLater(
        dataSource.getCurrentLocation(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      verifyNever(() => platform.checkPermission());
      verifyNever(() => platform.requestPermission());
      verifyNever(() => platform.getCurrentPosition());
    },
  );

  test(
    'requests permission and returns current coordinates when granted',
    () async {
      when(
        () => platform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => platform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => platform.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => platform.getCurrentPosition(),
      ).thenAnswer((_) async => _position());

      final location = await dataSource.getCurrentLocation();

      expect(
        location,
        const UserLocation(latitude: 50.241246, longitude: 11.327765),
      );
      verify(() => platform.requestPermission()).called(1);
      verify(() => platform.getCurrentPosition()).called(1);
    },
  );

  test(
    'does not get a position after the user denies the permission request',
    () async {
      when(
        () => platform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => platform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => platform.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      await expectLater(
        dataSource.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
      verifyNever(() => platform.getCurrentPosition());
    },
  );

  test(
    'reports permanent denial without showing another permission prompt',
    () async {
      when(
        () => platform.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => platform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      await expectLater(
        dataSource.getCurrentLocation(),
        throwsA(
          isA<LocationPermissionDeniedException>().having(
            (exception) => exception.permanentlyDenied,
            'permanentlyDenied',
            isTrue,
          ),
        ),
      );
      verifyNever(() => platform.requestPermission());
      verifyNever(() => platform.getCurrentPosition());
    },
  );

  test('uses an existing permission without requesting it again', () async {
    when(
      () => platform.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => platform.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      () => platform.getCurrentPosition(),
    ).thenAnswer((_) async => _position());

    final location = await dataSource.getCurrentLocation();

    expect(location.latitude, 50.241246);
    expect(location.longitude, 11.327765);
    verifyNever(() => platform.requestPermission());
  });
}

Position _position() => Position(
  latitude: 50.241246,
  longitude: 11.327765,
  timestamp: DateTime.utc(2026),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
