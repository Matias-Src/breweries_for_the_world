class LocationUnavailableException implements Exception {
  const LocationUnavailableException([
    this.message = 'Location is unavailable.',
  ]);

  final String message;

  @override
  String toString() => message;
}
