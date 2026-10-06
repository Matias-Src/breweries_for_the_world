import '../../domain/entities/brewery.dart';

class BreweryModel extends Brewery {
  const BreweryModel({
    required super.id,
    required super.name,
    required super.breweryType,
    super.address1,
    super.address2,
    super.address3,
    super.street,
    super.city,
    super.state,
    super.stateProvince,
    super.postalCode,
    super.country,
    super.phone,
    super.websiteUrl,
    super.latitude,
    super.longitude,
    super.distanceKm,
  });

  factory BreweryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final breweryType = json['brewery_type'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Brewery id is missing.');
    }
    if (name is! String || breweryType is! String) {
      throw const FormatException('Brewery name or type is missing.');
    }

    return BreweryModel(
      id: id,
      name: name,
      breweryType: breweryType,
      address1: _optionalString(json['address_1']),
      address2: _optionalString(json['address_2']),
      address3: _optionalString(json['address_3']),
      street: _optionalString(json['street']),
      city: _optionalString(json['city']),
      state: _optionalString(json['state']),
      stateProvince: _optionalString(json['state_province']),
      postalCode: _optionalString(json['postal_code']),
      country: _optionalString(json['country']),
      phone: _optionalString(json['phone']),
      websiteUrl: _optionalString(json['website_url']),
      latitude: _coordinate(json['latitude'], min: -90, max: 90),
      longitude: _coordinate(json['longitude'], min: -180, max: 180),
    );
  }

  BreweryModel withDistanceKm(double? distanceKm) => BreweryModel(
    id: id,
    name: name,
    breweryType: breweryType,
    address1: address1,
    address2: address2,
    address3: address3,
    street: street,
    city: city,
    state: state,
    stateProvince: stateProvince,
    postalCode: postalCode,
    country: country,
    phone: phone,
    websiteUrl: websiteUrl,
    latitude: latitude,
    longitude: longitude,
    distanceKm: distanceKm,
  );

  static String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static double? _coordinate(
    Object? value, {
    required double min,
    required double max,
  }) {
    final coordinate = switch (value) {
      num number => number.toDouble(),
      String string => double.tryParse(string),
      _ => null,
    };
    if (coordinate == null ||
        !coordinate.isFinite ||
        coordinate < min ||
        coordinate > max) {
      return null;
    }
    return coordinate;
  }
}
