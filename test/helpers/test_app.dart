import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/core/utils/clock.dart';
import 'package:zoezidesk_member/data/api/auth_api.dart';
import 'package:zoezidesk_member/data/api/dashboard_api.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';

import 'fakes.dart';

class MockDashboardApi extends Mock implements DashboardApi {}

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
  );
}

/// Fixed "now" for tests: 23 Oct 2026, 10:00.
final testNow = DateTime(2026, 10, 23, 10);

/// Everything the app touches outside Dart, replaced with fakes.
class TestEnv {
  TestEnv() {
    when(() => authApi.logout()).thenAnswer((_) async {});
  }

  final store = InMemorySecureStore();
  final db = memoryDatabase();
  final authApi = MockAuthApi();
  final dashboardApi = MockDashboardApi();
  DateTime now = testNow;

  List<Override> get overrides => [
        secureStoreProvider.overrideWithValue(store),
        appDatabaseProvider.overrideWithValue(db),
        authApiProvider.overrideWithValue(authApi),
        dashboardApiProvider.overrideWithValue(dashboardApi),
        clockProvider.overrideWithValue(() => now),
      ];

  Future<void> signIn() =>
      SessionStorage(store).save(token: 'tok', member: testMember);

  void dashboardReturns(Map<String, dynamic> dashboard, [Map<String, dynamic>? card]) {
    when(() => dashboardApi.dashboard()).thenAnswer((_) async => dashboard);
    when(() => dashboardApi.memberCard()).thenAnswer((_) async => card ?? testCardJson);
  }

  Future<void> dispose() => db.close();
}

Map<String, dynamic> dashboardJson({
  Map<String, dynamic>? membership = const {
    'plan_name': 'Monthly',
    'starts_at': '13 Oct 2026',
    'expires_at': '12 Nov 2026',
    'starts_at_iso': '2026-10-13',
    'expires_at_iso': '2026-11-12',
    'days_left': 20.4,
    'days_remaining': 20,
    'expiry_percent': 33,
    'state': 'active',
    'is_active': true,
  },
  List<Map<String, dynamic>> payments = const [
    {
      'id': 1,
      'amount': 3000,
      'method': 'mpesa',
      'receipt': 'QWE123',
      'date': '13 Oct 2026',
      'date_iso': '2026-10-13T09:00:00+03:00',
      'plan': 'Monthly',
    },
  ],
  int? totalPaid = 4500,
}) =>
    {
      'member': {
        'id': 7,
        'name': 'Jane Wanjiru',
        'member_number': 'ZD-0007',
        'gym_name': 'Test Gym',
        'status': 'active',
      },
      'membership': membership,
      'recent_payments': payments,
      'attendance_month': 6,
      'total_paid': ?totalPaid,
      'generated_at': '2026-10-23T10:00:00+03:00',
    };

const testCardJson = {
  'qr_code': 'ZD-QR-7f3a9c',
  'member_number': 'ZD-0007',
  'name': 'Jane Wanjiru',
  'gym_name': 'Test Gym',
};
