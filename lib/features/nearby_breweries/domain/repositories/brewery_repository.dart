import '../entities/brewery.dart';

abstract interface class BreweryRepository {
  Future<Brewery> getBreweryById({required String id});

  Future<List<Brewery>> getBreweries({required int page, int perPage = 20});

  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int page = 1,
    int limit = 40,
  });

  Future<List<Brewery>> searchBreweries({required String query});
}
