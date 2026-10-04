import '../entities/brewery.dart';
import '../repositories/brewery_repository.dart';

class GetNearestBreweries {
  const GetNearestBreweries(this._repository);

  final BreweryRepository _repository;

  Future<List<Brewery>> call({
    required double latitude,
    required double longitude,
  }) {
    return _repository.getNearestBreweries(
      latitude: latitude,
      longitude: longitude,
      limit: 40,
    );
  }
}
