import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../models/brewery_model.dart';

abstract interface class BreweryRemoteDataSource {
  Future<BreweryModel> getBreweryById({required String id});

  Future<List<BreweryModel>> getBreweries({
    required int page,
    required int perPage,
  });

  Future<List<BreweryModel>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int page = 1,
    required int limit,
  });

  Future<List<BreweryModel>> searchBreweries({required String query});
}

@LazySingleton(as: BreweryRemoteDataSource)
class BreweryRemoteDataSourceImpl implements BreweryRemoteDataSource {
  BreweryRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<BreweryModel> getBreweryById({required String id}) async {
    final response = await _dio.get<Map<String, dynamic>>('/breweries/$id');
    final brewery = response.data;
    if (brewery == null) {
      throw const FormatException('Brewery response is empty.');
    }
    return BreweryModel.fromJson(brewery);
  }

  @override
  Future<List<BreweryModel>> getBreweries({
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
  Future<List<BreweryModel>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int page = 1,
    required int limit,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/breweries',
      queryParameters: {
        'by_dist': '$latitude,$longitude',
        'page': page,
        'per_page': limit,
      },
    );
    return _parseBreweries(response.data);
  }

  @override
  Future<List<BreweryModel>> searchBreweries({required String query}) async {
    final response = await _dio.get<List<dynamic>>(
      '/breweries/search',
      queryParameters: {'query': query},
    );
    return _parseBreweries(response.data);
  }

  List<BreweryModel> _parseBreweries(List<dynamic>? breweries) {
    if (breweries == null) return const [];

    return breweries
        .map((json) {
          if (json is! Map) {
            throw const FormatException(
              'Brewery response item is not an object.',
            );
          }
          return BreweryModel.fromJson(Map<String, dynamic>.from(json));
        })
        .toList(growable: false);
  }
}
