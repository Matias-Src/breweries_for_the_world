import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../domain/entities/brewery.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/errors/location_permission_denied_exception.dart';
import '../../domain/errors/location_service_disabled_exception.dart';
import '../../domain/errors/location_unavailable_exception.dart';
import '../bloc/nearby_breweries_bloc/nearby_breweries_bloc.dart';
import '../formatters/brewery_address_formatter.dart';
import '../map/brewery_map_adapter.dart';
import '../map/nearby_breweries_map_controller.dart';

class NearbyBreweriesMapPage extends StatelessWidget {
  const NearbyBreweriesMapPage({
    super.key,
    required this.mapAdapter,
    required this.mapController,
    required this.settingsCubit,
    required this.onOpenCatalog,
    required this.onOpenBreweryDetails,
  });

  final BreweryMapAdapter mapAdapter;
  final NearbyBreweriesMapController mapController;
  final AppSettingsCubit settingsCubit;
  final VoidCallback onOpenCatalog;
  final void Function(Brewery brewery, UserLocation? location)
  onOpenBreweryDetails;

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

  @override
  Widget build(BuildContext context) {
    final labels = _NearbyBreweriesLabels.of(context);
    return Scaffold(
      drawer: _buildDrawer(context, labels),
      body: BlocConsumer<NearbyBreweriesBloc, NearbyBreweriesState>(
        listenWhen: (previous, current) =>
            previous.locationRefreshError == null &&
            current.locationRefreshError != null,
        listener: (context, state) {
          final error = state.locationRefreshError;
          if (error == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  _locationRefreshErrorMessage(
                    context,
                    error,
                    hasLastKnownLocation: state.location?.isValid ?? false,
                  ),
                ),
              ),
            );
        },
        builder: (context, state) {
          final location = state.location;
          final breweries = state.breweries;
          final mappedBreweries = breweries
              .where(_hasValidCoordinates)
              .toList(growable: false);
          final hasCarousel = breweries.isNotEmpty;

          return SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                mapAdapter.buildMap(
                  userLocation: location != null && location.isValid
                      ? location
                      : null,
                  initialCameraLocation: location != null && location.isValid
                      ? location
                      : null,
                  breweries: mappedBreweries,
                  selectedBreweryId: state.selectedBreweryId,
                  onBrewerySelected: (breweryId) =>
                      mapController.onMarkerSelected(breweries, breweryId),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            shape: const CircleBorder(),
                            elevation: 8,
                            child: Builder(
                              builder: (buttonContext) => IconButton(
                                key: const ValueKey('app-drawer-button'),
                                tooltip: AppLocalizations.of(context)!.openMenu,
                                onPressed: () =>
                                    Scaffold.of(buttonContext).openDrawer(),
                                icon: const Icon(Icons.menu),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _BrewerySearchField(
                              labels: labels,
                              onChanged: mapController.search,
                              onClear: mapController.clearSearch,
                            ),
                          ),
                        ],
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
                if (state case NearbyBreweriesError errorState)
                  Positioned(
                    top: 124,
                    left: 16,
                    right: 16,
                    child: _MapErrorNotice(
                      message: _errorMessage(context, errorState),
                      retryLabel: AppLocalizations.of(context)!.retry,
                      onRetry: () => context.read<NearbyBreweriesBloc>().add(
                        const RetryRequested(),
                      ),
                    ),
                  ),
                if (hasCarousel)
                  Positioned(
                    key: const ValueKey('nearby-breweries-carousel-position'),
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: SizedBox(
                      height: 210,
                      child: _BreweryCarousel(
                        breweries: breweries,
                        selectedBreweryId: state.selectedBreweryId,
                        onSelected: mapController.selectBrewery,
                        onLoadMore: () => context
                            .read<NearbyBreweriesBloc>()
                            .add(const NearbyBreweriesNextPageRequested()),
                        onDetails: (brewery) =>
                            onOpenBreweryDetails(brewery, location),
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: hasCarousel ? 230 : 24,
                  child: FloatingActionButton(
                    tooltip: state.isRefreshingLocation
                        ? labels.updatingLocation
                        : labels.myLocation,
                    onPressed: mapController.refreshLocation,
                    child: state.isRefreshingLocation
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, _NearbyBreweriesLabels labels) =>
      Drawer(
        child: SafeArea(
          child: Builder(
            builder: (drawerContext) =>
                BlocBuilder<AppSettingsCubit, AppSettingsState>(
                  bloc: settingsCubit,
                  builder: (context, settings) => ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/app_logo.svg',
                          semanticsLabel: labels.appTitle,
                          fit: BoxFit.contain,
                        ),
                      ),
                      ListTile(
                        key: const ValueKey('open-brewery-catalog'),
                        leading: const Icon(Icons.public),
                        title: Text(labels.allBreweries),
                        onTap: () {
                          Scaffold.of(drawerContext).closeDrawer();
                          onOpenCatalog();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        key: const ValueKey('dark-mode-toggle'),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: Text(labels.darkMode),
                        value: settings.themeMode == ThemeMode.dark,
                        onChanged: (isDark) => settingsCubit.setThemeMode(
                          isDark ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(labels.language),
                        trailing: DropdownButton<Locale>(
                          key: const ValueKey('language-selector'),
                          value: settings.locale,
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(
                              value: const Locale('en'),
                              child: Text(labels.english),
                            ),
                            DropdownMenuItem(
                              value: const Locale('es'),
                              child: Text(labels.spanish),
                            ),
                          ],
                          onChanged: (locale) {
                            if (locale != null) settingsCubit.setLocale(locale);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

  Widget _buildFilterChips(
    BuildContext context,
    NearbyBreweriesState state,
    _NearbyBreweriesLabels labels,
  ) {
    final activeTypes = state.activeTypes;
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
              onSelected: (_) => mapController.clearFilters(),
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
                onSelected: (_) =>
                    mapController.toggleBreweryType(type, activeTypes),
              ),
            ),
        ],
      ),
    );
  }
}

String _errorMessage(BuildContext context, NearbyBreweriesError state) {
  final l10n = AppLocalizations.of(context)!;
  if (state.exception is LocationPermissionDeniedException) {
    return l10n.locationPermissionDenied;
  }
  if (state.exception is LocationServiceDisabledException) {
    return l10n.locationServiceDisabled;
  }
  if (state.exception is LocationUnavailableException) {
    return l10n.locationUnavailable;
  }
  return state.isSearchError ? l10n.searchError : l10n.mapLoadError;
}

String _locationRefreshErrorMessage(
  BuildContext context,
  Object error, {
  required bool hasLastKnownLocation,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (hasLastKnownLocation) return l10n.locationUsingLastKnown;
  if (error is LocationPermissionDeniedException) {
    return l10n.locationPermissionDenied;
  }
  if (error is LocationServiceDisabledException) {
    return l10n.locationServiceDisabled;
  }
  return l10n.locationUnavailable;
}

class _MapErrorNotice extends StatelessWidget {
  const _MapErrorNotice({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(12),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}

class _BrewerySearchField extends StatefulWidget {
  const _BrewerySearchField({
    required this.labels,
    required this.onChanged,
    required this.onClear,
  });

  final _NearbyBreweriesLabels labels;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_BrewerySearchField> createState() => _BrewerySearchFieldState();
}

class _BrewerySearchFieldState extends State<_BrewerySearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('brewery-search-island'),
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    elevation: 8,
    shadowColor: const Color(0x33000000),
    borderRadius: BorderRadius.circular(32),
    child: SizedBox(
      height: 56,
      child: TextField(
        key: const ValueKey('brewery-search-field'),
        controller: _controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.labels.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: widget.labels.clearSearch,
                    onPressed: () {
                      _controller.clear();
                      widget.onClear();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: widget.onChanged,
      ),
    ),
  );
}

class _BreweryCarousel extends StatefulWidget {
  const _BreweryCarousel({
    required this.breweries,
    required this.selectedBreweryId,
    required this.onSelected,
    required this.onLoadMore,
    required this.onDetails,
  });

  static const _cardExtent = 296.0;

  final List<Brewery> breweries;
  final String? selectedBreweryId;
  final ValueChanged<Brewery> onSelected;
  final VoidCallback onLoadMore;
  final ValueChanged<Brewery> onDetails;

  @override
  State<_BreweryCarousel> createState() => _BreweryCarouselState();
}

class _BreweryCarouselState extends State<_BreweryCarousel> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant _BreweryCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBreweryId != widget.selectedBreweryId) {
      _scrollToSelectedBrewery();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelectedBrewery() {
    final selectedId = widget.selectedBreweryId;
    if (selectedId == null || !_controller.hasClients) return;
    final index = widget.breweries.indexWhere(
      (brewery) => brewery.id == selectedId,
    );
    if (index < 0) return;
    final target = (index * _BreweryCarousel._cardExtent).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _handleScroll() {
    if (_controller.hasClients &&
        _controller.position.extentAfter <= _BreweryCarousel._cardExtent) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const ValueKey('brewery-carousel'),
    controller: _controller,
    scrollDirection: Axis.horizontal,
    itemExtent: _BreweryCarousel._cardExtent,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    itemCount: widget.breweries.length,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _BreweryCard(
        brewery: widget.breweries[index],
        selected: widget.breweries[index].id == widget.selectedBreweryId,
        onSelected: () => widget.onSelected(widget.breweries[index]),
        onDetails: () => widget.onDetails(widget.breweries[index]),
      ),
    ),
  );
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
      UserLocation.areCoordinatesValid(latitude, longitude);
}

class _NearbyBreweriesLabels {
  const _NearbyBreweriesLabels(this.l10n);

  factory _NearbyBreweriesLabels.of(BuildContext context) =>
      _NearbyBreweriesLabels(AppLocalizations.of(context)!);

  final AppLocalizations l10n;

  String get appTitle => l10n.appTitle;
  String get nearbyBreweries => l10n.nearbyBreweries;
  String get allBreweries => l10n.allBreweries;
  String get darkMode => l10n.darkMode;
  String get language => l10n.language;
  String get english => l10n.english;
  String get spanish => l10n.spanish;
  String get searchHint => l10n.searchBreweriesHint;
  String get clearSearch => l10n.clearSearch;
  String get moreDetails => l10n.moreDetails;
  String get myLocation => l10n.myLocation;
  String get updatingLocation => l10n.updatingLocation;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
