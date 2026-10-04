import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl({required LocationDataSource dataSource})
    : _dataSource = dataSource;

  final LocationDataSource _dataSource;

  @override
  Future<UserLocation> getCurrentLocation() => _dataSource.getCurrentLocation();
}
