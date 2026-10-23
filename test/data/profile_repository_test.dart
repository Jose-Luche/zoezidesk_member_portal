import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/storage/field_cipher.dart';
import 'package:zoezidesk_member/data/db/encrypted_cache.dart';
import 'package:zoezidesk_member/data/repositories/profile_repository.dart';

import '../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late ProfileRepository repo;

  setUp(() {
    env = TestEnv();
    repo = ProfileRepository(
      api: env.profileApi,
      cache: EncryptedCache(env.db, FieldCipher(env.store)),
      clock: () => env.now,
    );
  });

  tearDown(() => env.dispose());

  test('refresh caches the profile', () async {
    when(() => env.profileApi.profile()).thenAnswer((_) async => profileJson());

    await repo.refresh();

    final cached = await repo.watchProfile().first;
    expect(cached!.fetchedAt, testNow);
    expect(cached.data.member.emergencyContactPhone, '254722000000');
    expect(cached.data.gym!.town, 'Nairobi');
    expect(cached.data.memberships.map((m) => m.lapsed), [false, true]);
  });

  test('server wins: a refresh replaces the cached profile', () async {
    when(() => env.profileApi.profile()).thenAnswer((_) async => profileJson());
    await repo.refresh();

    final changed = profileJson()..['member']['email'] = 'new@test.com';
    when(() => env.profileApi.profile()).thenAnswer((_) async => changed);
    await repo.refresh();

    expect((await repo.watchProfile().first)!.data.member.email, 'new@test.com');
  });

  test('a server without the endpoint (404) keeps the cache and reports it', () async {
    when(() => env.profileApi.profile()).thenAnswer((_) async => profileJson());
    await repo.refresh();

    when(() => env.profileApi.profile()).thenThrow(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(), statusCode: 404),
    ));

    await expectLater(repo.refresh(), throwsA(isA<ServerFailure>()));
    expect(await repo.watchProfile().first, isNotNull);
  });
}
