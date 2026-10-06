import 'package:bloc_test/bloc_test.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/errors/brewery_not_found_exception.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/repositories/brewery_repository.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/services/website_launcher.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/usecases/get_brewery_by_id.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_detail_cubit/brewery_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreweryRepository extends Mock implements BreweryRepository {}

class _MockWebsiteLauncher extends Mock implements WebsiteLauncher {}

void main() {
  late _MockBreweryRepository repository;
  late _MockWebsiteLauncher websiteLauncher;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.org'));
  });

  setUp(() {
    repository = _MockBreweryRepository();
    websiteLauncher = _MockWebsiteLauncher();
  });

  blocTest<BreweryDetailCubit, BreweryDetailState>(
    'emits an empty state when the brewery does not exist',
    setUp: () {
      when(
        () => repository.getBreweryById(id: 'missing'),
      ).thenThrow(const BreweryNotFoundException('missing'));
    },
    build: () => BreweryDetailCubit(
      breweryId: 'missing',
      getBreweryById: GetBreweryById(repository),
      mapRoute: null,
      websiteLauncher: websiteLauncher,
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<BreweryDetailLoading>(),
      isA<BreweryDetailEmpty>().having(
        (state) => state.breweryId,
        'brewery id',
        'missing',
      ),
    ],
  );

  test('validates and delegates website URLs to the launcher', () async {
    when(() => websiteLauncher.launch(any())).thenAnswer((_) async {});
    final cubit = BreweryDetailCubit(
      breweryId: 'brewery-1',
      getBreweryById: GetBreweryById(repository),
      mapRoute: null,
      websiteLauncher: websiteLauncher,
    );
    addTearDown(cubit.close);

    await cubit.openWebsite('example.org');
    await cubit.openWebsite('javascript:alert(1)');

    verify(
      () => websiteLauncher.launch(Uri.parse('https://example.org')),
    ).called(1);
    verifyNoMoreInteractions(websiteLauncher);
  });
}
