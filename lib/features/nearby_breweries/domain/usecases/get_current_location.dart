import '../entities/user_location.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationUseCase {
  const GetCurrentLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<UserLocation> call() => _repository.getCurrentLocation();
}
