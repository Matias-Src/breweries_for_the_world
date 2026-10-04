import 'package:dio/dio.dart';

import '../models/brewery_dto.dart';

abstract interface class BreweryRemoteDataSource {
  Future<BreweryDto> getBreweryById({required String id});

  Future<List<BreweryDto>> getBreweries({
    required int page,
    required int perPage,
  });

  Future<List<BreweryDto>> getNearestBreweries({
    required double latitude,
    required double longitude,
    required int limit,
  });

  Future<List<BreweryDto>> searchBreweries({required String query});
}

class BreweryRemoteDataSourceImpl implements BreweryRemoteDataSource {
  BreweryRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<BreweryDto> getBreweryById({required String id}) async {
    final response = await _dio.get<Map<String, dynamic>>('/breweries/$id');
    final brewery = response.data;
    if (brewery == null) {
      throw const FormatException('Brewery response is empty.');
    }
    return BreweryDto.fromJson(brewery);
  }

  @override
  Future<List<BreweryDto>> getBreweries({
    required int page,
    required int perPage,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/breweries',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return _parseBreweries(response.data);
  }

  @override
  Future<List<BreweryDto>> getNearestBreweries({
    required double latitude,
    required double longitude,
    required int limit,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/breweries',
      queryParameters: {'by_dist': '$latitude,$longitude', 'per_page': limit},
    );
    return _parseBreweries(response.data);
  }

  @override
  Future<List<BreweryDto>> searchBreweries({required String query}) async {
    final response = await _dio.get<List<dynamic>>(
      '/breweries/search',
      queryParameters: {'query': query},
    );
    return _parseBreweries(response.data);
  }

  List<BreweryDto> _parseBreweries(List<dynamic>? breweries) {
    if (breweries == null) return const [];

    return breweries
        .map((json) {
          if (json is! Map) {
            throw const FormatException(
              'Brewery response item is not an object.',
            );
          }
          return BreweryDto.fromJson(Map<String, dynamic>.from(json));
        })
        .toList(growable: false);
  }
}
