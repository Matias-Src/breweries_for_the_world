import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery_route.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/user_location.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/search_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_event.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_state.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/map/brewery_map_adapter.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/pages/nearby_breweries_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreweryRepository extends Mock implements BreweryRepository {}

class _RecordingBreweryMapAdapter implements BreweryMapAdapter {
  UserLocation? userLocation;
  List<Brewery> breweries = const [];
  String? selectedBreweryId;
  ValueChanged<String>? onBrewerySelected;
  final List<UserLocation> recenterRequests = [];

  @override
  Widget buildMap({
    required UserLocation? userLocation,
    required UserLocation? initialCameraLocation,
    required List<Brewery> breweries,
    required String? selectedBreweryId,
    required ValueChanged<String> onBrewerySelected,
  }) {
    this.userLocation = userLocation;
    this.breweries = breweries;
    this.selectedBreweryId = selectedBreweryId;
    this.onBrewerySelected = onBrewerySelected;

    return ColoredBox(
      key: const ValueKey('map-surface'),
      color: Colors.black,
      child: Align(
        alignment: Alignment.center,
        child: Wrap(
          children: [
            for (final brewery in breweries)
              IconButton(
                key: ValueKey('marker-${brewery.id}'),
                tooltip: brewery.name,
                onPressed: () => onBrewerySelected(brewery.id),
                icon: Icon(
                  selectedBreweryId == brewery.id
                      ? Icons.location_on
                      : Icons.place,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBreweryMap({
    required Brewery brewery,
    required UserLocation? userLocation,
    required BreweryRoute? route,
    required double bottomPanelHeight,
  }) => ColoredBox(
    key: ValueKey('detail-map-${brewery.id}'),
    color: Colors.black,
  );

  @override
  Future<void> recenter(UserLocation location) async {
    recenterRequests.add(location);
  }
}

void main() {
  const userLocation = UserLocation(latitude: 50.1, longitude: 11.2);
  const breweryWithCoordinates = Brewery(
    id: 'brewery-valid',
    name: 'Located Brewery',
    breweryType: 'micro',
    latitude: 50.2,
    longitude: 11.3,
  );
  const breweryWithoutCoordinates = Brewery(
    id: 'brewery-no-coordinates',
    name: 'Unlocated Brewery',
    breweryType: 'brewpub',
  );
  const breweryWithPartialCoordinates = Brewery(
    id: 'brewery-partial-coordinates',
    name: 'Partially Located Brewery',
    breweryType: 'nano',
    latitude: 50.3,
  );
  const breweryWithInvalidCoordinates = Brewery(
    id: 'brewery-invalid-coordinates',
    name: 'Invalid Coordinates Brewery',
    breweryType: 'regional',
    latitude: 91,
    longitude: 11.4,
  );

  testWidgets('shows all 40 nearby breweries in a horizontal carousel', (
    tester,
  ) async {
    final breweries = List.generate(
      40,
      (index) => Brewery(
        id: 'brewery-$index',
        name: 'Brewery $index',
        breweryType: 'micro',
        latitude: 40 + index / 100,
        longitude: -70,
      ),
    );
    await _pumpLoadedMapPage(tester, breweries);

    final carousel = find.byKey(const ValueKey('brewery-carousel'));
    expect(carousel, findsOneWidget);
    expect(
      find.byKey(const ValueKey('brewery-card-brewery-0')),
      findsOneWidget,
    );

    for (
      var attempt = 0;
      attempt < 20 &&
          find
              .byKey(const ValueKey('brewery-card-brewery-39'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.drag(carousel, const Offset(-600, 0));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey('brewery-card-brewery-39')),
      findsOneWidget,
    );
  });

  testWidgets('searches breweries from the floating search island', (
    tester,
  ) async {
    const searchResult = Brewery(
      id: 'brewery-search-result',
      name: 'Search Result Brewery',
      breweryType: 'micro',
      latitude: 40.7,
      longitude: -73.9,
    );
    final searchRepository = _MockBreweryRepository();
    when(
      () => searchRepository.searchBreweries(query: 'search result'),
    ).thenAnswer((_) async => [searchResult]);
    final result = await _pumpLoadedMapPage(tester, const [
      breweryWithCoordinates,
    ], searchBreweries: SearchBreweries(searchRepository));

    final searchField = find.byKey(const ValueKey('brewery-search-field'));
    expect(find.byKey(const ValueKey('brewery-search-island')), findsOneWidget);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'search result');
    await tester.pumpAndSettle();

    expect(
      result.bloc.state,
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.breweries,
        'search results',
        const [searchResult],
      ),
    );
    expect(result.adapter.breweries, const [searchResult]);
  });

  testWidgets(
    'filters brewery cards and map markers immediately with type chips',
    (tester) async {
      const breweries = [
        Brewery(
          id: 'filter-micro',
          name: 'Micro Brewery',
          breweryType: 'micro',
          latitude: 45.1,
          longitude: -122.1,
        ),
        Brewery(
          id: 'filter-nano',
          name: 'Nano Brewery',
          breweryType: 'nano',
          latitude: 45.2,
          longitude: -122.2,
        ),
        Brewery(
          id: 'filter-brewpub',
          name: 'Brewpub Brewery',
          breweryType: 'brewpub',
          latitude: 45.3,
          longitude: -122.3,
        ),
      ];
      final result = await _pumpLoadedMapPage(tester, breweries);
      expect(
        find.byKey(const ValueKey('brewery-filter-carousel')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('brewery-type-micro')));
      await tester.pumpAndSettle();
      expect(
        result.bloc.state,
        isA<NearbyBreweriesSuccess>().having(
          (state) => state.breweries.map((brewery) => brewery.id).toList(),
          'micro-filtered breweries',
          ['filter-micro'],
        ),
      );
      expect(result.adapter.breweries, [breweries.first]);
      expect(
        find.byKey(const ValueKey('brewery-card-filter-brewpub')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('brewery-type-nano')));
      await tester.pumpAndSettle();
      expect(
        result.bloc.state,
        isA<NearbyBreweriesSuccess>()
            .having(
              (state) => state.breweries.map((brewery) => brewery.id).toList(),
              'filtered breweries',
              ['filter-micro', 'filter-nano'],
            )
            .having((state) => state.activeTypes, 'active types', {
              'micro',
              'nano',
            }),
      );
      expect(result.adapter.breweries, breweries.take(2).toList());

      await tester.tap(find.byKey(const ValueKey('brewery-type-all')));
      await tester.pumpAndSettle();
      expect(
        result.bloc.state,
        isA<NearbyBreweriesSuccess>()
            .having((state) => state.breweries, 'all breweries', breweries)
            .having((state) => state.activeTypes, 'active types', isEmpty),
      );
    },
  );

  testWidgets(
    'omits missing optional fields and avoids duplicate address segments',
    (tester) async {
      const brewery = Brewery(
        id: 'brewery-address',
        name: 'Address Brewery',
        breweryType: 'regional',
        address1: '123 Main Street',
        street: '123 Main Street',
        city: 'Portland',
        state: 'Oregon',
        postalCode: '97201',
        country: 'US',
        latitude: 45.5,
        longitude: -122.6,
      );
      await _pumpLoadedMapPage(tester, [brewery]);

      final card = find.byKey(const ValueKey('brewery-card-brewery-address'));
      expect(card, findsOneWidget);
      final renderedText = tester
          .widgetList<RichText>(
            find.descendant(of: card, matching: find.byType(RichText)),
          )
          .map((text) => text.text.toPlainText())
          .join('\n');

      expect(
        find.descendant(of: card, matching: find.text('Phone')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Address')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Website')),
        findsNothing,
      );
      expect(
        RegExp(
          RegExp.escape('123 Main Street'),
        ).allMatches(renderedText).length,
        1,
      );
    },
  );

  testWidgets('selecting a carousel card recenters and highlights its marker', (
    tester,
  ) async {
    const brewery = Brewery(
      id: 'brewery-card-selection',
      name: 'Card Selection Brewery',
      breweryType: 'micro',
      latitude: 41.2,
      longitude: -72.4,
    );
    final result = await _pumpLoadedMapPage(tester, [brewery]);

    await tester.tap(
      find.byKey(const ValueKey('brewery-card-brewery-card-selection')),
    );
    await tester.pumpAndSettle();

    expect(
      result.bloc.state,
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.selectedBreweryId,
        'selected brewery id',
        brewery.id,
      ),
    );
    expect(result.adapter.selectedBreweryId, brewery.id);
    expect(result.adapter.recenterRequests, [
      const UserLocation(latitude: 41.2, longitude: -72.4),
    ]);

    await tester.tap(
      find.byKey(const ValueKey('brewery-card-brewery-card-selection')),
    );
    await tester.pumpAndSettle();

    expect(
      result.bloc.state,
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.selectedBreweryId,
        'deselected brewery id',
        isNull,
      ),
    );
    expect(result.adapter.selectedBreweryId, isNull);
    expect(result.adapter.recenterRequests, [
      const UserLocation(latitude: 41.2, longitude: -72.4),
      userLocation,
    ]);
  });

  testWidgets('filtering out the selected brewery deselects and recenters', (
    tester,
  ) async {
    const selectedBrewery = Brewery(
      id: 'selected-nano',
      name: 'Selected Nano Brewery',
      breweryType: 'nano',
      latitude: 41.2,
      longitude: -72.4,
    );
    const remainingBrewery = Brewery(
      id: 'remaining-micro',
      name: 'Remaining Micro Brewery',
      breweryType: 'micro',
      latitude: 41.3,
      longitude: -72.5,
    );
    final result = await _pumpLoadedMapPage(tester, const [
      selectedBrewery,
      remainingBrewery,
    ]);

    await tester.tap(find.byKey(const ValueKey('brewery-card-selected-nano')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('brewery-type-micro')));
    await tester.pumpAndSettle();

    expect(
      result.bloc.state,
      isA<NearbyBreweriesSuccess>()
          .having((state) => state.breweries, 'filtered breweries', const [
            remainingBrewery,
          ])
          .having(
            (state) => state.selectedBreweryId,
            'selected brewery id',
            isNull,
          ),
    );
    expect(result.adapter.selectedBreweryId, isNull);
    expect(result.adapter.recenterRequests, [
      const UserLocation(latitude: 41.2, longitude: -72.4),
      userLocation,
    ]);

    await tester.tap(find.byKey(const ValueKey('brewery-type-all')));
    await tester.pumpAndSettle();

    expect(
      result.bloc.state,
      isA<NearbyBreweriesSuccess>().having(
        (state) => state.selectedBreweryId,
        'selection after clearing the filter',
        isNull,
      ),
    );
  });

  testWidgets('selecting a marker scrolls its card into view', (tester) async {
    final breweries = List.generate(
      40,
      (index) => Brewery(
        id: 'brewery-$index',
        name: 'Brewery $index',
        breweryType: 'micro',
        latitude: 40 + index / 100,
        longitude: -70,
      ),
    );
    final result = await _pumpLoadedMapPage(tester, breweries);
    final card = find.byKey(const ValueKey('brewery-card-brewery-39'));

    await tester.tap(find.byKey(const ValueKey('marker-brewery-39')));
    await tester.pumpAndSettle();

    expect(result.adapter.selectedBreweryId, 'brewery-39');
    expect(card.hitTestable(), findsOneWidget);
  });

  testWidgets('opens a brewery detail view with its available contact data', (
    tester,
  ) async {
    const brewery = Brewery(
      id: 'brewery-details',
      name: 'Details Brewery',
      breweryType: 'brewpub',
      address1: '42 River Road',
      city: 'Bend',
      state: 'Oregon',
      phone: '555-0104',
      websiteUrl: 'https://details.example',
      latitude: 44.1,
      longitude: -121.3,
    );
    await _pumpLoadedMapPage(tester, [brewery], locale: const Locale('es'));

    final detailsAction = find.byKey(
      const ValueKey('brewery-details-brewery-details'),
    );
    expect(detailsAction, findsOneWidget);
    expect(find.text('Ver más detalles'), findsOneWidget);
    final cardRect = tester.getRect(
      find.byKey(const ValueKey('brewery-card-brewery-details')),
    );
    final buttonRect = tester.getRect(detailsAction);
    expect(buttonRect.center.dx, closeTo(cardRect.center.dx, 1));
    expect(cardRect.bottom - buttonRect.bottom, inInclusiveRange(4, 12));
    await tester.tap(find.text('Ver más detalles'));
    await tester.pumpAndSettle();

    final detailsView = find.byKey(
      const ValueKey('brewery-detail-view-brewery-details'),
    );
    expect(detailsView, findsOneWidget);
    expect(
      find.descendant(of: detailsView, matching: find.text('Details Brewery')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detailsView,
        matching: find.textContaining('42 River Road'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detailsView, matching: find.text('555-0104')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detailsView,
        matching: find.textContaining('details.example'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'starts at the user location and only maps breweries with valid coordinates',
    (tester) async {
      final repository = _MockBreweryRepository();
      when(
        () => repository.getNearestBreweries(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          limit: 40,
        ),
      ).thenAnswer(
        (_) async => [
          breweryWithCoordinates,
          breweryWithoutCoordinates,
          breweryWithPartialCoordinates,
          breweryWithInvalidCoordinates,
        ],
      );
      final bloc = NearbyBreweriesBloc(
        getNearestBreweries: GetNearestBreweries(repository),
      );
      final adapter = _RecordingBreweryMapAdapter();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: NearbyBreweriesMapPage(mapAdapter: adapter),
          ),
        ),
      );
      bloc.add(const LocationRequested(latitude: 50.1, longitude: 11.2));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('map-surface')), findsOneWidget);
      expect(adapter.userLocation, userLocation);
      expect(adapter.breweries, [breweryWithCoordinates]);
      expect(
        find.byKey(const ValueKey('marker-brewery-valid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('marker-brewery-no-coordinates')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marker-brewery-partial-coordinates')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('marker-brewery-invalid-coordinates')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'marker selection updates Bloc and location control recenters map',
    (tester) async {
      final repository = _MockBreweryRepository();
      when(
        () => repository.getNearestBreweries(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          limit: 40,
        ),
      ).thenAnswer((_) async => [breweryWithCoordinates]);
      final bloc = NearbyBreweriesBloc(
        getNearestBreweries: GetNearestBreweries(repository),
      );
      final adapter = _RecordingBreweryMapAdapter();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: NearbyBreweriesMapPage(mapAdapter: adapter),
          ),
        ),
      );
      bloc.add(const LocationRequested(latitude: 50.1, longitude: 11.2));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('marker-brewery-valid')));
      await tester.pump();

      expect(
        bloc.state,
        isA<NearbyBreweriesSuccess>().having(
          (state) => state.selectedBreweryId,
          'selected brewery id',
          breweryWithCoordinates.id,
        ),
      );
      expect(adapter.selectedBreweryId, breweryWithCoordinates.id);

      await tester.tap(find.byTooltip('My location'));

      expect(adapter.recenterRequests, [userLocation]);
    },
  );

  testWidgets('keeps the map usable before a location is available', (
    tester,
  ) async {
    final bloc = NearbyBreweriesBloc(
      getNearestBreweries: GetNearestBreweries(_MockBreweryRepository()),
    );
    final adapter = _RecordingBreweryMapAdapter();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: NearbyBreweriesMapPage(mapAdapter: adapter),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('map-surface')), findsOneWidget);
    expect(adapter.userLocation, isNull);
    expect(adapter.breweries, isEmpty);
    expect(find.byTooltip('My location'), findsNothing);
  });

  testWidgets('keeps the map hit area inside system safe insets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = NearbyBreweriesBloc(
      getNearestBreweries: GetNearestBreweries(_MockBreweryRepository()),
    );
    final adapter = _RecordingBreweryMapAdapter();
    addTearDown(bloc.close);
    const insets = EdgeInsets.only(left: 18, right: 18, bottom: 36);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            devicePixelRatio: 1,
            padding: insets,
            viewPadding: insets,
          ),
          child: BlocProvider.value(
            value: bloc,
            child: NearbyBreweriesMapPage(mapAdapter: adapter),
          ),
        ),
      ),
    );

    final mapRect = tester.getRect(find.byKey(const ValueKey('map-surface')));
    expect(mapRect.left, greaterThanOrEqualTo(insets.left));
    expect(mapRect.right, lessThanOrEqualTo(400 - insets.right));
    expect(mapRect.bottom, lessThanOrEqualTo(800 - insets.bottom));
  });
}

Future<({NearbyBreweriesBloc bloc, _RecordingBreweryMapAdapter adapter})>
_pumpLoadedMapPage(
  WidgetTester tester,
  List<Brewery> breweries, {
  SearchBreweries? searchBreweries,
  Locale locale = const Locale('en'),
}) async {
  final repository = _MockBreweryRepository();
  when(
    () => repository.getNearestBreweries(
      latitude: 50.1,
      longitude: 11.2,
      limit: 40,
    ),
  ).thenAnswer((_) async => breweries);
  final bloc = NearbyBreweriesBloc(
    getNearestBreweries: GetNearestBreweries(repository),
    searchBreweries: searchBreweries,
  );
  final adapter = _RecordingBreweryMapAdapter();
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: BlocProvider.value(
        value: bloc,
        child: NearbyBreweriesMapPage(mapAdapter: adapter),
      ),
    ),
  );
  bloc.add(const LocationRequested(latitude: 50.1, longitude: 11.2));
  await tester.pumpAndSettle();

  return (bloc: bloc, adapter: adapter);
}
