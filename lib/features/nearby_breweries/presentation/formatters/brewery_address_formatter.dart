import '../../domain/entities/brewery.dart';

List<String> breweryAddressSegments(Brewery brewery) {
  final candidates = [
    brewery.address1,
    brewery.address2,
    brewery.address3,
    brewery.street,
    brewery.city,
    brewery.stateProvince,
    brewery.state,
    brewery.postalCode,
    brewery.country,
  ];
  final segments = <String>[];
  final normalizedSegments = <String>{};

  for (final candidate in candidates) {
    final segment = candidate?.trim();
    if (segment == null || segment.isEmpty) continue;
    if (normalizedSegments.add(segment.toLowerCase())) segments.add(segment);
  }

  return segments;
}

String? formatBreweryAddress(Brewery brewery) {
  final segments = breweryAddressSegments(brewery);
  return segments.isEmpty ? null : segments.join(', ');
}
