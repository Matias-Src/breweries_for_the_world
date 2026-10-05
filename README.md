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

- Mapbox map with user location, nearby breweries, a synchronized carousel, and brewery-type filters.
- Paginated catalog with name search, filters, and sorting options.
- Brewery details with address, phone number, website, and walking or driving directions when coordinates and user location are available.
- Loading, error, and retry states; English and Spanish support; light and dark themes; and persisted preferences.
- Layered architecture with BLoC/Cubit and repositories, plus unit and flow tests for data, location, search, directions, and navigation.

## Out of Scope

- City or address geocoding: search is limited to brewery names.
- Public transit recommendations or multimodal directions; only walking and driving routes are available.
- Offline access to catalog data.

## Decisions and Trade-offs

- OpenBreweryDB provides brewery discovery and pagination without requiring a custom backend, but coverage and data quality depend on the service. Coordinates and other fields may be missing.
- Nearby queries request up to 40 results ordered by distance; this does not necessarily include every brewery within a fixed radius. Only results with valid coordinates can appear as map markers or have directions.
- The app uses a public Mapbox token to initialize the map. This is practical for a mobile client, but the token is not secret and should be restricted in Mapbox settings.

## Improvements with More Time

- Profile performance and reduce work on the main isolate; move processing identified as CPU-intensive, such as calculations or transformations of large lists, to isolates where profiling justifies it.
- Add a local cache for the catalog and recent results to speed up startup and provide a degraded offline experience.
- Expand integration testing on Android and iOS devices, especially around permissions, the map, and real navigation flows.
