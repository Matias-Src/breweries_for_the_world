class Brewery {
  const Brewery({
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
    this.distanceKm,
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
  final double? distanceKm;
}
