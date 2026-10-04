import 'package:flutter/widgets.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/user_location.dart';

abstract interface class BreweryMapAdapter {
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  });

  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  });

  Future<void> recenter(UserLocation location);
}
