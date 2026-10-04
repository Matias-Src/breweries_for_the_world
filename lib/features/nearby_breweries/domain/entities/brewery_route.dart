import 'user_location.dart';
import 'route_mode.dart';

class BreweryRoute {
  const BreweryRoute({
    required this.mode,
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final RouteMode mode;
  final List<UserLocation> coordinates;
  final double distanceMeters;
  final double durationSeconds;
}