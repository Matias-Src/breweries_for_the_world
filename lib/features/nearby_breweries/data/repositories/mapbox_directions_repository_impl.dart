import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/brewery_route.dart';
import '../../domain/constants/route_mode.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/errors/network_exception.dart';
import '../../domain/errors/parsing_exception.dart';
import '../../domain/errors/server_exception.dart';
import '../../domain/repositories/brewery_route_repository.dart';
import '../datasources/mapbox_directions_remote_data_source.dart';

@LazySingleton(as: BreweryRouteRepository)
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
      final response = exception.response;
      if (response != null) {
        throw ServerException(
          exception.message ?? 'The directions service returned an error.',
          response.statusCode,
          exception,
        );
      }
      throw NetworkException(
        exception.message ?? 'Could not reach the directions service.',
        exception,
      );
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }
}
