import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/mapbox_directions_remote_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/route_mode.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingInterceptor extends Interceptor {
  RequestOptions? request;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    request = options;
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        data: {
          'routes': [
            {
              'distance': 1250.5,
              'duration': 840.0,
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [-122.4, 37.7],
                  [-122.3, 37.8],
                ],
              },
            },
          ],
        },
      ),
    );
  }
}

void main() {
  test('requests and parses a walking route from GeoJSON', () async {
    final interceptor = _CapturingInterceptor();
    final dataSource = MapboxDirectionsRemoteDataSourceImpl(
      dio: Dio()..interceptors.add(interceptor),
      accessToken: 'pk.test-token',
    );

    final route = await dataSource.getRoute(
      origin: const UserLocation(latitude: 37.7, longitude: -122.4),
      destination: const UserLocation(latitude: 37.8, longitude: -122.3),
      mode: RouteMode.walking,
    );

    expect(interceptor.request!.path, contains('/directions/v5/mapbox/walking/'));
    expect(
      interceptor.request!.path,
      contains('-122.4,37.7;-122.3,37.8'),
    );
    expect(interceptor.request!.queryParameters['geometries'], 'geojson');
    expect(interceptor.request!.queryParameters['access_token'], 'pk.test-token');
    expect(route.mode, RouteMode.walking);
    expect(route.distanceMeters, 1250.5);
    expect(route.durationSeconds, 840);
    expect(route.coordinates, const [
      UserLocation(latitude: 37.7, longitude: -122.4),
      UserLocation(latitude: 37.8, longitude: -122.3),
    ]);
  });

  test('uses the driving profile', () async {
    final interceptor = _CapturingInterceptor();
    final dataSource = MapboxDirectionsRemoteDataSourceImpl(
      dio: Dio()..interceptors.add(interceptor),
      accessToken: 'pk.test-token',
    );

    await dataSource.getRoute(
      origin: const UserLocation(latitude: 37.7, longitude: -122.4),
      destination: const UserLocation(latitude: 37.8, longitude: -122.3),
      mode: RouteMode.driving,
    );

    expect(interceptor.request!.path, contains('/directions/v5/mapbox/driving/'));
  });
}