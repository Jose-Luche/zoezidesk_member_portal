import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import 'device_preferences.dart';
import 'field_cipher.dart';
import 'session_storage.dart';

/// Removes everything the app stores about the member. Runs on logout and
/// when the server rejects the token.
class LocalDataWiper {
  const LocalDataWiper({
    required this.sessionStorage,
    this.store,
    this.database,
    this.cipher,
    this.clearImageCache,
  });

  final SessionStorage sessionStorage;

  /// Where device preferences live; they are kept (they are not the
  /// member's data).
  final SecureStore? store;
  final AppDatabase? database;
  final FieldCipher? cipher;

  /// Cached member photos.
  final Future<void> Function()? clearImageCache;

  Future<void> wipeAll() async {
    // Database first. If the app dies before secure storage is cleared, the
    // member is still signed in with an empty cache, which the next refresh
    // fills. The reverse order could leave encrypted rows without a key.
    await database?.wipe();
    final keep = <String, String>{
      for (final key in DevicePreferences.keys) key: ?await store?.read(key),
    };
    await sessionStorage.clear();
    for (final MapEntry(:key, :value) in keep.entries) {
      await store?.write(key, value);
    }
    cipher?.reset();
    try {
      await clearImageCache?.call();
    } catch (_) {
      // Best-effort: the image cache holds photos, never tokens.
    }
  }
}

/// Clears cached network images. Overridden in tests, where the cache
/// manager's platform plugins are unavailable.
final imageCacheClearerProvider =
    Provider<Future<void> Function()>((_) => () => DefaultCacheManager().emptyCache());

final localDataWiperProvider = Provider<LocalDataWiper>(
  (ref) => LocalDataWiper(
    sessionStorage: ref.watch(sessionStorageProvider),
    store: ref.watch(secureStoreProvider),
    database: ref.watch(appDatabaseProvider),
    cipher: ref.watch(fieldCipherProvider),
    clearImageCache: ref.watch(imageCacheClearerProvider),
  ),
);
