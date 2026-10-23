import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';

/// AES-256-GCM for sensitive data stored in the local database. The key is
/// generated on first use and kept in secure storage, so wiping secure
/// storage on logout makes any leftover rows unreadable.
class FieldCipher {
  FieldCipher(this._store);

  static const _keyName = 'db_field_key';

  final SecureStore _store;
  final _algorithm = AesGcm.with256bits();
  Future<SecretKey>? _key;

  Future<SecretKey> _loadKey() async {
    final stored = await _store.read(_keyName);
    if (stored != null) return SecretKey(base64Decode(stored));
    final key = await _algorithm.newSecretKey();
    await _store.write(_keyName, base64Encode(await key.extractBytes()));
    return key;
  }

  Future<Uint8List> encrypt(String plain) async {
    final box = await _algorithm.encrypt(
      utf8.encode(plain),
      secretKey: await (_key ??= _loadKey()),
    );
    return box.concatenation();
  }

  /// Throws [SecretBoxAuthenticationError] if the data was written with a
  /// different key or tampered with.
  Future<String> decrypt(Uint8List data) async {
    final box = SecretBox.fromConcatenation(
      data,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final clear = await _algorithm.decrypt(
      box,
      secretKey: await (_key ??= _loadKey()),
    );
    return utf8.decode(clear);
  }

  /// Forget the cached key after secure storage has been wiped.
  void reset() => _key = null;
}

final fieldCipherProvider =
    Provider<FieldCipher>((ref) => FieldCipher(ref.watch(secureStoreProvider)));
