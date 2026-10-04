// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_nearest_breweries.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/nearby_breweries_bloc.dart';
import 'package:breweries_for_the_world/main.dart';

void main() {
  testWidgets('shows the nearby breweries loading state', (tester) async {
    final bloc = NearbyBreweriesBloc(
      getNearestBreweries: GetNearestBreweries(_EmptyBreweryRepository()),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(MyApp(nearbyBreweriesBloc: bloc));

    expect(find.text('Nearby breweries'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Nearby breweries'))).brightness,
      Brightness.dark,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Flutter Demo Home Page'), findsNothing);
  });
}

class _EmptyBreweryRepository implements BreweryRepository {
  @override
  Future<List<Brewery>> getNearestBreweries({
    required double latitude,
    required double longitude,
    int limit = 40,
  }) async => [];

  @override
  Future<List<Brewery>> searchBreweries({required String query}) async => [];
}
