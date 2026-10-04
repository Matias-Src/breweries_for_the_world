import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/get_brewery_route.dart';
import '../bloc/nearby_breweries_bloc.dart';
import '../bloc/nearby_breweries_event.dart';
import '../bloc/nearby_breweries_state.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';
import 'brewery_detail_page.dart';

class NearbyBreweriesMapPage extends StatefulWidget {
  const NearbyBreweriesMapPage({
    super.key,
    required this.mapAdapter,
    this.getBreweryRoute,
  });

  final BreweryMapAdapter mapAdapter;
  final GetBreweryRoute? getBreweryRoute;

  @override
  State<NearbyBreweriesMapPage> createState() => _NearbyBreweriesMapPageState();
}

class _NearbyBreweriesMapPageState extends State<NearbyBreweriesMapPage> {
  static const _breweryCardExtent = 296.0;
  static const _breweryTypes = [
    'micro',
    'nano',
    'regional',
    'brewpub',
    'large',
    'planning',
    'bar',
    'contract',
    'closed',
  ];
  final ScrollController _carouselController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = _NearbyBreweriesLabels.of(context);
    return Scaffold(
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
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        key: const ValueKey('brewery-search-island'),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        elevation: 8,
                        shadowColor: const Color(0x33000000),
                        borderRadius: BorderRadius.circular(32),
                        child: SizedBox(
                          height: 56,
                          child: TextField(
                            key: const ValueKey('brewery-search-field'),
                            controller: _searchController,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: labels.searchHint,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _searchController,
                                    builder: (context, value, _) =>
                                        value.text.isEmpty
                                        ? const SizedBox.shrink()
                                        : IconButton(
                                            tooltip: labels.clearSearch,
                                            onPressed: () {
                                              _searchController.clear();
                                              context
                                                  .read<NearbyBreweriesBloc>()
                                                  .add(
                                                    const SearchQueryChanged(
                                                      '',
                                                    ),
                                                  );
                                            },
                                            icon: const Icon(Icons.close),
                                          ),
                                  ),
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            onChanged: (query) => context
                                .read<NearbyBreweriesBloc>()
                                .add(SearchQueryChanged(query)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterChips(context, state, labels),
                    ],
                  ),
                ),
                if (state is NearbyBreweriesLoading ||
                    state is NearbyBreweriesInitial)
                  const Positioned(
                    top: 126,
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
                      child: _buildCarousel(
                        context,
                        breweries,
                        success,
                        location,
                      ),
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
  }

  Widget _buildFilterChips(
    BuildContext context,
    NearbyBreweriesState state,
    _NearbyBreweriesLabels labels,
  ) {
    final activeTypes = switch (state) {
      NearbyBreweriesSuccess(:final activeTypes) => activeTypes,
      NearbyBreweriesEmpty(:final activeTypes) => activeTypes,
      _ => const <String>{},
    };
    final bloc = context.read<NearbyBreweriesBloc>();
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      key: const ValueKey('brewery-filter-carousel'),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              key: const ValueKey('brewery-type-all'),
              label: Text(labels.allBreweries),
              selected: activeTypes.isEmpty,
              showCheckmark: false,
              backgroundColor: colorScheme.surfaceContainerHigh,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: activeTypes.isEmpty
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              onSelected: (_) => bloc.add(const FiltersCleared()),
            ),
          ),
          for (final type in _breweryTypes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: ValueKey('brewery-type-$type'),
                label: Text(type),
                selected: activeTypes.contains(type),
                showCheckmark: false,
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: activeTypes.contains(type)
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                onSelected: (_) {
                  final nextTypes = Set<String>.of(activeTypes);
                  if (!nextTypes.add(type)) nextTypes.remove(type);
                  _applyBreweryTypeFilter(bloc, nextTypes);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    List<Brewery> breweries,
    NearbyBreweriesSuccess? success,
    UserLocation? location,
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
        onDetails: () => _openDetails(context, breweries[index], location),
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
    final bloc = context.read<NearbyBreweriesBloc>();
    final currentState = bloc.state;
    final isDeselecting =
        currentState is NearbyBreweriesSuccess &&
        currentState.selectedBreweryId == brewery.id;
    bloc.add(BrewerySelected(brewery.id));
    if (!recenterMap) return;
    if (isDeselecting) {
      _recenterOnUserLocation(currentState);
      return;
    }
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

  void _applyBreweryTypeFilter(NearbyBreweriesBloc bloc, Set<String> types) {
    final currentState = bloc.state;
    if (currentState is NearbyBreweriesSuccess) {
      final selectedBreweryId = currentState.selectedBreweryId;
      final selectionMatchesFilter = currentState.breweries.any(
        (brewery) =>
            brewery.id == selectedBreweryId &&
            types.contains(brewery.breweryType),
      );
      if (selectedBreweryId != null &&
          types.isNotEmpty &&
          !selectionMatchesFilter) {
        _recenterOnUserLocation(currentState);
      }
    }
    bloc.add(BreweryTypesChanged(types));
  }

  void _recenterOnUserLocation(NearbyBreweriesState state) {
    final location = switch (state) {
      NearbyBreweriesSuccess(:final location) => location,
      NearbyBreweriesEmpty(:final location) => location,
      _ => null,
    };
    if (location != null && _isValidLocation(location)) {
      unawaited(widget.mapAdapter.recenter(location));
    }
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

  void _openDetails(
    BuildContext context,
    Brewery brewery,
    UserLocation? location,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BreweryDetailPage(
          brewery: brewery,
          mapAdapter: widget.mapAdapter,
          userLocation: location,
          getBreweryRoute: widget.getBreweryRoute,
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
    final labels = _NearbyBreweriesLabels.of(context);
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                alignment: Alignment.center,
                child: FilledButton.icon(
                  key: ValueKey('brewery-details-${brewery.id}'),
                  onPressed: onDetails,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconAlignment: IconAlignment.end,
                  label: Text(labels.moreDetails),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasValidCoordinates(Brewery brewery) {
  final latitude = brewery.latitude;
  final longitude = brewery.longitude;
  return latitude != null &&
      longitude != null &&
      _isValidCoordinates(latitude, longitude);
}

class _NearbyBreweriesLabels {
  const _NearbyBreweriesLabels(this.isSpanish);

  factory _NearbyBreweriesLabels.of(BuildContext context) =>
      _NearbyBreweriesLabels(
        Localizations.localeOf(context).languageCode == 'es',
      );

  final bool isSpanish;

  String get searchHint =>
      isSpanish ? 'Buscar cervecerías' : 'Search breweries';
  String get clearSearch => isSpanish ? 'Borrar búsqueda' : 'Clear search';
  String get allBreweries => isSpanish ? 'Todas' : 'All';
  String get filterBreweries =>
      isSpanish ? 'Filtrar cervecerías' : 'Filter breweries';
  String get filtersTitle => isSpanish ? 'Filtros' : 'Filters';
  String get clearFilters => isSpanish ? 'Limpiar' : 'Clear';
  String get applyFilters => isSpanish ? 'Aplicar' : 'Apply';
  String get moreDetails => isSpanish ? 'Ver más detalles' : 'More details';
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
