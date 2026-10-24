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
flutter build apk --release --dart-define-from-file=env/prod.json        # one APK for every phone
flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json
flutter build appbundle --release --dart-define-from-file=env/prod.json  # for Google Play
```

Raise `version:` in `pubspec.yaml` (both parts, e.g. `1.0.1+2`) for every
build you hand out. Android only installs an update with a higher version
code.

### Sharing APKs without Google Play

Until the app is on Google Play, members install the APK directly (allowing
"install unknown apps" once) and get updates only when you send them a new
APK.

- Share the universal `app-release.apk` (about 65 MB). It installs on every
  phone, including older 32-bit ones.
- Don't mix it with the per-CPU APKs from `--split-per-abi`. Those get
  version codes 1001 (32-bit) and 2001 (64-bit) for the same release, so a
  phone that has one of them refuses a later universal APK until its version
  code passes that number.
- Publish the SHA-256 checksum with each APK so members can tell it is yours.

### Signing

Release builds are signed with the key in `android/key.properties`
(gitignored, as are `*.jks` files). Without that file they fall back to the
debug key and Gradle warns; Google Play rejects those builds.

Create the key once and keep the file and passwords somewhere safe (a
password manager plus an offline backup). Every update must be signed with
the same key: while APKs are shared directly, losing it means members have
to uninstall the app (and lose unsent changes) to install a new one. Once on
Google Play, losing it means asking Google to reset the upload key.

```sh
keytool -genkeypair -v -keystore ~/zoezidesk-upload.jks -storetype PKCS12   -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties`:

```properties
storeFile=C:/Users/you/zoezidesk-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

When the app moves to Google Play, use Play App Signing and choose to use
this existing key as the app signing key, so phones that installed a shared
APK can update from Play. Otherwise they would have to uninstall first.

### Size (1.0.0, arm64)

About 22.6 MB as an APK; about 11 MB to download, since Play compresses it
and serves only the phone's CPU type. Most of it is the Flutter engine
(about 12 MB) and the app's compiled code (about 9 MB).

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
- Payment history is cached with amounts and receipts encrypted. Receipt
  PDFs open in the browser through a 10-minute signed link, so they need a
  connection; the app never puts its token in a URL.
- Workouts are logged offline: sessions and sets are saved locally, then
  sent as one whole-session document (`workout_sync`). The outbox keeps
  only the newest copy per session (`OutboxService.coalesce`), and the
  server applies it by the app's ids, so resending is harmless. The
  exercise library is cached for the offline picker.
- The food diary works the same way: entries are saved locally and each is
  sent as a PUT by its app id (`diary_put`, coalesced); the food catalogue
  and the last 7 days are cached. The nutrition goal is changed online only.
- Paying for a plan (M-Pesa STK push) is online only and never queued: a
  payment must not be sent late or twice. Each attempt carries an
  idempotency key, so a retry after a dropped connection gets the first
  push back instead of sending another.
- Android auto-backup is off so the database never leaves the device
  without its key.

## Settings

- Appearance: dark (default), light, or match the phone. Saved in secure
  storage as a device preference (`DevicePreferences`), read before the
  first frame, and kept on logout; everything about the member is wiped.
- Shows how many changes are waiting to send, with "Send now".
- Logging out warns when changes have not reached the server, since logout
  deletes them.
- Notifications: not available yet (needs a Firebase project and a backend
  sender); the screen says so instead of showing a toggle that does nothing.

## Logo and app icon

- The wordmarks are in `assets/logo/`; the app bundles the dark and light
  ones and shows the right one for the theme (`BrandMark`, via
  `flutter_svg`).
- Launcher icons, the launch-screen mark and the 512 px store icon
  (`store/icon-512.png`) are drawn from the logo mark by
  `python tool/make_icons.py` (no image library needed). Android uses an
  adaptive icon on brand navy `#0D1E2E` with a monochrome layer for themed
  icons. Run the script again if the mark changes.

## Design system

- All colors, spacing, radius, motion and font names live in
  `lib/core/theme/app_tokens.dart`. Widgets read them through the theme
  (`Theme.of(context)`, `context.palette`), never as literals.
- Light and dark `ThemeData` are built in `lib/core/theme/app_theme.dart`.
  Dark is the default.
- Barlow and Barlow Condensed are bundled in `assets/fonts/` (OFL) and
  declared in `pubspec.yaml`, so text renders correctly offline. (The
  `google_fonts` package was dropped: its catalogue added about 8 MB.)
- `test/core/theme/contrast_test.dart` checks every text/background pair for
  4.5:1 contrast. Add a pair there whenever a new combination is used.
- Debug builds have a design gallery at `/dev/design`, linked from the home
  screen.

## Test

```sh
flutter analyze
flutter test
```
