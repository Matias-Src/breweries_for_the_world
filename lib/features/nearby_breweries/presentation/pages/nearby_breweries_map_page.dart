import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';
import '../bloc/nearby_breweries_bloc.dart';
import '../bloc/nearby_breweries_event.dart';
import '../bloc/nearby_breweries_state.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';
import 'brewery_detail_page.dart';

class NearbyBreweriesMapPage extends StatefulWidget {
  const NearbyBreweriesMapPage({super.key, required this.mapAdapter});

  final BreweryMapAdapter mapAdapter;

  @override
  State<NearbyBreweriesMapPage> createState() => _NearbyBreweriesMapPageState();
}

class _NearbyBreweriesMapPageState extends State<NearbyBreweriesMapPage> {
  static const _breweryCardExtent = 296.0;
  final ScrollController _carouselController = ScrollController();

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nearby breweries'),
      actions: [
        BlocBuilder<NearbyBreweriesBloc, NearbyBreweriesState>(
          builder: (context, state) {
            final breweries = state is NearbyBreweriesSuccess
                ? state.breweries
                : const <Brewery>[];
            if (breweries.isEmpty) return const SizedBox.shrink();
            return IconButton(
              key: const ValueKey('brewery-list-expand'),
              tooltip: 'Expand brewery list',
              onPressed: () => _showExpandedList(context, breweries),
              icon: const Icon(Icons.expand_less),
            );
          },
        ),
      ],
    ),
    body: BlocBuilder<NearbyBreweriesBloc, NearbyBreweriesState>(
      builder: (context, state) {
        final success = state is NearbyBreweriesSuccess ? state : null;
        final location = switch (state) {
          NearbyBreweriesSuccess(:final location) => location,
          NearbyBreweriesEmpty(:final location) => location,
          _ => null,
        };
        final breweries = success?.breweries ?? const <Brewery>[];
        final mappedBreweries = breweries
            .where(_hasValidCoordinates)
            .toList(growable: false);
        final hasCarousel = breweries.isNotEmpty;

        return SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.mapAdapter.buildMap(
                userLocation: location != null && _isValidLocation(location)
                    ? location
                    : null,
                initialCameraLocation:
                    location != null && _isValidLocation(location)
                    ? location
                    : null,
                breweries: mappedBreweries,
                selectedBreweryId: success?.selectedBreweryId,
                onBrewerySelected: (breweryId) =>
                    _onMarkerSelected(context, breweries, breweryId),
              ),
              if (state is NearbyBreweriesLoading ||
                  state is NearbyBreweriesInitial)
                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (hasCarousel)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SizedBox(
                    height: 210,
                    child: _buildCarousel(context, breweries, success),
                  ),
                ),
              if (location != null && _isValidLocation(location))
                Positioned(
                  right: 16,
                  bottom: hasCarousel ? 230 : 24,
                  child: FloatingActionButton(
                    tooltip: 'My location',
                    onPressed: () =>
                        unawaited(widget.mapAdapter.recenter(location)),
                    child: const Icon(Icons.my_location),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildCarousel(
    BuildContext context,
    List<Brewery> breweries,
    NearbyBreweriesSuccess? success,
  ) => ListView.builder(
    key: const ValueKey('brewery-carousel'),
    controller: _carouselController,
    scrollDirection: Axis.horizontal,
    itemExtent: _breweryCardExtent,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    itemCount: breweries.length,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _BreweryCard(
        brewery: breweries[index],
        selected: breweries[index].id == success?.selectedBreweryId,
        onSelected: () => _selectBrewery(context, breweries[index]),
        onDetails: () => _openDetails(context, breweries[index]),
      ),
    ),
  );

  void _onMarkerSelected(
    BuildContext context,
    List<Brewery> breweries,
    String breweryId,
  ) {
    final index = breweries.indexWhere((brewery) => brewery.id == breweryId);
    if (index < 0) return;
    _selectBrewery(context, breweries[index], recenterMap: false);
    _scrollCardIntoView(index);
  }

  void _selectBrewery(
    BuildContext context,
    Brewery brewery, {
    bool recenterMap = true,
  }) {
    context.read<NearbyBreweriesBloc>().add(BrewerySelected(brewery.id));
    if (!recenterMap) return;
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    if (latitude == null ||
        longitude == null ||
        !_isValidCoordinates(latitude, longitude)) {
      return;
    }
    unawaited(
      widget.mapAdapter.recenter(
        UserLocation(latitude: latitude, longitude: longitude),
      ),
    );
  }

  void _scrollCardIntoView(int index) {
    if (!_carouselController.hasClients) return;
    final target = (index * _breweryCardExtent).clamp(
      0.0,
      _carouselController.position.maxScrollExtent,
    );
    unawaited(
      _carouselController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  void _openDetails(BuildContext context, Brewery brewery) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BreweryDetailPage(brewery: brewery, mapAdapter: widget.mapAdapter),
      ),
    );
  }

  void _showExpandedList(BuildContext context, List<Brewery> breweries) {
    final bloc = context.read<NearbyBreweriesBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Breweries',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: breweries.length,
                  itemBuilder: (context, index) => _BreweryListTile(
                    brewery: breweries[index],
                    onSelected: () {
                      Navigator.of(sheetContext).pop();
                      bloc.add(BrewerySelected(breweries[index].id));
                      final latitude = breweries[index].latitude;
                      final longitude = breweries[index].longitude;
                      if (latitude != null &&
                          longitude != null &&
                          _isValidCoordinates(latitude, longitude)) {
                        unawaited(
                          widget.mapAdapter.recenter(
                            UserLocation(
                              latitude: latitude,
                              longitude: longitude,
                            ),
                          ),
                        );
                        _scrollCardIntoView(index);
                      }
                    },
                    onDetails: () {
                      Navigator.of(sheetContext).pop();
                      _openDetails(context, breweries[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreweryCard extends StatelessWidget {
  const _BreweryCard({
    required this.brewery,
    required this.selected,
    required this.onSelected,
    required this.onDetails,
  });

  final Brewery brewery;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final address = formatBreweryAddress(brewery);
    final city = brewery.city?.trim();
    final cityInAddress =
        city != null &&
        address != null &&
        address.toLowerCase().contains(city.toLowerCase());
    return Card(
      key: ValueKey('brewery-card-${brewery.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brewery.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                [brewery.breweryType, if (!cityInAddress) brewery.city]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (brewery.distanceKm case final distance?
                  when distance.isFinite)
                Text('${distance.toStringAsFixed(1)} km'),
              if (_hasText(brewery.phone))
                Text(
                  brewery.phone!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (address != null)
                Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (_hasText(brewery.websiteUrl))
                Text(
                  brewery.websiteUrl!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: ValueKey('brewery-details-${brewery.id}'),
                  tooltip: 'Open brewery details',
                  onPressed: onDetails,
                  icon: const Icon(Icons.open_in_new),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreweryListTile extends StatelessWidget {
  const _BreweryListTile({
    required this.brewery,
    required this.onSelected,
    required this.onDetails,
  });

  final Brewery brewery;
  final VoidCallback onSelected;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('expanded-brewery-${brewery.id}'),
    title: Text(brewery.name),
    subtitle: Text(
      [brewery.breweryType, brewery.city, formatBreweryAddress(brewery)]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' · '),
    ),
    onTap: onSelected,
    trailing: IconButton(
      tooltip: 'Open brewery details',
      onPressed: onDetails,
      icon: const Icon(Icons.open_in_new),
    ),
  );
}

bool _hasValidCoordinates(Brewery brewery) {
  final latitude = brewery.latitude;
  final longitude = brewery.longitude;
  return latitude != null &&
      longitude != null &&
      _isValidCoordinates(latitude, longitude);
}

bool _isValidLocation(UserLocation location) =>
    _isValidCoordinates(location.latitude, location.longitude);

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _isValidCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;
