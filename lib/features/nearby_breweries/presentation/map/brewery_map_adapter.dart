import 'package:flutter/widgets.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';

abstract interface class BreweryMapAdapter {
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  });

  Widget buildBreweryMap({required Brewery brewery});

  Future<void> recenter(UserLocation location);
}
