import 'package:breweries_for_the_world/features/nearby_breweries/data/datasources/brewery_remote_data_source.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/models/brewery_dto.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/data/repositories/brewery_repository_impl.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/network_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/parsing_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/server_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBreweryRemoteDataSource extends Mock
    implements BreweryRemoteDataSource {}

void main() {
  late MockBreweryRemoteDataSource dataSource;
  late BreweryRepository repository;

  const latitude = 50.241246;
  const longitude = 11.327765;
  const breweryJson = <String, dynamic>{
    'id': 'ae7b3174-8be8-4d53-a3a5-9b8240970eea',
    'name': "'s",
    'brewery_type': 'brewpub',
    'address_1': 'Friesener Straße 1',
    'address_2': null,
    'address_3': null,
    'city': 'Kronach',
    'state_province': 'Bayern',
    'postal_code': '96317',
    'country': 'Germany',
    'longitude': 11.327765,
    'latitude': 50.241246,
    'phone': '+49 9261 628000',
    'website_url': 'http://www.antla.de',
    'state': 'Bayern',
    'street': 'Friesener Straße 1',
  };

  setUp(() {
    dataSource = MockBreweryRemoteDataSource();
    repository = BreweryRepositoryImpl(remoteDataSource: dataSource);
  });

  test('loads a brewery by id and maps it into a domain entity', () async {
    when(
      () => dataSource.getBreweryById(id: 'brewery-42'),
    ).thenAnswer((_) async => BreweryDto.fromJson(breweryJson));

    final brewery = await repository.getBreweryById(id: 'brewery-42');

    verify(() => dataSource.getBreweryById(id: 'brewery-42')).called(1);
    expect(brewery.name, "'s");
    expect(brewery.city, 'Kronach');
  });

  test('maps a requested brewery page into domain entities', () async {
    when(
      () => dataSource.getBreweries(page: 2, perPage: 20),
    ).thenAnswer((_) async => [BreweryDto.fromJson(breweryJson)]);

    final breweries = await repository.getBreweries(page: 2, perPage: 20);

    verify(() => dataSource.getBreweries(page: 2, perPage: 20)).called(1);
    expect(breweries.single.name, "'s");
    expect(breweries.single.city, 'Kronach');
  });

  group('getNearestBreweries', () {
    test('requests 40 breweries ordered by distance from the user', () async {
      when(
        () => dataSource.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [BreweryDto.fromJson(breweryJson)]);

      final breweries = await repository.getNearestBreweries(
        latitude: latitude,
        longitude: longitude,
      );

      verify(
        () => dataSource.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).called(1);
      expect(breweries, hasLength(1));
      expect(breweries.single, isA<Brewery>());
      expect(breweries.single.name, "'s");
      expect(breweries.single.address1, 'Friesener Straße 1');
      expect(breweries.single.phone, '+49 9261 628000');
      expect(breweries.single.websiteUrl, 'http://www.antla.de');
    });

    test(
      'returns an empty list when the API has no nearby breweries',
      () async {
        when(
          () => dataSource.getNearestBreweries(
            latitude: latitude,
            longitude: longitude,
            limit: 40,
          ),
        ).thenAnswer((_) async => <BreweryDto>[]);

        final breweries = await repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
        );

        expect(breweries, isEmpty);
      },
    );

    test('maps Dio connection errors to a typed network exception', () async {
      when(
        () => dataSource.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/breweries'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps Dio response errors to a typed server exception', () async {
      when(
        () => dataSource.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/breweries'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/breweries'),
            statusCode: 503,
          ),
        ),
      );

      await expectLater(
        repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(
          isA<ServerException>().having(
            (exception) => exception.statusCode,
            'status code',
            503,
          ),
        ),
      );
    });

    test('maps malformed API data to a typed parsing exception', () async {
      when(
        () => dataSource.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
          limit: 40,
        ),
      ).thenThrow(const FormatException('Invalid brewery payload.'));

      await expectLater(
        repository.getNearestBreweries(
          latitude: latitude,
          longitude: longitude,
        ),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
