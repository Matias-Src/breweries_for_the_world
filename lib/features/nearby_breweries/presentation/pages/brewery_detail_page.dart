import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/route_mode.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/get_brewery_route.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';

class BreweryDetailPage extends StatefulWidget {
  const BreweryDetailPage({
    super.key,
    required this.brewery,
    required this.mapAdapter,
    this.userLocation,
    this.getBreweryRoute,
  });

  final Brewery brewery;
  final BreweryMapAdapter mapAdapter;
  final UserLocation? userLocation;
  final GetBreweryRoute? getBreweryRoute;

  @override
  State<BreweryDetailPage> createState() => _BreweryDetailPageState();
}

class _BreweryDetailPageState extends State<BreweryDetailPage> {
  RouteMode _selectedMode = RouteMode.walking;
  BreweryRoute? _route;
  Object? _routeError;
  bool _isLoadingRoute = false;
  int _routeRequestId = 0;

  bool get _hasDestination {
    final latitude = widget.brewery.latitude;
    final longitude = widget.brewery.longitude;
    return latitude != null &&
        longitude != null &&
        _isValidCoordinates(latitude, longitude);
  }

  bool get _canRequestRoute =>
      _hasDestination &&
      widget.userLocation != null &&
      _isValidLocation(widget.userLocation!) &&
      widget.getBreweryRoute != null;

