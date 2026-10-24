import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/features/auth/state/session_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late MockAuthApi api;
  late InMemorySecureStore store;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);
    return c;
  }

  Future<SessionState> settled(ProviderContainer c) async {
    c.read(sessionControllerProvider);
    await pumpEventQueue();
    return c.read(sessionControllerProvider);
  }

  setUp(() {
    env = TestEnv();
    api = env.authApi;
    store = env.store;
  });

  tearDown(() => env.dispose());

  test('starts loading, then signed out with no stored session', () async {
    final c = makeContainer();
    expect(c.read(sessionControllerProvider), isA<SessionLoading>());
    expect(await settled(c), isA<SignedOut>());
  });

  test('restores a stored session', () async {
    await SessionStorage(store).save(token: 't1', member: testMember);
    final state = await settled(makeContainer());
    expect(state, isA<SignedIn>());
    expect((state as SignedIn).member, testMember);
  });

  test('logout clears storage and signs out', () async {
    await SessionStorage(store).save(token: 't1', member: testMember);
    final c = makeContainer();
    await settled(c);

    await c.read(sessionControllerProvider.notifier).logout();

    expect(c.read(sessionControllerProvider), isA<SignedOut>());
    expect(store.values, isEmpty);
  });

  test('expire wipes data and explains why, once', () async {
    await SessionStorage(store).save(token: 't1', member: testMember);
    final c = makeContainer();
    await settled(c);
    final notifier = c.read(sessionControllerProvider.notifier);

    await Future.wait([notifier.expire(), notifier.expire()]);

    final state = c.read(sessionControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).reason, contains('session has ended'));
    expect(store.values, isEmpty);
    verifyNever(() => api.logout(refreshToken: any(named: 'refreshToken')));
  });

  test('expire does nothing when already signed out', () async {
    final c = makeContainer();
    await settled(c);
    await c.read(sessionControllerProvider.notifier).expire();
    expect((c.read(sessionControllerProvider) as SignedOut).reason, isNull);
  });
}
