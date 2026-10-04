# breweries_for_the_world

A Flutter app for discovering nearby breweries.

## Getting Started

Copy `.env.example` to `.env` and replace the example `MAPBOX_ACCESS_TOKEN` with your Mapbox public token. The file uses JSON format and is passed as a build-time define; it is not bundled as an asset.

Run the app with:

```powershell
flutter run --dart-define-from-file=.env
```

The token is embedded in the compiled app and can be extracted. Use only a public Mapbox token with the minimum required permissions and appropriate restrictions; never put private credentials in this file.

For Flutter development resources:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
