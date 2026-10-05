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
  MapboxMap? _nearbyMap;
  UserLocation? _pendingRecenterLocation;

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
    onMapReady: _onNearbyMapReady,
    onMapDisposed: _onNearbyMapDisposed,
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
    final cameraLocation = destinationLocation?.isValid == true
      ? destinationLocation
      : userLocation ?? destinationLocation;

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
    if (!location.isValid) return;
    final map = _nearbyMap;
    if (map == null) {
      _pendingRecenterLocation = location;
      _viewportController.moveTo(_cameraAt(location));
      return;
    }
    await _moveMapToLocation(map, location);
  }

  void _onNearbyMapReady(MapboxMap map) {
    _nearbyMap = map;
    final pendingLocation = _pendingRecenterLocation;
    _pendingRecenterLocation = null;
    if (pendingLocation != null) {
      unawaited(_moveMapToLocation(map, pendingLocation));
    }
  }

  void _onNearbyMapDisposed(MapboxMap map) {
    if (identical(_nearbyMap, map)) _nearbyMap = null;
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
    this.onMapReady,
    this.onMapDisposed,
    required this.viewportController,
  });

  final UserLocation? userLocation;
  final UserLocation? initialCameraLocation;
  final List<Brewery> breweries;
  final String? selectedBreweryId;
  final BreweryRoute? route;
  final double routeBottomInset;
  final ValueChanged<String> onBrewerySelected;
  final ValueChanged<MapboxMap>? onMapReady;
  final ValueChanged<MapboxMap>? onMapDisposed;
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
  Future<void> _pendingRouteUpdate = Future<void>.value();
  final Map<String, PointAnnotation> _breweryAnnotations = {};
  final Map<String, UserLocation> _breweryPositions = {};
  PointAnnotation? _userLocationAnnotation;
  UserLocation? _lastUserLocation;
  String? _lastSelectedBreweryId;

  @override
  void didUpdateWidget(covariant _MapboxMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCameraLocation != widget.initialCameraLocation) {
      final location = widget.initialCameraLocation;
      if (location != null && location.isValid) {
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
    try {
      await _initializeMap(map);
    } on Exception catch (error, stackTrace) {
      debugPrint('Unable to initialize Mapbox: $error\n$stackTrace');
    }
  }

  Future<void> _initializeMap(MapboxMap map) async {
    _map = map;
    widget.onMapReady?.call(map);

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
    _pendingRouteUpdate = _pendingRouteUpdate
        .then((_) => _updateRoute())
        .catchError((Object error) {
          debugPrint('Unable to update Mapbox route: $error');
        });
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

    final location = widget.userLocation;
    final validLocation = location != null && location.isValid
        ? location
        : null;
    final desiredBreweries = <String, UserLocation>{};
    for (final brewery in widget.breweries) {
      final latitude = brewery.latitude;
      final longitude = brewery.longitude;
      if (latitude == null ||
          longitude == null ||
          !UserLocation.areCoordinatesValid(latitude, longitude)) {
        continue;
      }
      desiredBreweries[brewery.id] = UserLocation(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final removedIds = _breweryAnnotations.keys
        .where((id) => !desiredBreweries.containsKey(id))
        .toList(growable: false);
    if (removedIds.isNotEmpty) {
      await manager.deleteMulti(
        removedIds.map((id) => _breweryAnnotations[id]!).toList(),
      );
      for (final id in removedIds) {
        _breweryAnnotations.remove(id);
        _breweryPositions.remove(id);
      }
    }

    final newBreweryIds = <String>[];
    final newBreweryOptions = <PointAnnotationOptions>[];
    for (final entry in desiredBreweries.entries) {
      final id = entry.key;
      final position = entry.value;
      final annotation = _breweryAnnotations[id];
      if (annotation == null) {
        newBreweryIds.add(id);
        newBreweryOptions.add(
          PointAnnotationOptions(
            geometry: _point(position.latitude, position.longitude),
            image: breweryMarkerImage,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: id == widget.selectedBreweryId ? 1 : 0.8,
            customData: {'breweryId': id},
          ),
        );
        continue;
      }

      final positionChanged = !_sameLocation(_breweryPositions[id], position);
      final selectionChanged =
          (id == _lastSelectedBreweryId) != (id == widget.selectedBreweryId);
      if (positionChanged || selectionChanged) {
        annotation.geometry = _point(position.latitude, position.longitude);
        annotation.iconSize = id == widget.selectedBreweryId ? 1 : 0.8;
        await manager.update(annotation);
      }
      _breweryPositions[id] = position;
    }

    if (newBreweryOptions.isNotEmpty) {
      final created = await manager.createMulti(newBreweryOptions);
      for (var index = 0; index < created.length; index++) {
        final annotation = created[index];
        if (annotation != null) {
          final id = newBreweryIds[index];
          _breweryAnnotations[id] = annotation;
          _breweryPositions[id] = desiredBreweries[id]!;
        }
      }
    }

    if (validLocation == null) {
      final annotation = _userLocationAnnotation;
      if (annotation != null) await manager.delete(annotation);
      _userLocationAnnotation = null;
      _lastUserLocation = null;
    } else if (_userLocationAnnotation == null) {
      _userLocationAnnotation = await manager.create(
        PointAnnotationOptions(
          geometry: _point(validLocation.latitude, validLocation.longitude),
          image: userLocationImage,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1,
          customData: const {'userLocation': true},
        ),
      );
      _lastUserLocation = validLocation;
    } else if (!_sameLocation(_lastUserLocation, validLocation)) {
      final annotation = _userLocationAnnotation!;
      annotation.geometry = _point(
        validLocation.latitude,
        validLocation.longitude,
      );
      await manager.update(annotation);
      _lastUserLocation = validLocation;
    }

    _lastSelectedBreweryId = widget.selectedBreweryId;
  }

  @override
  void dispose() {
    _annotationTapEvents?.cancel();
    final map = _map;
    if (map != null) widget.onMapDisposed?.call(map);
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

Future<void> _moveMapToLocation(MapboxMap map, UserLocation location) =>
    map.flyTo(
      CameraOptions(
        center: _point(location.latitude, location.longitude),
        zoom: InitialMapCamera.locationZoom,
      ),
      MapAnimationOptions(duration: 700),
    );

Future<Uint8List> _loadMapIcon(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Point _point(double latitude, double longitude) =>
    Point(coordinates: Position(longitude, latitude));

bool _sameLocation(UserLocation? first, UserLocation? second) =>
    first?.latitude == second?.latitude &&
    first?.longitude == second?.longitude;
