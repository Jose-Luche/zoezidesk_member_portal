import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/storage/field_cipher.dart';
import 'package:zoezidesk_member/data/db/encrypted_cache.dart';
import 'package:zoezidesk_member/data/repositories/dashboard_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
  });

  tearDown(() => env.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: env.overrides, child: const ZoeziApp()),
    );
    await tester.pumpAndSettle();
  }

  DioException offline() => DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );

  void failWith(DioException e) {
    when(() => env.dashboardApi.dashboard()).thenThrow(e);
    when(() => env.dashboardApi.memberCard()).thenThrow(e);
  }

  /// Put data in the cache as if fetched at [at].
  Future<void> seedCache(DateTime at, [Map<String, dynamic>? dashboard]) async {
    final cache = EncryptedCache(env.db, FieldCipher(env.store));
    await cache.put(DashboardRepository.dashboardKey, dashboard ?? dashboardJson(), at);
    await cache.put(DashboardRepository.memberCardKey, testCardJson, at);
  }

  testWidgets('first load: fetches and shows the membership card', (tester) async {
    env.dashboardReturns(dashboardJson());
    await pumpApp(tester);

    expect(find.text('Hi, Jane'), findsOneWidget);
    expect(find.text('Jane Wanjiru'), findsOneWidget);
    expect(find.text('ZD-0007'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Valid until 12 Nov 2026'), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // visits this month
    expect(find.text('20'), findsOneWidget); // days left
    expect(find.text('KES 4,500'), findsOneWidget);

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
  });

  testWidgets('offline with nothing cached shows the offline state', (tester) async {
    failWith(offline());
    await pumpApp(tester);

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    env.dashboardReturns(dashboardJson());
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Jane Wanjiru'), findsOneWidget);
  });

  testWidgets('offline with a cache shows saved data and when', (tester) async {
    await seedCache(testNow.subtract(const Duration(hours: 3)));
    failWith(offline());
    await pumpApp(tester);

    expect(find.text('Jane Wanjiru'), findsOneWidget);
    expect(find.text('You are offline. Showing saved data from 3 h ago.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('cache older than 24 hours is flagged even when refresh succeeds later',
      (tester) async {
    await seedCache(testNow.subtract(const Duration(hours: 30)));
    failWith(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(), statusCode: 500),
    ));
    await pumpApp(tester);

    expect(find.text('Could not refresh. Showing saved data from yesterday.'), findsOneWidget);
  });

  testWidgets('expired membership shows the renew notice', (tester) async {
    env.dashboardReturns(dashboardJson(membership: {
      'plan_name': 'Monthly',
      'expires_at_iso': '2026-10-20',
      'days_remaining': 0,
      'expiry_percent': 100,
      'state': 'expired',
    }));
    await pumpApp(tester);

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Expired 20 Oct 2026'), findsOneWidget);
    expect(
      find.text('Your membership has expired. Renew in the app or at the front desk.'),
      findsOneWidget,
    );
  });

  testWidgets('expiring soon shows a warning', (tester) async {
    env.dashboardReturns(dashboardJson(membership: {
      'plan_name': 'Monthly',
      'expires_at_iso': '2026-10-26',
      'days_remaining': 3,
      'state': 'expiring',
    }));
    await pumpApp(tester);

    expect(find.text('Expires in 3 days'), findsOneWidget);
    expect(
      find.text('Expires in 3 days. Renew in the app or at the front desk.'),
      findsOneWidget,
    );
  });

  testWidgets('no membership and no payments', (tester) async {
    env.dashboardReturns(dashboardJson(membership: null, payments: const [], totalPaid: 0));
    await pumpApp(tester);

    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Visit the front desk to get started'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No payments yet.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No payments yet.'), findsOneWidget);
  });

  testWidgets('pull to refresh fetches again', (tester) async {
    env.dashboardReturns(dashboardJson());
    await pumpApp(tester);
    clearInteractions(env.dashboardApi);

    await tester.fling(find.text('Jane Wanjiru'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(() => env.dashboardApi.dashboard()).called(1);
  });

  testWidgets('quick actions open their destinations', (tester) async {
    env.dashboardReturns(dashboardJson());
    await pumpApp(tester);

    when(() => env.paymentsApi.page(any())).thenAnswer((_) async => paymentsJson([]));
    final payments = find.descendant(of: find.byType(Card), matching: find.text('Payments'));
    await tester.scrollUntilVisible(payments, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(payments);
    await tester.pumpAndSettle();
    await tester.tap(payments);
    await tester.pumpAndSettle();
    expect(find.text('No payments yet'), findsOneWidget);
  });

  testWidgets('logout from More wipes the cached dashboard', (tester) async {
    env.dashboardReturns(dashboardJson());
    await pumpApp(tester);
    expect(await env.db.select(env.db.cachedDocuments).get(), isNotEmpty);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Member login'), findsOneWidget);
    expect(await env.db.select(env.db.cachedDocuments).get(), isEmpty);
    expect(env.store.values, isEmpty);
  });
}
