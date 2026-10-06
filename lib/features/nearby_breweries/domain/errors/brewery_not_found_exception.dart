class BreweryNotFoundException implements Exception {
  const BreweryNotFoundException(this.breweryId);

  final String breweryId;
}
