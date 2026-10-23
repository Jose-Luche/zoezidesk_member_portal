import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/storage/field_cipher.dart';
import 'package:zoezidesk_member/data/db/encrypted_cache.dart';
import 'package:zoezidesk_member/data/repositories/dashboard_repository.dart';

import '../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late DashboardRepository repo;

  setUp(() {
    env = TestEnv();
    repo = DashboardRepository(
      api: env.dashboardApi,
      cache: EncryptedCache(env.db, FieldCipher(env.store)),
      clock: () => env.now,
    );
  });

  tearDown(() => env.dispose());

  test('nothing cached before the first refresh', () async {
    expect(await repo.watchDashboard().first, isNull);
    expect(await repo.watchMemberCard().first, isNull);
  });

  test('refresh caches dashboard and card with the fetch time', () async {
    env.dashboardReturns(dashboardJson());

    await repo.refresh();

    final dashboard = await repo.watchDashboard().first;
    expect(dashboard!.data.member.name, 'Jane Wanjiru');
    expect(dashboard.data.totalPaid, 4500);
    expect(dashboard.data.recentPayments.single.receipt, 'QWE123');
    expect(dashboard.fetchedAt, testNow);
    expect((await repo.watchMemberCard().first)!.data.qrCode, 'ZD-QR-7f3a9c');
  });

  test('a failed refresh keeps the previous cache', () async {
    env.dashboardReturns(dashboardJson());
    await repo.refresh();

    when(() => env.dashboardApi.dashboard()).thenThrow(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    ));
    env.now = testNow.add(const Duration(hours: 2));

    await expectLater(repo.refresh(), throwsA(isA<NetworkFailure>()));
    expect((await repo.watchDashboard().first)!.fetchedAt, testNow);
  });

  test('a malformed response never replaces good data', () async {
    env.dashboardReturns(dashboardJson());
    await repo.refresh();

    env.dashboardReturns({'unexpected': true});
    await expectLater(repo.refresh(), throwsA(isA<ServerFailure>()));
    expect((await repo.watchDashboard().first)!.data.member.name, 'Jane Wanjiru');
  });

  test('reads responses from a server without the new fields', () async {
    final old = dashboardJson(totalPaid: null)
      ..['membership'] = {
        'plan_name': 'Monthly',
        'starts_at': '13 Oct 2026',
        'expires_at': '12 Nov 2026',
        'days_left': 19.6,
        'is_active': true,
      };
    env.dashboardReturns(old);

    await repo.refresh();

    final data = (await repo.watchDashboard().first)!.data;
    expect(data.totalPaid, isNull);
    expect(data.membership!.daysLeft, 19.6);
  });
}
