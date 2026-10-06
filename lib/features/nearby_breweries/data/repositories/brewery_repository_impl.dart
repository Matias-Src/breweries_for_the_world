import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/errors/brewery_not_found_exception.dart';
import '../../domain/errors/network_exception.dart';
import '../../domain/errors/parsing_exception.dart';
import '../../domain/errors/server_exception.dart';
import '../../domain/repositories/brewery_repository.dart';
import '../../domain/services/distance_calculator.dart';
import '../datasources/brewery_remote_data_source.dart';

@LazySingleton(as: BreweryRepository)
class BreweryRepositoryImpl implements BreweryRepository {
  BreweryRepositoryImpl({required BreweryRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final BreweryRemoteDataSource _remoteDataSource;

  @override
  Future<Brewery> getBreweryById({required String id}) async {
    try {
      final brewery = await _remoteDataSource.getBreweryById(id: id);
      return brewery.toEntity();
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 404) {
        throw BreweryNotFoundException(id);
      }
      throw _mapDioException(exception);
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }

  @override
  Future<List<Brewery>> getBreweries({
    required int page,
    int perPage = 20,
  }) async {
    try {
      final breweries = await _remoteDataSource.getBreweries(
        page: page,
        perPage: perPage,
      );
      return breweries.map((brewery) => brewery.toEntity()).toList();
    } on DioException catch (exception) {
      throw _mapDioException(exception);
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }

  @override
  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int page = 1,
    int limit = 40,
  }) async {
    try {
      final breweries = await _remoteDataSource.getNearestBreweries(
        latitude: latitude,
        longitude: longitude,
        page: page,
        limit: limit,
      );
      return breweries
          .map(
            (brewery) => brewery.toEntity(
              distanceKm: DistanceCalculator.calculateKm(
                startLatitude: latitude,
                startLongitude: longitude,
                endLatitude: brewery.latitude,
                endLongitude: brewery.longitude,
              ),
            ),
          )
          .toList();
    } on DioException catch (exception) {
      throw _mapDioException(exception);
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }

  @override
  Future<List<Brewery>> searchBreweries({required String query}) async {
    try {
      final breweries = await _remoteDataSource.searchBreweries(query: query);
      return breweries.map((brewery) => brewery.toEntity()).toList();
    } on DioException catch (exception) {
      throw _mapDioException(exception);
    } on FormatException catch (exception) {
      throw ParsingException(exception.message);
    }
  }
}

Exception _mapDioException(DioException exception) {
  final response = exception.response;
  if (response != null) {
    return ServerException(
      exception.message ?? 'The brewery service returned an error.',
      response.statusCode,
      exception,
    );
  }
  return NetworkException(
    exception.message ?? 'Could not reach the server.',
    exception,
  );
}
