import '../entities/brewery_route.dart';
import '../constants/route_mode.dart';
import '../entities/user_location.dart';

abstract interface class BreweryRouteRepository {
  Future<BreweryRoute> getRoute({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  });
}