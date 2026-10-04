import '../entities/brewery.dart';

abstract interface class BreweryRepository {
  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int limit = 40,
  });

  Future<List<Brewery>> searchBreweries({required String query});
}