  @override
  void initState() {
    super.initState();
    if (_canRequestRoute) {
      _isLoadingRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestRoute(RouteMode.walking);
      });
    }
  }

  Future<void> _requestRoute(RouteMode mode) async {
    final origin = widget.userLocation;
    final latitude = widget.brewery.latitude;
    final longitude = widget.brewery.longitude;
    final getBreweryRoute = widget.getBreweryRoute;
    if (origin == null ||
        latitude == null ||
        longitude == null ||
        getBreweryRoute == null) {
      return;
    }

    final requestId = ++_routeRequestId;
    setState(() {
      _selectedMode = mode;
      _route = null;
      _routeError = null;
      _isLoadingRoute = true;
    });

    try {
      final route = await getBreweryRoute(
        origin: origin,
        destination: UserLocation(latitude: latitude, longitude: longitude),
        mode: mode,
      );
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _route = route;
        _isLoadingRoute = false;
      });
    } on Exception catch (error) {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routeError = error;
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brewery = widget.brewery;
    final address = formatBreweryAddress(brewery);
    final city = brewery.city?.trim();
    final cityInAddress = city != null &&
        address != null &&
        address.toLowerCase().contains(city.toLowerCase());
    final hasCoordinates = _hasDestination;

    return Scaffold(
      key: ValueKey('brewery-detail-view-${brewery.id}'),
      appBar: AppBar(title: const Text('Brewery details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = constraints.maxHeight * 0.44;
          return Stack(
            fit: StackFit.expand,
            children: [
              KeyedSubtree(
                key: const ValueKey('brewery-detail-map'),
                child: widget.mapAdapter.buildBreweryMap(
                  brewery: brewery,
                  userLocation: widget.userLocation,
                  route: _route,
                  bottomPanelHeight: panelHeight,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  height: panelHeight,
                  child: _BreweryDetailPanel(
                    brewery: brewery,
                    address: address,
                    city: city,
                    cityInAddress: cityInAddress,
                    hasCoordinates: hasCoordinates,
                    canRequestRoute: _canRequestRoute,
                    selectedMode: _selectedMode,
                    route: _route,
                    routeError: _routeError,
                    isLoadingRoute: _isLoadingRoute,
                    labels: _BreweryDetailLabels.of(context),
                    onModeChanged: _requestRoute,
                    onRetry: () => _requestRoute(_selectedMode),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreweryDetailPanel extends StatelessWidget {
  const _BreweryDetailPanel({
    required this.brewery,
    required this.address,
    required this.city,
    required this.cityInAddress,
    required this.hasCoordinates,
    required this.canRequestRoute,
    required this.selectedMode,
    required this.route,
    required this.routeError,
    required this.isLoadingRoute,
    required this.labels,
    required this.onModeChanged,
    required this.onRetry,
  });

  final Brewery brewery;
  final String? address;
  final String? city;
  final bool cityInAddress;
  final bool hasCoordinates;
  final bool canRequestRoute;
  final RouteMode selectedMode;
  final BreweryRoute? route;
  final Object? routeError;
  final bool isLoadingRoute;
  final _BreweryDetailLabels labels;
  final ValueChanged<RouteMode> onModeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final city = this.city;
    final details = [
      brewery.breweryType,
      if (city != null && city.isNotEmpty && !cityInAddress) city,
      if (brewery.distanceKm case final distance? when distance.isFinite)
        '${distance.toStringAsFixed(1)} km',
    ].join(' · ');

    return Material(
      key: const ValueKey('brewery-detail-panel'),
      color: colorScheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      elevation: 16,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brewery.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasCoordinates) ...[
                const SizedBox(height: 10),
                SegmentedButton<RouteMode>(
                  segments: [
                    ButtonSegment(
                      value: RouteMode.walking,
                      label: Text(labels.walking),
                      icon: const Icon(Icons.directions_walk),
                    ),
                    ButtonSegment(
                      value: RouteMode.driving,
                      label: Text(labels.driving),
                      icon: const Icon(Icons.directions_car),
                    ),
                  ],
                  selected: {selectedMode},
                  onSelectionChanged: canRequestRoute
                      ? (selection) => onModeChanged(selection.first)
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(height: 24, child: _buildRouteStatus(context)),
              ],
              if (address != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (_hasText(brewery.phone) || _hasText(brewery.websiteUrl)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    if (_hasText(brewery.phone))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(brewery.phone!.trim()),
                        ],
                      ),
                    if (_hasText(brewery.websiteUrl))
                      InkWell(
                        key: const ValueKey('brewery-website-link'),
                        onTap: () => _openWebsite(brewery.websiteUrl!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              brewery.websiteUrl!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStatus(BuildContext context) {
    if (!canRequestRoute) return Text(labels.locationUnavailable);
    if (isLoadingRoute) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(labels.calculatingRoute),
        ],
      );
    }
    if (routeError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              labels.routeError,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: labels.retry,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }
    final currentRoute = route;
    if (currentRoute == null) return const SizedBox.shrink();
    final distance = currentRoute.distanceMeters < 1000
        ? '${currentRoute.distanceMeters.round()} m'
        : '${(currentRoute.distanceMeters / 1000).toStringAsFixed(1)} km';
    final minutes = (currentRoute.durationSeconds / 60).ceil();
    return Text(
      '$minutes min · $distance',
      key: const ValueKey('route-summary'),
    );
  }
}

class _BreweryDetailLabels {
  const _BreweryDetailLabels(this.isSpanish);

  factory _BreweryDetailLabels.of(BuildContext context) =>
      _BreweryDetailLabels(
        Localizations.localeOf(context).languageCode == 'es',
      );

  final bool isSpanish;

  String get walking => isSpanish ? 'A pie' : 'Walk';
  String get driving => isSpanish ? 'En auto' : 'Drive';
  String get locationUnavailable =>
      isSpanish ? 'Ubicación no disponible' : 'Location unavailable';
  String get calculatingRoute =>
      isSpanish ? 'Calculando ruta...' : 'Calculating route...';
  String get routeError =>
      isSpanish ? 'No se pudo calcular la ruta' : 'Could not calculate route';
  String get retry => isSpanish ? 'Reintentar ruta' : 'Retry route';
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _isValidLocation(UserLocation location) =>
    _isValidCoordinates(location.latitude, location.longitude);

bool _isValidCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

Future<void> _openWebsite(String websiteUrl) async {
  final trimmedUrl = websiteUrl.trim();
  final parsedUrl = Uri.tryParse(trimmedUrl);
  final uri = parsedUrl != null && parsedUrl.hasScheme
      ? parsedUrl
      : Uri.tryParse('https://$trimmedUrl');

  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
