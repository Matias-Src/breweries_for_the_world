import '../entities/brewery.dart';
import '../repositories/brewery_repository.dart';

class GetBreweryPageUseCase {
  const GetBreweryPageUseCase(this._repository);

  final BreweryRepository _repository;

  Future<List<Brewery>> call({required int page, int perPage = 20}) =>
      _repository.getBreweries(page: page, perPage: perPage);
}
