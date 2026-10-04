import '../../domain/entities/brewery.dart';

class BreweryDto {
  const BreweryDto({
    required this.id,
    required this.name,
    required this.breweryType,
    this.address1,
    this.address2,
    this.address3,
    this.street,
    this.city,
    this.state,
    this.stateProvince,
    this.postalCode,
    this.country,
    this.phone,
    this.websiteUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String breweryType;
  final String? address1;
  final String? address2;
  final String? address3;
  final String? street;
  final String? city;
  final String? state;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? websiteUrl;
  final double? latitude;
  final double? longitude;

  factory BreweryDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final breweryType = json['brewery_type'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Brewery id is missing.');
    }
    if (name is! String || breweryType is! String) {
      throw const FormatException('Brewery name or type is missing.');
    }

    return BreweryDto(
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

  Brewery toEntity({double? distanceKm}) => Brewery(
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
