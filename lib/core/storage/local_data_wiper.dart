import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';

/// Removes everything the app stores about the member. Runs on logout and
/// when the server rejects the token. The local database joins this list
/// when it is added.
class LocalDataWiper {
  const LocalDataWiper({required this.sessionStorage});

  final SessionStorage sessionStorage;

  Future<void> wipeAll() async {
    await sessionStorage.clear();
  }
}

final localDataWiperProvider = Provider<LocalDataWiper>(
  (ref) => LocalDataWiper(sessionStorage: ref.watch(sessionStorageProvider)),
);
