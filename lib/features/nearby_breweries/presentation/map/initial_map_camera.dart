import '../../domain/entities/user_location.dart';

class InitialMapCamera {
  const InitialMapCamera({required this.center, required this.zoom});

  static const fallbackCenter = UserLocation(
    latitude: 39.8283,
    longitude: -98.5795,
  );
  static const fallbackZoom = 5.5;
  static const locationZoom = 12.0;

  final UserLocation center;
  final double zoom;

  factory InitialMapCamera.resolve(UserLocation? location) {
    if (location != null && _isValidLocation(location)) {
      return InitialMapCamera(center: location, zoom: locationZoom);
    }
    return const InitialMapCamera(center: fallbackCenter, zoom: fallbackZoom);
  }
}

bool _isValidLocation(UserLocation location) =>
    location.latitude.isFinite &&
    location.longitude.isFinite &&
    location.latitude >= -90 &&
    location.latitude <= 90 &&
    location.longitude >= -180 &&
    location.longitude <= 180;
