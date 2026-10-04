import 'package:dio/dio.dart';

import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/route_mode.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/errors/network_exception.dart';
import '../../domain/errors/parsing_exception.dart';
import '../../domain/errors/server_exception.dart';
import '../../domain/repositories/brewery_route_repository.dart';
import '../datasources/mapbox_directions_remote_data_source.dart';

class MapboxDirectionsRepositoryImpl implements BreweryRouteRepository {
  const MapboxDirectionsRepositoryImpl({required this.dataSource});

  final MapboxDirectionsRemoteDataSource dataSource;

  @override
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  }) async {
    try {
      return await dataSource.getRoute(
        origin: origin,
        destination: destination,
        mode: mode,
      );
    } on DioException catch (exception) {
      if (exception.response != null) {
        throw ServerException(
          exception.message ?? 'The directions service returned an error.',
        );
      }
      throw NetworkException(
        exception.message ?? 'Could not reach the directions service.',
      );
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }
}