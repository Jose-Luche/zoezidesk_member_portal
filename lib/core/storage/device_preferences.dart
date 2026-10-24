import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';

/// Settings that belong to the phone, not the member (the theme). They are
/// kept in secure storage, like everything else the app stores, and
/// survive logout (see LocalDataWiper).
class DevicePreferences {
  const DevicePreferences(this._store);

  static const themeModeKey = 'pref_theme_mode';

  /// Keys LocalDataWiper keeps when it wipes secure storage.
  static const keys = [themeModeKey];

  final SecureStore _store;

  Future<ThemeMode?> readThemeMode() async {
    final saved = await _store.read(themeModeKey);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull;
  }

  Future<void> writeThemeMode(ThemeMode mode) => _store.write(themeModeKey, mode.name);
}

final devicePreferencesProvider =
    Provider<DevicePreferences>((ref) => DevicePreferences(ref.watch(secureStoreProvider)));
