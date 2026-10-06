import '../entities/brewery.dart';
import '../repositories/brewery_repository.dart';

class SearchBreweries {
  const SearchBreweries(this._repository);

  final BreweryRepository _repository;

  Future<List<Brewery>> call({required String query}) =>
      _repository.searchBreweries(query: query);
}
