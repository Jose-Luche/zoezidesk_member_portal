# ZoeziDesk Members App

Flutter members app for ZoeziDesk (Android first). It supplements the web
members portal; the web portal stays the functional reference.

## Run

```sh
flutter pub get
dart run build_runner build      # only after changing freezed/json models
flutter run --dart-define-from-file=env/dev.json
```

## Environment values

Configuration comes from `--dart-define-from-file`. Nothing is hardcoded,
and the app refuses to start without `API_BASE_URL`.

| File | Purpose | In git |
|---|---|---|
| `env/example.json` | Template listing every key | yes |
| `env/dev.json` | Your local values | no |
| `env/prod.json` | Production values | no |

Keys:

- `API_BASE_URL`: base of the mobile API, e.g. `https://gym.zoezidesk.com/api`.
  From the Android emulator a local XAMPP backend is reachable at
  `http://10.0.2.2/projects/zoezi_erp/public/api`. Plain HTTP is allowed in
  debug builds only.

Against a local backend with `APP_ENV=local`, the OTP screen shows the login
code in debug builds, so no WhatsApp message is needed.

## Build a release

```sh
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json
```

Release signing still uses the debug key. Before the first Play Store upload,
create an upload keystore and reference it from `android/key.properties`
(gitignored).

## Authentication

- OTP over WhatsApp (`/member/otp/request`, `/member/otp/verify`).
- The Sanctum token and the signed-in member are kept only in
  `flutter_secure_storage`.
- There are no refresh tokens. Any `401` on an authenticated request ends
  the session, wipes local data and returns to login with a message.
- Logout revokes the token on the server when online and always wipes local
  data.

Backend changes the app depends on are tracked in `BACKEND_REQUIREMENTS.md`.

## Offline data

- Screens render from the local Drift database (`lib/data/db/`) and refresh
  from the API in the background, on app resume and on pull-to-refresh.
- Cached API snapshots are AES-256-GCM encrypted (`FieldCipher`). The key
  lives in secure storage, so logout, which wipes the database and secure
  storage, leaves nothing readable.
- Cached screens show "Updated …". A warning appears when the data is older
  than 24 hours, or when a refresh failed or the phone is offline.
- Writes made offline (class bookings and cancellations) go to an `Outbox`
  table with an idempotency key, are shown as pending, and are sent oldest
  first on app start, on resume and when connectivity returns
  (`lib/core/sync/outbox_service.dart`). Network errors, timeouts, 409, 429
  and 5xx retry with exponential backoff up to 5 minutes; other 4xx mark the
  change failed with the server's reason. Connectivity is only a hint; a
  failed request is the real signal.
- Live class spot counts are shown only while online.
- Android auto-backup is off so the database never leaves the device
  without its key.

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
- Debug builds have a design gallery at `/dev/design`, linked from the home
  screen.

## Test

```sh
flutter analyze
flutter test
```
