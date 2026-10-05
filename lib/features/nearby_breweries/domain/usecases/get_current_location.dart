import 'package:injectable/injectable.dart';

import '../entities/user_location.dart';
import '../repositories/location_repository.dart';

@lazySingleton
class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final LocationRepository _repository;

  Future<UserLocation> call() => _repository.getCurrentLocation();
}
