import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/data/repositories/payments_repository.dart';

import '../../helpers/test_app.dart';

DioException offline() =>
    DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  final oct1 = DateTime(2026, 10, 1, 9);
  final sep1 = DateTime(2026, 9, 1, 9);

  group('PaymentsRepository', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer(overrides: env.overrides));
    tearDown(() => c.dispose());
    PaymentsRepository repo() => c.read(paymentsRepositoryProvider);

    test('refresh caches the first page and the totals, in server order', () async {
      when(() => env.paymentsApi.page(1)).thenAnswer(
        (_) async => paymentsJson(
          [
            paymentJson(3, status: 'pending'),
            paymentJson(2, paidAt: oct1, receipt: 'SJK4H7Q2LM'),
            paymentJson(1, amount: 2500, paidAt: sep1, method: 'cash'),
          ],
          lastPage: 2,
          totalPaid: 5500,
          total: 12,
        ),
      );

      final page = await repo().refresh();

      expect(page.hasMore, isTrue);
      final rows = await repo().watchAll().first;
      // Unpaid (no paid_at) sorts last, as on the server.
      expect(rows.map((r) => r.id), [2, 1, 3]);
      expect(rows.first.receipt, 'SJK4H7Q2LM');
      expect(rows.first.amount, 3000);
      expect(rows.first.hasReceiptPdf, isTrue);
      expect(rows[1].method, 'cash');
      expect(rows.last.paidAt, isNull);
      final summary = await repo().watchSummary().first;
      expect(summary!.totalPaid, 5500);
      expect(summary.total, 12);
      expect(await repo().watchFetchedAt().first, testNow);
    });

    test('amounts and receipts are encrypted at rest', () async {
      when(() => env.paymentsApi.page(1)).thenAnswer(
        (_) async => paymentsJson([paymentJson(1, amount: 4321, paidAt: oct1, receipt: 'SJK4H7Q2LM')]),
      );
      await repo().refresh();

      final raw = (await env.db.select(env.db.payments).getSingle()).payload;
      final asText = latin1.decode(raw);
      expect(asText, isNot(contains('SJK4H7Q2LM')));
      expect(asText, isNot(contains('4321')));
    });

    test('older pages append; a refresh replaces everything (server wins)', () async {
      when(() => env.paymentsApi.page(1))
          .thenAnswer((_) async => paymentsJson([paymentJson(3, paidAt: oct1)], lastPage: 2));
      when(() => env.paymentsApi.page(2)).thenAnswer(
        (_) async => paymentsJson([paymentJson(1, paidAt: sep1)], page: 2, lastPage: 2),
      );
      await repo().refresh();
      final page2 = await repo().loadPage(2);
      expect(page2.hasMore, isFalse);
      expect((await repo().watchAll().first).map((r) => r.id), [3, 1]);

      // The front desk voided payment 3.
      when(() => env.paymentsApi.page(1)).thenAnswer((_) async => paymentsJson([paymentJson(1, paidAt: sep1)]));
      await repo().refresh();
      expect((await repo().watchAll().first).map((r) => r.id), [1]);
    });

    test('offline keeps the cached history', () async {
      when(() => env.paymentsApi.page(1)).thenAnswer((_) async => paymentsJson([paymentJson(1, paidAt: sep1)]));
      await repo().refresh();
      when(() => env.paymentsApi.page(1)).thenThrow(offline());

      await expectLater(repo().refresh(), throwsA(isA<NetworkFailure>()));
      expect(await repo().watchAll().first, hasLength(1));
    });

    test('rows written with a lost key are dropped, not shown', () async {
      when(() => env.paymentsApi.page(1)).thenAnswer((_) async => paymentsJson([paymentJson(1, paidAt: sep1)]));
      await repo().refresh();
      env.store.values.remove('db_field_key');

      final fresh = ProviderContainer(overrides: env.overrides);
      addTearDown(fresh.dispose);
      expect(await fresh.read(paymentsRepositoryProvider).watchAll().first, isEmpty);
      expect(await env.db.select(env.db.payments).get(), isEmpty);
    });

    test('receipt link comes from the server', () async {
      when(() => env.paymentsApi.receiptLink(2)).thenAnswer(
        (_) async => {'url': 'https://api.test/member/receipts/2?signature=abc', 'expires_at': '…'},
      );
      expect(
        await repo().receiptLink(2),
        Uri.parse('https://api.test/member/receipts/2?signature=abc'),
      );
    });
  });

  group('payments screen', () {
    setUp(() async {
      await env.signIn();
      env.dashboardReturns(dashboardJson());
    });

    Future<void> openPayments(WidgetTester tester) async {
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
      await tester.pumpAndSettle();
      c.read(routerProvider).push(Routes.payments);
      await tester.pumpAndSettle();
    }

    final scrollable = find.byType(Scrollable);

    testWidgets('lists payments with the total and their status', (tester) async {
      when(() => env.paymentsApi.page(1)).thenAnswer(
        (_) async => paymentsJson(
          [
            paymentJson(4, status: 'failed', paidAt: DateTime(2026, 10, 20, 9)),
            paymentJson(3, paidAt: oct1, receipt: 'SJK4H7Q2LM'),
            paymentJson(2, status: 'pending', plan: null),
          ],
          totalPaid: 3000,
        ),
      );
      await openPayments(tester);

      expect(find.text('Total paid'), findsOneWidget);
      expect(find.text('KES 3,000'), findsWidgets);
      expect(find.text('3 payments'), findsOneWidget);
      expect(find.text('1 Oct 2026 · 9:00 AM'), findsOneWidget);
      expect(find.text('SJK4H7Q2LM'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Pending'), 200, scrollable: scrollable.first);
      expect(find.text('Membership'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Receipt'), findsOneWidget);
    });

    testWidgets('Receipt opens a fresh signed link in the browser', (tester) async {
      when(() => env.paymentsApi.page(1))
          .thenAnswer((_) async => paymentsJson([paymentJson(3, paidAt: oct1, receipt: 'SJK4H7Q2LM')]));
      when(() => env.paymentsApi.receiptLink(3)).thenAnswer(
        (_) async => {'url': 'https://api.test/member/receipts/3?signature=abc'},
      );
      await openPayments(tester);

      await tester.tap(find.text('Receipt'));
      await tester.pumpAndSettle();

      expect(env.openedUrls, [Uri.parse('https://api.test/member/receipts/3?signature=abc')]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Receipt offline explains that it needs a connection', (tester) async {
      when(() => env.paymentsApi.page(1))
          .thenAnswer((_) async => paymentsJson([paymentJson(3, paidAt: oct1)]));
      when(() => env.paymentsApi.receiptLink(3)).thenThrow(offline());
      await openPayments(tester);

      await tester.tap(find.text('Receipt'));
      await tester.pump();

      expect(find.textContaining('Receipts need an internet connection'), findsOneWidget);
      expect(env.openedUrls, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('no app to open the PDF', (tester) async {
      env.openUrlResult = false;
      when(() => env.paymentsApi.page(1))
          .thenAnswer((_) async => paymentsJson([paymentJson(3, paidAt: oct1)]));
      when(() => env.paymentsApi.receiptLink(3))
          .thenAnswer((_) async => {'url': 'https://api.test/member/receipts/3'});
      await openPayments(tester);

      await tester.tap(find.text('Receipt'));
      await tester.pump();

      expect(find.text('No app on this phone can open the receipt.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('cached history shows offline with when it was updated', (tester) async {
      when(() => env.paymentsApi.page(1))
          .thenAnswer((_) async => paymentsJson([paymentJson(3, paidAt: oct1)], totalPaid: 3000));
      final c = ProviderContainer(overrides: env.overrides);
      await c.read(paymentsRepositoryProvider).refresh();
      c.dispose();

      env.now = testNow.add(const Duration(days: 2));
      when(() => env.paymentsApi.page(1)).thenThrow(offline());
      await openPayments(tester);

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.textContaining('You are offline. Showing saved data from'), findsOneWidget);
    });

    testWidgets('first open offline', (tester) async {
      when(() => env.paymentsApi.page(1)).thenThrow(offline());
      await openPayments(tester);
      expect(find.text('You are offline'), findsOneWidget);
    });

    testWidgets('no payments yet', (tester) async {
      when(() => env.paymentsApi.page(1)).thenAnswer((_) async => paymentsJson([]));
      await openPayments(tester);
      expect(find.text('No payments yet'), findsOneWidget);
    });

    testWidgets('load older payments', (tester) async {
      when(() => env.paymentsApi.page(1)).thenAnswer(
        (_) async => paymentsJson([paymentJson(3, paidAt: oct1)], lastPage: 2, total: 2),
      );
      when(() => env.paymentsApi.page(2)).thenAnswer(
        (_) async => paymentsJson([paymentJson(1, amount: 2500, paidAt: sep1)], page: 2, lastPage: 2, total: 2),
      );
      await openPayments(tester);

      final more = find.text('Load older payments');
      await tester.scrollUntilVisible(more, 200, scrollable: scrollable.first);
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('KES 2,500'), 200, scrollable: scrollable.first);
      expect(find.text('Load older payments'), findsNothing);
    });
  });
}
