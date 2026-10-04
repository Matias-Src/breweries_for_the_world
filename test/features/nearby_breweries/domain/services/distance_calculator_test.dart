import 'package:breweries_for_the_world/features/nearby_breweries/domain/services/distance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates the Haversine distance in kilometers', () {
    final distanceKm = DistanceCalculator.calculateKm(
      startLatitude: 0,
      startLongitude: 0,
      endLatitude: 0,
      endLongitude: 1,
    );

    expect(distanceKm, closeTo(111.195, 0.01));
  });

  test('returns zero for identical coordinates', () {
    final distanceKm = DistanceCalculator.calculateKm(
      startLatitude: 50.241246,
      startLongitude: 11.327765,
      endLatitude: 50.241246,
      endLongitude: 11.327765,
    );

    expect(distanceKm, 0);
  });

  test('returns null if a coordinate is missing or outside valid bounds', () {
    expect(
      DistanceCalculator.calculateKm(
        startLatitude: null,
        startLongitude: 11,
        endLatitude: 50,
        endLongitude: 12,
      ),
      isNull,
    );
    expect(
      DistanceCalculator.calculateKm(
        startLatitude: 91,
        startLongitude: 11,
        endLatitude: 50,
        endLongitude: 12,
      ),
      isNull,
    );
  });
}
