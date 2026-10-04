import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/brewery_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingInterceptor extends Interceptor {
  RequestOptions? request;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    request = options;
    handler.resolve(Response<dynamic>(requestOptions: options, data: []));
  }
}

void main() {
  test('requests the requested brewery catalog page', () async {
    final interceptor = _CapturingInterceptor();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
      ..interceptors.add(interceptor);
    final dataSource = BreweryRemoteDataSourceImpl(dio: dio);

    final breweries = await dataSource.getBreweries(page: 3, perPage: 20);

    final request = interceptor.request;
    expect(breweries, isEmpty);
    expect(request, isNotNull);
    expect(request!.method, 'GET');
    expect(request.path, '/breweries');
    expect(request.queryParameters['page'], 3);
    expect(request.queryParameters['per_page'], 20);
    expect(request.uri.queryParameters['page'], '3');
    expect(request.uri.queryParameters['per_page'], '20');
  });

  test(
    'requests 40 breweries ordered by distance from the supplied location',
    () async {
      final interceptor = _CapturingInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
        ..interceptors.add(interceptor);
      final dataSource = BreweryRemoteDataSourceImpl(dio: dio);

      final breweries = await dataSource.getNearestBreweries(
        latitude: 50.241246,
        longitude: 11.327765,
        limit: 40,
      );

      final request = interceptor.request;
      expect(breweries, isEmpty);
      expect(request, isNotNull);
      expect(request!.method, 'GET');
      expect(request.path, '/breweries');
      expect(request.queryParameters['by_dist'], '50.241246,11.327765');
      expect(request.queryParameters['per_page'], 40);
      expect(request.uri.queryParameters['by_dist'], '50.241246,11.327765');
      expect(request.uri.queryParameters['per_page'], '40');
    },
  );

  test('parses brewery objects and rejects malformed result entries', () async {
    final validBrewery = <String, dynamic>{
      'id': 'brewery-1',
      'name': 'Example Brewery',
      'brewery_type': 'micro',
    };
    final interceptor = _ResponseInterceptor([validBrewery]);
    final dataSource = BreweryRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
        ..interceptors.add(interceptor),
    );

    final breweries = await dataSource.getNearestBreweries(
      latitude: 0,
      longitude: 0,
      limit: 40,
    );

    expect(breweries, hasLength(1));
    expect(breweries.single.name, 'Example Brewery');

    final malformedDataSource = BreweryRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
        ..interceptors.add(_ResponseInterceptor(['not-an-object'])),
    );

    await expectLater(
      malformedDataSource.getNearestBreweries(
        latitude: 0,
        longitude: 0,
        limit: 40,
      ),
      throwsFormatException,
    );
  });

  test('searches by name using the encoded query parameter', () async {
    final interceptor = _SearchCapturingInterceptor()
      ..responseData = [
        {'id': 'brewery-1', 'name': 'Brew & Co Köln', 'brewery_type': 'micro'},
      ];
    final dataSource = BreweryRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
        ..interceptors.add(interceptor),
    );

    final breweries = await dataSource.searchBreweries(query: 'Brew & Co/Köln');

    expect(breweries.single.name, 'Brew & Co Köln');
    expect(interceptor.request!.path, '/breweries/search');
    expect(interceptor.request!.queryParameters['query'], 'Brew & Co/Köln');
    expect(interceptor.request!.uri.queryParameters['query'], 'Brew & Co/Köln');
  });

  test('loads one brewery by id for direct detail routes', () async {
    final interceptor = _ResponseInterceptor({
      'id': 'brewery-42',
      'name': 'Route Brewery',
      'brewery_type': 'micro',
    });
    final dataSource = BreweryRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://api.openbrewerydb.org/v1'))
        ..interceptors.add(interceptor),
    );

    final brewery = await dataSource.getBreweryById(id: 'brewery-42');

    expect(brewery.id, 'brewery-42');
    expect(interceptor.request!.path, '/breweries/brewery-42');
  });
}

class _ResponseInterceptor extends Interceptor {
  _ResponseInterceptor(this.data);

  final Object data;
  RequestOptions? request;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    request = options;
    handler.resolve(Response<dynamic>(requestOptions: options, data: data));
  }
}

class _SearchCapturingInterceptor extends Interceptor {
  RequestOptions? request;
  Object? responseData;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    request = options;
    handler.resolve(
      Response<dynamic>(requestOptions: options, data: responseData),
    );
  }
}
