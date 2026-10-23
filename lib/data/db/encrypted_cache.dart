import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/field_cipher.dart';
import 'app_database.dart';

/// Cached data plus when it was fetched, for "last updated" labels.
class Cached<T> {
  const Cached(this.data, this.fetchedAt);

  static const staleAfter = Duration(hours: 24);

  final T data;
  final DateTime fetchedAt;

  bool isStaleAt(DateTime now) => now.difference(fetchedAt) > staleAfter;

  Cached<R> map<R>(R Function(T) convert) => Cached(convert(data), fetchedAt);
}

/// Key-value snapshots of JSON responses, encrypted at rest.
class EncryptedCache {
  const EncryptedCache(this._db, this._cipher);

  final AppDatabase _db;
  final FieldCipher _cipher;

  Future<void> put(String key, Map<String, dynamic> json, DateTime fetchedAt) async {
    final payload = await _cipher.encrypt(jsonEncode(json));
    await _db.into(_db.cachedDocuments).insertOnConflictUpdate(
          CachedDocumentsCompanion.insert(
            key: key,
            payload: payload,
            fetchedAt: fetchedAt,
          ),
        );
  }

  Stream<Cached<Map<String, dynamic>>?> watch(String key) {
    final query = _db.select(_db.cachedDocuments)
      ..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().asyncMap(
          (row) => row == null ? null : _decode(row),
        );
  }

  Future<Cached<Map<String, dynamic>>?> _decode(CachedDocument row) async {
    try {
      final json = jsonDecode(await _cipher.decrypt(row.payload));
      return Cached(json as Map<String, dynamic>, row.fetchedAt);
    } catch (_) {
      // Written with a key that no longer exists, or corrupt: drop it so
      // the next refresh replaces it.
      await (_db.delete(_db.cachedDocuments)..where((t) => t.key.equals(row.key))).go();
      return null;
    }
  }
}

final encryptedCacheProvider = Provider<EncryptedCache>(
  (ref) => EncryptedCache(ref.watch(appDatabaseProvider), ref.watch(fieldCipherProvider)),
);
