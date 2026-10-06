import '../entities/brewery.dart';
import '../repositories/brewery_repository.dart';

class GetBreweryById {
  const GetBreweryById(this._repository);

  final BreweryRepository _repository;

  Future<Brewery> call({required String id}) =>
      _repository.getBreweryById(id: id);
}
