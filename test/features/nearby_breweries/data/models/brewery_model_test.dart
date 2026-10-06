import 'package:breweries_for_the_world/features/nearby_breweries/data/models/brewery_model.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('maps brewery and full address fields from the API response', () {
    final brewery = BreweryModel.fromJson(breweryJson);

    expect(brewery, isA<Brewery>());
    expect(brewery.id, 'ae7b3174-8be8-4d53-a3a5-9b8240970eea');
    expect(brewery.name, "'s");
    expect(brewery.breweryType, 'brewpub');
    expect(brewery.address1, 'Friesener Straße 1');
    expect(brewery.address2, isNull);
    expect(brewery.address3, isNull);
    expect(brewery.street, 'Friesener Straße 1');
    expect(brewery.city, 'Kronach');
    expect(brewery.state, 'Bayern');
    expect(brewery.stateProvince, 'Bayern');
    expect(brewery.postalCode, '96317');
    expect(brewery.country, 'Germany');
    expect(brewery.latitude, 50.241246);
    expect(brewery.longitude, 11.327765);
    expect(brewery.phone, '+49 9261 628000');
    expect(brewery.websiteUrl, 'http://www.antla.de');
  });

  test('keeps brewery data when coordinates are absent or invalid', () {
    final withoutCoordinates = BreweryModel.fromJson({
      ...breweryJson,
      'latitude': null,
      'longitude': null,
    });
    final withInvalidCoordinates = BreweryModel.fromJson({
      ...breweryJson,
      'latitude': 91,
      'longitude': 'not-a-coordinate',
    });

    expect(withoutCoordinates.name, "'s");
    expect(withoutCoordinates.latitude, isNull);
    expect(withoutCoordinates.longitude, isNull);
    expect(withInvalidCoordinates.name, "'s");
    expect(withInvalidCoordinates.latitude, isNull);
    expect(withInvalidCoordinates.longitude, isNull);
  });

  test('rejects missing required API fields', () {
    expect(
      () => BreweryModel.fromJson({...breweryJson}..remove('id')),
      throwsFormatException,
    );
    expect(
      () => BreweryModel.fromJson({...breweryJson}..remove('name')),
      throwsFormatException,
    );
    expect(
      () => BreweryModel.fromJson({...breweryJson}..remove('brewery_type')),
      throwsFormatException,
    );
  });
}
