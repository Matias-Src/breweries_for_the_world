import 'package:dio/dio.dart';

import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/route_mode.dart';
import '../../domain/entities/user_location.dart';

abstract interface class MapboxDirectionsRemoteDataSource {
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  });
}

class MapboxDirectionsRemoteDataSourceImpl
    implements MapboxDirectionsRemoteDataSource {
  MapboxDirectionsRemoteDataSourceImpl({
    required Dio dio,
    required String accessToken,
  }) : _dio = dio,
       _accessToken = accessToken;

  final Dio _dio;
  final String _accessToken;

  @override
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.mapbox.com/directions/v5/mapbox/${mode.name}/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}',
      queryParameters: {
        'access_token': _accessToken,
        'alternatives': false,
        'geometries': 'geojson',
        'overview': 'full',
        'steps': false,
      },
    );
    return _parseRoute(response.data, mode);
  }

  BreweryRoute _parseRoute(Map<String, dynamic>? data, RouteMode mode) {
    final routes = data?['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw const FormatException('Directions response contains no routes.');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final distance = route['distance'];
    final duration = route['duration'];
    final geometry = route['geometry'];
    final rawCoordinates = geometry is Map ? geometry['coordinates'] : null;
    if (distance is! num ||
        duration is! num ||
        !distance.isFinite ||
        !duration.isFinite ||
        rawCoordinates is! List) {
      throw const FormatException('Directions route is malformed.');
    }

    final coordinates = rawCoordinates.map((coordinate) {
      if (coordinate is! List || coordinate.length < 2) {
        throw const FormatException('Directions geometry is malformed.');
      }
      final longitude = coordinate[0];
      final latitude = coordinate[1];
      if (longitude is! num || latitude is! num) {
        throw const FormatException('Directions geometry is malformed.');
      }
      return UserLocation(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );
    }).toList(growable: false);

    if (coordinates.length < 2) {
      throw const FormatException('Directions geometry has too few points.');
    }

    return BreweryRoute(
      mode: mode,
      coordinates: coordinates,
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }
}