import 'dart:math' as math;

class DistanceCalculator {
  static const double _earthRadiusKm = 6371.0088;

  static double? calculateKm({
    required double? startLatitude,
    required double? startLongitude,
    required double? endLatitude,
    required double? endLongitude,
  }) {
    if (!_isValidCoordinate(startLatitude, min: -90, max: 90) ||
        !_isValidCoordinate(startLongitude, min: -180, max: 180) ||
        !_isValidCoordinate(endLatitude, min: -90, max: 90) ||
        !_isValidCoordinate(endLongitude, min: -180, max: 180)) {
      return null;
    }

    final latitudeDelta = _toRadians(endLatitude! - startLatitude!);
    final longitudeDelta = _toRadians(endLongitude! - startLongitude!);
    final startLatitudeRadians = _toRadians(startLatitude);
    final endLatitudeRadians = _toRadians(endLatitude);

    final haversine =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final boundedHaversine = haversine.clamp(0.0, 1.0);

    return _earthRadiusKm *
        2 *
        math.atan2(
          math.sqrt(boundedHaversine),
          math.sqrt(1 - boundedHaversine),
        );
  }

  static bool _isValidCoordinate(
    double? value, {
    required double min,
    required double max,
  }) => value != null && value.isFinite && value >= min && value <= max;

  static double _toRadians(double degrees) => degrees * (math.pi / 180);
}
