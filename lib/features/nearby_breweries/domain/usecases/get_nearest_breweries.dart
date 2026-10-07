import '../entities/brewery.dart';
import '../repositories/brewery_repository.dart';

class GetNearestBreweriesUseCase {
  const GetNearestBreweriesUseCase(this._repository);

  final BreweryRepository _repository;

  Future<List<Brewery>> call({
    required double latitude,
    required double longitude,
    int page = 1,
  }) {
    return _repository.getNearestBreweries(
      latitude: latitude,
      longitude: longitude,
      page: page,
      limit: 40,
    );
  }
}
