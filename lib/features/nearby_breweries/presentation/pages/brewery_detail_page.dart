import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/brewery.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/constants/route_mode.dart';
import '../../domain/entities/user_location.dart';
import '../bloc/brewery_detail_cubit/brewery_detail_cubit.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';

class BreweryDetailPage extends StatelessWidget {
  const BreweryDetailPage({super.key, required this.mapAdapter});

  final BreweryMapAdapter mapAdapter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BreweryDetailCubit, BreweryDetailState>(
      builder: (context, state) => switch (state) {
        BreweryDetailLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        BreweryDetailEmpty() => Scaffold(
          appBar: AppBar(title: Text(l10n.breweryDetails)),
          body: Center(child: Text(l10n.breweryNotFound)),
        ),
        BreweryDetailError() => Scaffold(
          appBar: AppBar(title: Text(l10n.breweryDetails)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.breweryDetailsLoadError),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.read<BreweryDetailCubit>().load(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        BreweryDetailSuccess() => _buildSuccess(context, state, l10n),
      },
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    BreweryDetailSuccess state,
    AppLocalizations l10n,
  ) {
    final brewery = state.brewery;
    final cubit = context.read<BreweryDetailCubit>();
    final address = formatBreweryAddress(brewery);
    final city = brewery.city?.trim();
    final cityInAddress =
        city != null &&
        address != null &&
        address.toLowerCase().contains(city.toLowerCase());
    final canRequestRoute = cubit.canRequestRoute(brewery);

    return Scaffold(
      key: ValueKey('brewery-detail-view-${brewery.id}'),
      appBar: AppBar(title: Text(l10n.breweryDetails)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = constraints.maxHeight * 0.44;
          return Stack(
            fit: StackFit.expand,
            children: [
              KeyedSubtree(
                key: const ValueKey('brewery-detail-map'),
                child: mapAdapter.buildBreweryMap(
                  brewery: brewery,
                  userLocation: cubit.userLocation,
                  route: state.route,
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
                    hasCoordinates: _hasValidCoordinates(brewery),
                    canRequestRoute: canRequestRoute,
                    selectedMode: state.selectedMode,
                    route: state.route,
                    routeError: state.routeError,
                    isLoadingRoute: state.isLoadingRoute,
                    onModeChanged: cubit.selectMode,
                    onRetry: cubit.retryRoute,
                    onOpenWebsite: cubit.openWebsite,
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
    required this.onModeChanged,
    required this.onRetry,
    required this.onOpenWebsite,
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
  final ValueChanged<RouteMode> onModeChanged;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      label: Text(l10n.walking),
                      icon: const Icon(Icons.directions_walk),
                    ),
                    ButtonSegment(
                      value: RouteMode.driving,
                      label: Text(l10n.driving),
                      icon: const Icon(Icons.directions_car),
                    ),
                  ],
                  selected: {selectedMode},
                  onSelectionChanged: canRequestRoute
                      ? (selection) => onModeChanged(selection.first)
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(height: 24, child: _buildRouteStatus(context, l10n)),
              ],
              if (address != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                    ),
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
                          Icon(
                            Icons.phone_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(brewery.phone!.trim()),
                        ],
                      ),
                    if (_hasText(brewery.websiteUrl))
                      InkWell(
                        key: const ValueKey('brewery-website-link'),
                        onTap: () => onOpenWebsite(brewery.websiteUrl!),
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

  Widget _buildRouteStatus(BuildContext context, AppLocalizations l10n) {
    if (!canRequestRoute) return Text(l10n.locationUnavailable);
    if (isLoadingRoute) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.calculatingRoute),
        ],
      );
    }
    if (routeError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.routeError,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: l10n.retryRoute,
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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _hasValidCoordinates(Brewery brewery) {
  final latitude = brewery.latitude;
  final longitude = brewery.longitude;
  return latitude != null &&
      longitude != null &&
      UserLocation.areCoordinatesValid(latitude, longitude);
}
