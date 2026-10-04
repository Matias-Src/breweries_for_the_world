import '../entities/brewery_route.dart';
import '../entities/route_mode.dart';
import '../entities/user_location.dart';
import '../repositories/brewery_route_repository.dart';

class GetBreweryRoute {
  const GetBreweryRoute(this._repository);

  final BreweryRouteRepository _repository;

  Future<BreweryRoute> call({
    required UserLocation origin,
    required UserLocation destination,
    required RouteMode mode,
  }) => _repository.getRoute(
    origin: origin,
    destination: destination,
    mode: mode,
  );
}