import '../entities/brewery_route.dart';
import '../constants/route_mode.dart';
import '../entities/user_location.dart';
import '../repositories/brewery_route_repository.dart';

class GetBreweryRouteUseCase {
  const GetBreweryRouteUseCase(this._repository);

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
