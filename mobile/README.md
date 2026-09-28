# DairyGo mobile app

The Flutter app used by Sacco milk collectors, administrators and board
members. It talks to the DairyGo API (`backend/`) at
`https://apis.dairy.urizon.co.ke` (see `lib/core/constants/api_constants.dart`).

## Run and build

The Flutter SDK is not on `PATH` on the development machine; use its full path
(`/home/joseph/flutter/bin/flutter`) or add it to `PATH`.

```bash
flutter pub get
flutter run                       # on a connected phone or emulator
flutter build apk --release --split-per-abi
```

`--split-per-abi` builds one APK per phone type, about 20 MB each instead of
one 56 MB file, which matters on slow connections. Almost every current phone
needs `app-arm64-v8a-release.apk`; very old phones need
`app-armeabi-v7a-release.apk`. The files are in
`build/app/outputs/flutter-apk/`.

Raise `version:` in `pubspec.yaml` for every release, and release the app
together with any backend change it depends on.

## Code layout

```text
lib/
  app/            router, shell (bottom bar / side rail), theme
  core/           network (Dio + interceptors), cache, pagination, layout, widgets
  features/<x>/   data (API + models) → domain → presentation (Riverpod + screens)
```

Models use freezed/json_serializable; after changing one run
`dart run build_runner build --delete-conflicting-outputs`.
Format with `dart format lib test` (generated `*.g.dart`/`*.freezed.dart`
excluded: restore them with `git checkout` if a formatter touches them).

## Tests

```bash
flutter analyze
flutter test                      # unit tests and the layout test
```

`test/layout` opens every main screen for each role (collector, admin, board,
and a Sacco with no price) on six screen sizes, from a 320 dp phone to a
tablet in landscape, at normal and the largest text size, and fails on any
layout error such as an overflow. It uses API responses captured from a test
server in `test/layout/fixtures`.

- Screenshots for review: `flutter test test/layout --update-goldens --dart-define=SCREENSHOTS=true`
  writes them to `test/layout/screenshots/` (not committed).
- New fixtures after an API change: run `test/layout/capture_fixtures.sh`
  against a local API with test data.
- `test/layout/safe_area_test.dart` and `test/layout/states_test.dart` check
  system bars, cutouts, curved edges, loading placeholders and the
  connection strips.
- `test/live_api_test.dart` runs the real network layer (sessions, safe
  retries) against a local API; see the file header. Never against
  production.

## Docs

- [Navigation and layout](docs/navigation-and-layout.md): menus per role,
  screen sizes, text size, the layout test.
- [Speed and offline](docs/performance-and-offline.md): what makes the app
  usable on a 100 kbps connection or with no signal.
- Backend and business rules: `../backend/docs/`.
