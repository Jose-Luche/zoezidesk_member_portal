import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/storage/field_cipher.dart';
import 'package:zoezidesk_member/core/storage/local_data_wiper.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';
import 'package:zoezidesk_member/data/db/encrypted_cache.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  late InMemorySecureStore store;
  late AppDatabase db;
  late FieldCipher cipher;
  late EncryptedCache cache;

  setUp(() {
    store = InMemorySecureStore();
    db = memoryDatabase();
    cipher = FieldCipher(store);
    cache = EncryptedCache(db, cipher);
  });

  tearDown(() => db.close());

  group('FieldCipher', () {
    test('round-trips and never repeats ciphertext', () async {
      final a = await cipher.encrypt('ZD-QR-7f3a9c');
      final b = await cipher.encrypt('ZD-QR-7f3a9c');
      expect(a, isNot(equals(b))); // random nonce
      expect(await cipher.decrypt(a), 'ZD-QR-7f3a9c');
    });

    test('keeps the key in secure storage', () async {
      await cipher.encrypt('x');
      expect(store.values.containsKey('db_field_key'), isTrue);
    });

    test('data from another key does not decrypt', () async {
      final data = await cipher.encrypt('secret');
      final other = FieldCipher(InMemorySecureStore());
      await expectLater(other.decrypt(data), throwsA(anything));
    });
  });

  group('EncryptedCache', () {
    test('stores and streams the document with its fetch time', () async {
      await cache.put('dashboard', {'a': 1}, testNow);
      final cached = await cache.watch('dashboard').first;
      expect(cached!.data, {'a': 1});
      expect(cached.fetchedAt, testNow);
    });

    test('rows are encrypted at rest', () async {
      await cache.put('member_card', {'qr_code': 'ZD-QR-7f3a9c'}, testNow);
      final row = await db.select(db.cachedDocuments).getSingle();
      expect(latin1.decode(row.payload, allowInvalid: true), isNot(contains('ZD-QR')));
    });

    test('unreadable rows are dropped instead of crashing', () async {
      await cache.put('dashboard', {'a': 1}, testNow);
      // Simulate a lost key (e.g. restored database without secure storage).
      await store.deleteAll();
      cipher.reset();

      expect(await cache.watch('dashboard').first, isNull);
      expect(await db.select(db.cachedDocuments).get(), isEmpty);
    });

    test('staleness is 24 hours', () {
      final c = Cached(1, testNow);
      expect(c.isStaleAt(testNow.add(const Duration(hours: 23))), isFalse);
      expect(c.isStaleAt(testNow.add(const Duration(hours: 25))), isTrue);
    });
  });

  test('LocalDataWiper clears the database, key and session', () async {
    final storage = SessionStorage(store);
    await storage.save(token: 't', member: testMember);
    await cache.put('dashboard', {'a': 1}, testNow);

    await LocalDataWiper(sessionStorage: storage, database: db, cipher: cipher).wipeAll();

    expect(await db.select(db.cachedDocuments).get(), isEmpty);
    expect(store.values, isEmpty);
  });
}
