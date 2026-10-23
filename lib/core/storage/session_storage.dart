import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/dto/member_summary.dart';

/// Minimal key-value contract so tests can use an in-memory store.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> deleteAll();
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// The access token and signed-in member live only in secure storage,
/// never in shared preferences or plain files.
class SessionStorage {
  const SessionStorage(this._store);

  static const _tokenKey = 'auth_token';
  static const _memberKey = 'auth_member';

  final SecureStore _store;

  Future<String?> readToken() => _store.read(_tokenKey);

  Future<MemberSummary?> readMember() async {
    final raw = await _store.read(_memberKey);
    if (raw == null) return null;
    return MemberSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save({required String token, required MemberSummary member}) async {
    await _store.write(_tokenKey, token);
    await _store.write(_memberKey, jsonEncode(member.toJson()));
  }

  Future<void> clear() => _store.deleteAll();
}

final secureStoreProvider = Provider<SecureStore>((_) => const FlutterSecureStore());

final sessionStorageProvider =
    Provider<SessionStorage>((ref) => SessionStorage(ref.watch(secureStoreProvider)));
