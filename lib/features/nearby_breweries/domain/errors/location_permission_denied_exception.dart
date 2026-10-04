class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException({this.permanentlyDenied = false});

  final bool permanentlyDenied;
}
