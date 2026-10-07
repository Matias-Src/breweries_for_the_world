import 'package:breweries_for_the_world/features/nearby_breweries/data/models/brewery_route_model.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/constants/route_mode.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Mapbox route data into a BreweryRoute subtype', () {
    final route = BreweryRouteModel.fromJson({
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
    }, mode: RouteMode.walking);

    expect(route, isA<BreweryRoute>());
    expect(route.mode, RouteMode.walking);
    expect(route.distanceMeters, 1250.5);
    expect(route.durationSeconds, 840);
    expect(route.coordinates, const [
      UserLocation(latitude: 37.7, longitude: -122.4),
      UserLocation(latitude: 37.8, longitude: -122.3),
    ]);
  });

  test('rejects a response without routes', () {
    expect(
      () => BreweryRouteModel.fromJson({'routes': []}, mode: RouteMode.walking),
      throwsFormatException,
    );
  });

  test('rejects route geometry with fewer than two points', () {
    expect(
      () => BreweryRouteModel.fromJson({
        'routes': [
          {
            'distance': 10,
            'duration': 20,
            'geometry': {
              'coordinates': [
                [-122.4, 37.7],
              ],
            },
          },
        ],
      }, mode: RouteMode.walking),
      throwsFormatException,
    );
  });
}
