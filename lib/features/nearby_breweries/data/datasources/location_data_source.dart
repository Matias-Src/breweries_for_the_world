import 'package:geolocator/geolocator.dart' as geo;

import '../../domain/entities/user_location.dart';
import '../../domain/errors/location_permission_denied_exception.dart';
import '../../domain/errors/location_service_disabled_exception.dart';
import '../../domain/errors/location_unavailable_exception.dart';

abstract interface class LocationDataSource {
  Future<UserLocation> getCurrentLocation();
}

class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl({required geo.GeolocatorPlatform geolocatorPlatform})
    : _geolocatorPlatform = geolocatorPlatform;

  final geo.GeolocatorPlatform _geolocatorPlatform;

  @override
  Future<UserLocation> getCurrentLocation() async {
    try {
      if (!await _geolocatorPlatform.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }

      var permission = await _geolocatorPlatform.checkPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.unableToDetermine) {
        permission = await _geolocatorPlatform.requestPermission();
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedException(permanentlyDenied: true);
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.unableToDetermine) {
        throw const LocationPermissionDeniedException();
      }

      final position = await _geolocatorPlatform.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationPermissionDeniedException {
      rethrow;
    } on LocationServiceDisabledException {
      rethrow;
    } on LocationUnavailableException {
      rethrow;
    } on geo.PermissionDeniedException {
      throw const LocationPermissionDeniedException();
    } on geo.LocationServiceDisabledException {
      throw const LocationServiceDisabledException();
    } on Exception catch (exception) {
      throw LocationUnavailableException(exception.toString());
    }
  }
}
