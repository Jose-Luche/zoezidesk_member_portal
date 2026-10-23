# ZoeziDesk Members App

Flutter members app for ZoeziDesk (Android first). It supplements the web
members portal; the web portal stays the functional reference.

## Run

```sh
flutter pub get
flutter run
```

Environment values (API base URL) arrive with the login feature via
`--dart-define-from-file=env/dev.json`; see `env/example.json` once added.

## Design system

- All colors, spacing, radius, motion and font names live in
  `lib/core/theme/app_tokens.dart`. Widgets read them through the theme
  (`Theme.of(context)`, `context.palette`), never as literals.
- Light and dark `ThemeData` are built in `lib/core/theme/app_theme.dart`.
  Dark is the default.
- Barlow and Barlow Condensed are bundled in `assets/google_fonts/` (OFL) and
  runtime font fetching is disabled, so text renders correctly offline.
- `test/core/theme/contrast_test.dart` checks every text/background pair for
  4.5:1 contrast. Add a pair there whenever a new combination is used.

## Test

```sh
flutter analyze
flutter test
```
