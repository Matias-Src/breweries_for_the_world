# Breweries for the World

A Flutter app for discovering nearby breweries and exploring a worldwide catalog.

## How to Run

Requirements: Flutter 3.41.2, Dart 3.11.0, and a public Mapbox access token.

1. Install dependencies and create the local configuration file:

   ```powershell
   flutter pub get
   Copy-Item .env.example .env
   ```

2. Replace `MAPBOX_ACCESS_TOKEN` in `.env` with your public Mapbox token. The file uses `KEY=VALUE` format and is not bundled as an asset.
3. Regenerate the Envied output whenever `.env` changes, then run the app on a device or emulator:

   ```powershell
   dart run build_runner build
   flutter run
   ```

Run the tests and static analysis with:

```powershell
flutter test
flutter analyze
```

The public token is embedded in the compiled app and can be extracted. Use a public token with minimal permissions and platform restrictions; do not include private credentials.
Envied obfuscation makes casual inspection less direct but does not make client-side values secret.

## Completed

- The required catalog-to-detail flow: a paginated brewery list showing name, type, and city, plus a detail page with address, phone, and website.
- Loading, error with retry, empty, and no-search-results states in the catalog; detail requests also show loading and recoverable error states.
- The selected bonus: a Mapbox map with nearby brewery markers and user location. Selecting a marker selects the same brewery in the synchronized carousel; brewery-type filters are available on the map and catalog.
- Debounced name search (300 ms), catalog filters and sorting, and walking or driving directions when brewery coordinates and user location are available.
- Layered domain/data/presentation code using BLoC/Cubit, `get_it` and `injectable`. Repositories convert network and parsing failures into typed domain exceptions, which presentation state handles.
- English and Spanish localization, light and dark themes, and persisted preferences.
- Tests for model parsing, repository errors, catalog pagination/search, location, directions, and app navigation. Run them with `flutter test`.

The required list/detail flow is available through the catalog and detail pages. The nearby map is an additional screen for the selected location-based bonus.

## Out of Scope

- City or address geocoding: search is limited to brewery names.
- Public transit recommendations or multimodal directions; only walking and driving routes are available.
- Offline access to catalog data.

## Decisions and Trade-offs

- OpenBreweryDB provides brewery discovery and pagination without requiring a custom backend, but coverage and data quality depend on the service. Coordinates and other fields may be missing.
- Nearby queries request up to 40 results ordered by distance; this does not necessarily include every brewery within a fixed radius. Only results with valid coordinates can appear as map markers or have directions.
- `BreweryModel` currently extends the domain `Brewery` entity, so API parsing and the domain representation share one type instead of using a separate DTO-to-entity mapper. A dedicated DTO and mapper would improve layer isolation if the data contract grows.
- The app uses a public Mapbox token to initialize the map. This is practical for a mobile client, but the token is not secret and should be restricted in Mapbox settings.

## Improvements with More Time

- Profile performance and reduce work on the main isolate; move processing identified as CPU-intensive, such as calculations or transformations of large lists, to isolates where profiling justifies it.
- Add a local cache for the catalog and recent results to speed up startup and provide a degraded offline experience.
- Expand integration testing on Android and iOS devices, especially around permissions, the map, and real navigation flows.
