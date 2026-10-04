import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../domain/entities/brewery.dart';
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
  Widget buildBreweryMap({required Brewery brewery}) {
    final latitude = brewery.latitude;
    final longitude = brewery.longitude;
    final cameraLocation = latitude != null && longitude != null
        ? UserLocation(latitude: latitude, longitude: longitude)
        : null;

    return _MapboxMapSurface(
      key: ValueKey('mapbox-brewery-map-${brewery.id}'),
      userLocation: null,
      initialCameraLocation: cameraLocation,
      breweries: [brewery],
      selectedBreweryId: brewery.id,
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
    required this.onBrewerySelected,
    required this.viewportController,
  });

  final UserLocation? userLocation;
  final UserLocation? initialCameraLocation;
  final List<Brewery> breweries;
  final String? selectedBreweryId;
  final ValueChanged<String> onBrewerySelected;
  final ViewportController viewportController;

  @override
  State<_MapboxMapSurface> createState() => _MapboxMapSurfaceState();
}

class _MapboxMapSurfaceState extends State<_MapboxMapSurface> {
  CircleAnnotationManager? _annotationManager;
  Cancelable? _annotationTapEvents;
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
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    final manager = await map.annotations.createCircleAnnotationManager();
    if (!mounted) return;
    _annotationManager = manager;
    _annotationTapEvents = manager.tapEvents(
      onTap: (annotation) {
        final breweryId = annotation.customData?['breweryId'];
        if (breweryId is String) widget.onBrewerySelected(breweryId);
      },
    );
    _queueAnnotationUpdate();
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
    if (manager == null || !mounted) return;

    final annotations = <CircleAnnotationOptions>[];
    final location = widget.userLocation;
    if (location != null && _isValidLocation(location)) {
      annotations.add(
        CircleAnnotationOptions(
          geometry: _point(location.latitude, location.longitude),
          circleColor: const Color(0xff245ac4).toARGB32(),
          circleRadius: 10,
          circleStrokeColor: const Color(0xffffffff).toARGB32(),
          circleStrokeWidth: 3,
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
        CircleAnnotationOptions(
          geometry: _point(latitude, longitude),
          circleColor:
              (isSelected ? const Color(0xffb24b28) : const Color(0xff0b776b))
                  .toARGB32(),
          circleRadius: isSelected ? 11 : 8,
          circleStrokeColor: const Color(0xffffffff).toARGB32(),
          circleStrokeWidth: 2,
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
