import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../domain/entities/brewery.dart';
import '../../domain/entities/brewery_route.dart';
import '../../domain/entities/user_location.dart';
import 'brewery_map_adapter.dart';
import 'initial_map_camera.dart';

class MapboxBreweryMapAdapter implements BreweryMapAdapter {
  final ViewportController _viewportController = ViewportController();

  @override
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) => _MapboxMapSurface(
    key: const ValueKey('mapbox-map-surface'),
    userLocation: userLocation,
    initialCameraLocation: initialCameraLocation,
    breweries: breweries,
    selectedBreweryId: selectedBreweryId,
    onBrewerySelected: onBrewerySelected,
    viewportController: _viewportController,
  );

  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  }) {
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    final destinationLocation = latitude != null && longitude != null
        ? UserLocation(latitude: latitude, longitude: longitude)
        : null;
    final cameraLocation = userLocation ?? destinationLocation;

    return _MapboxMapSurface(
      key: ValueKey('mapbox-brewery-map-${brewery.id}'),
      userLocation: userLocation,
      initialCameraLocation: cameraLocation,
      breweries: [brewery],
      selectedBreweryId: brewery.id,
      route: route,
      routeBottomInset: bottomPanelHeight,
      onBrewerySelected: (_) {},
      viewportController: ViewportController(),
    );
  }

  @override
  Future<void> recenter(UserLocation location) async {
    if (!_isValidLocation(location)) return;
    _viewportController.moveTo(_cameraAt(location));
  }
}

class _MapboxMapSurface extends StatefulWidget {
  const _MapboxMapSurface({
    super.key,
    required this.userLocation,
    required this.initialCameraLocation,
    required this.breweries,
    required this.selectedBreweryId,
    this.route,
    this.routeBottomInset = 0,
    required this.onBrewerySelected,
    required this.viewportController,
  });

  final UserLocation? userLocation;
  final UserLocation? initialCameraLocation;
  final List<Brewery> breweries;
  final String? selectedBreweryId;
  final BreweryRoute? route;
  final double routeBottomInset;
  final ValueChanged<String> onBrewerySelected;
  final ViewportController viewportController;

  @override
  State<_MapboxMapSurface> createState() => _MapboxMapSurfaceState();
}

class _MapboxMapSurfaceState extends State<_MapboxMapSurface> {
  PointAnnotationManager? _annotationManager;
  PolylineAnnotationManager? _routeAnnotationManager;
  MapboxMap? _map;
  Cancelable? _annotationTapEvents;
  Uint8List? _breweryMarkerImage;
  Uint8List? _userLocationImage;
  Future<void> _pendingAnnotationUpdate = Future<void>.value();

  @override
  void didUpdateWidget(covariant _MapboxMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCameraLocation != widget.initialCameraLocation) {
      final location = widget.initialCameraLocation;
      if (location != null && _isValidLocation(location)) {
        widget.viewportController.moveTo(_cameraAt(location));
      }
    }
    if (oldWidget.userLocation != widget.userLocation ||
        oldWidget.breweries != widget.breweries ||
        oldWidget.selectedBreweryId != widget.selectedBreweryId) {
      _queueAnnotationUpdate();
    }
    if (oldWidget.route != widget.route ||
        oldWidget.routeBottomInset != widget.routeBottomInset) {
      _queueRouteUpdate();
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;

    await map.compass.updateSettings(
      CompassSettings(
        enabled: true,
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: 150.0,
        marginRight: 16.0,
      ),
    );

    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    await map.logo.updateSettings(
      LogoSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 16.0,
        marginRight: 16.0,
      ),
    );

    await map.attribution.updateSettings(
      AttributionSettings(
        position: OrnamentPosition.BOTTOM_LEFT,
        marginBottom: 16.0,
        marginLeft: 16.0,
      ),
    );

