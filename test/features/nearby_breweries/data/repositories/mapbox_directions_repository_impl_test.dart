import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/repositories/mapbox_directions_repository_impl.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/route_mode.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/network_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/parsing_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDirectionsDataSource implements MapboxDirectionsRemoteDataSource {
  Object? error;
  final route = const BreweryRoute(
    mode: RouteMode.walking,
    coordinates: [
      UserLocation(latitude: 37.7, longitude: -122.4),
      UserLocation(latitude: 37.8, longitude: -122.3),
    ],
    distanceMeters: 1250,
    durationSeconds: 840,
  );

  @override
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return route;
  }
}

void main() {
  const origin = UserLocation(latitude: 37.7, longitude: -122.4);
  const destination = UserLocation(latitude: 37.8, longitude: -122.3);

  test('translates a connection failure into a network exception', () async {
    final dataSource = _FakeDirectionsDataSource()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/directions'),
        type: DioExceptionType.connectionError,
      );
    final repository = MapboxDirectionsRepositoryImpl(dataSource: dataSource);

    await expectLater(
      repository.getRoute(
        origin: origin,
        destination: destination,
        mode: RouteMode.walking,
      ),
      throwsA(isA<NetworkException>()),
    );
  });

  test('translates malformed route data into a parsing exception', () async {
    final dataSource = _FakeDirectionsDataSource()..error = const FormatException();
    final repository = MapboxDirectionsRepositoryImpl(dataSource: dataSource);

    await expectLater(
      repository.getRoute(
        origin: origin,
        destination: destination,
        mode: RouteMode.walking,
      ),
      throwsA(isA<ParsingException>()),
    );
  });
}