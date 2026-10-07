import '../../domain/entities/brewery_route.dart';
import '../../domain/constants/route_mode.dart';
import '../../domain/entities/user_location.dart';

class BreweryRouteModel extends BreweryRoute {
  const BreweryRouteModel({
    required super.mode,
    required super.coordinates,
    required super.distanceMeters,
    required super.durationSeconds,
  });

  factory BreweryRouteModel.fromJson(
    Map<String, dynamic>? data, {
    required RouteMode mode,
  }) {
    final routes = data?['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw const FormatException('Directions response contains no routes.');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final distance = route['distance'];
    final duration = route['duration'];
    final geometry = route['geometry'];
    final rawCoordinates = geometry is Map ? geometry['coordinates'] : null;
    if (distance is! num ||
        duration is! num ||
        !distance.isFinite ||
        !duration.isFinite ||
        rawCoordinates is! List) {
      throw const FormatException('Directions route is malformed.');
    }

    final coordinates = rawCoordinates
        .map((coordinate) {
          if (coordinate is! List || coordinate.length < 2) {
            throw const FormatException('Directions geometry is malformed.');
          }
          final longitude = coordinate[0];
          final latitude = coordinate[1];
          if (longitude is! num || latitude is! num) {
            throw const FormatException('Directions geometry is malformed.');
          }
          return UserLocation(
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
          );
        })
        .toList(growable: false);

    if (coordinates.length < 2) {
      throw const FormatException('Directions geometry has too few points.');
    }

    return BreweryRouteModel(
      mode: mode,
      coordinates: coordinates,
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }
}
