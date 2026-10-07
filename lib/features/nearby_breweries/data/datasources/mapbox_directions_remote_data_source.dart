import 'package:dio/dio.dart';

import '../models/brewery_route_model.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/constants/route_mode.dart';
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
    return BreweryRouteModel.fromJson(response.data, mode: mode);
  }
}
