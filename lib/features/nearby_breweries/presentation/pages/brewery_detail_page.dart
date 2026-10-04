import 'package:flutter/material.dart';

import '../../domain/entities/brewery.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';

class BreweryDetailPage extends StatelessWidget {
  const BreweryDetailPage({
    super.key,
    required this.brewery,
    required this.mapAdapter,
  });

  final Brewery brewery;
  final BreweryMapAdapter mapAdapter;

  @override
  Widget build(BuildContext context) {
    final addressSegments = breweryAddressSegments(brewery);
    final city = brewery.city?.trim();
    final cityInAddress =
        city != null &&
        addressSegments.any(
          (segment) => segment.toLowerCase() == city.toLowerCase(),
        );
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    final hasCoordinates =
        latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;

    return Scaffold(
      key: ValueKey('brewery-detail-view-${brewery.id}'),
      appBar: AppBar(title: const Text('Brewery details')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              brewery.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(brewery.breweryType),
            if (city != null && city.isNotEmpty && !cityInAddress) Text(city),
            if (brewery.distanceKm case final distance? when distance.isFinite)
              Text('${distance.toStringAsFixed(1)} km'),
            if (addressSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Address', style: Theme.of(context).textTheme.titleSmall),
              for (final segment in addressSegments) SelectableText(segment),
            ],
            if (_hasText(brewery.phone)) ...[
              const SizedBox(height: 16),
              Text('Phone', style: Theme.of(context).textTheme.titleSmall),
              SelectableText(brewery.phone!.trim()),
            ],
            if (_hasText(brewery.websiteUrl)) ...[
              const SizedBox(height: 16),
              Text('Website', style: Theme.of(context).textTheme.titleSmall),
              SelectableText(brewery.websiteUrl!.trim()),
            ],
            if (hasCoordinates) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: mapAdapter.buildBreweryMap(brewery: brewery),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