    final breweryMarkerImage = await _loadMapIcon(
      'assets/icons/ic_brewery_marker.png',
    );
    final userLocationImage = await _loadMapIcon(
      'assets/icons/ic_user_location.png',
    );
    if (!mounted) return;
    _breweryMarkerImage = breweryMarkerImage;
    _userLocationImage = userLocationImage;
    final manager = await map.annotations.createPointAnnotationManager();
    await manager.setIconAllowOverlap(true);
    await manager.setIconIgnorePlacement(true);
    if (!mounted) return;
    _annotationManager = manager;
    _routeAnnotationManager = await map.annotations
        .createPolylineAnnotationManager();
    if (!mounted) return;
    _annotationTapEvents = manager.tapEvents(
      onTap: (annotation) {
        final breweryId = annotation.customData?['breweryId'];
        if (breweryId is String) widget.onBrewerySelected(breweryId);
      },
    );
    _queueAnnotationUpdate();
    _queueRouteUpdate();
  }

  void _queueRouteUpdate() {
    unawaited(_updateRoute());
  }

  Future<void> _updateRoute() async {
    final manager = _routeAnnotationManager;
    if (manager == null || !mounted) return;
    await manager.deleteAll();

    final route = widget.route;
    if (route == null || route.coordinates.length < 2) return;
    final lineCoordinates = route.coordinates
        .map((location) => Position(location.longitude, location.latitude))
        .toList(growable: false);
    final points = lineCoordinates
        .map((position) => Point(coordinates: position))
        .toList(growable: false);
    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: lineCoordinates),
        lineColor: const Color(0xff4285f4).toARGB32(),
        lineWidth: 6,
        lineBorderColor: const Color(0xffffffff).toARGB32(),
        lineBorderWidth: 2,
        lineJoin: LineJoin.ROUND,
      ),
    );

    final map = _map;
    if (map == null || !mounted) return;
    final camera = await map.cameraForCoordinatesPadding(
      points,
      CameraOptions(),
      MbxEdgeInsets(
        top: 48,
        left: 36,
        bottom: widget.routeBottomInset + 24,
        right: 36,
      ),
      15,
      null,
    );
    await map.easeTo(camera, MapAnimationOptions(duration: 900));
  }

  void _queueAnnotationUpdate() {
    _pendingAnnotationUpdate = _pendingAnnotationUpdate
        .then((_) => _updateAnnotations())
        .catchError((Object error) {
          debugPrint('Unable to update Mapbox annotations: $error');
        });
  }

  Future<void> _updateAnnotations() async {
    final manager = _annotationManager;
    final breweryMarkerImage = _breweryMarkerImage;
    final userLocationImage = _userLocationImage;
    if (manager == null ||
        breweryMarkerImage == null ||
        userLocationImage == null ||
        !mounted) {
      return;
    }

    final annotations = <PointAnnotationOptions>[];
    final location = widget.userLocation;
    if (location != null && _isValidLocation(location)) {
      annotations.add(
        PointAnnotationOptions(
          geometry: _point(location.latitude, location.longitude),
          image: userLocationImage,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1,
          customData: const {'userLocation': true},
        ),
      );
    }
    for (final brewery in widget.breweries) {
      final latitude = brewery.latitude;
      final longitude = brewery.longitude;
      if (latitude == null ||
          longitude == null ||
          !_isValidCoordinates(latitude, longitude)) {
        continue;
      }
      final isSelected = brewery.id == widget.selectedBreweryId;
      annotations.add(
        PointAnnotationOptions(
          geometry: _point(latitude, longitude),
          image: breweryMarkerImage,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: isSelected ? 1 : 0.8,
          customData: {'breweryId': brewery.id},
        ),
      );
    }

    await manager.deleteAll();
    if (annotations.isNotEmpty) await manager.createMulti(annotations);
  }

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = InitialMapCamera.resolve(widget.initialCameraLocation);
    return MapWidget(
      styleUri: MapboxStyles.DARK,
      viewport: CameraViewportState(
        center: _point(camera.center.latitude, camera.center.longitude),
        zoom: camera.zoom,
      ),
      viewportController: widget.viewportController,
      onMapCreated: _onMapCreated,
    );
  }
}

CameraViewportState _cameraAt(UserLocation location) => CameraViewportState(
  center: _point(location.latitude, location.longitude),
  zoom: InitialMapCamera.locationZoom,
);

Future<Uint8List> _loadMapIcon(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Point _point(double latitude, double longitude) =>
    Point(coordinates: Position(longitude, latitude));

bool _isValidLocation(UserLocation location) =>
    _isValidCoordinates(location.latitude, location.longitude);

bool _isValidCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;
