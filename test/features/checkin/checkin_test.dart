import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/data/repositories/attendance_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  final visit1 = DateTime(2026, 10, 22, 18, 5);
  final visit2 = DateTime(2026, 10, 20, 7, 0);

  group('AttendanceRepository', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer(overrides: env.overrides));
    tearDown(() => c.dispose());
    AttendanceRepository repo() => c.read(attendanceRepositoryProvider);

    test('refresh caches the first page and the summary', () async {
      when(() => env.attendanceApi.page(1)).thenAnswer(
        (_) async => attendanceJson([(2, visit1, 'manual'), (1, visit2, 'qr')], lastPage: 2, thisMonth: 9),
      );

      final page = await repo().refresh();

      expect(page.hasMore, isTrue);
      final rows = await repo().watchAll().first;
      expect(rows.map((r) => r.id), [2, 1]);
      expect(rows.first.method, 'manual');
      final summary = await repo().watchSummary().first;
      expect(summary!.thisMonth, 9);
      expect(await repo().watchFetchedAt().first, testNow);
    });

    test('older pages append; a refresh replaces everything (server wins)', () async {
      when(() => env.attendanceApi.page(1))
          .thenAnswer((_) async => attendanceJson([(3, visit1, 'qr')], lastPage: 2));
      when(() => env.attendanceApi.page(2))
          .thenAnswer((_) async => attendanceJson([(1, visit2, 'qr')], page: 2, lastPage: 2));
      await repo().refresh();
      final page2 = await repo().loadPage(2);
      expect(page2.hasMore, isFalse);
      expect((await repo().watchAll().first).map((r) => r.id), [3, 1]);

      // Staff removed check-in 3.
      when(() => env.attendanceApi.page(1)).thenAnswer((_) async => attendanceJson([(1, visit2, 'qr')]));
      await repo().refresh();
      expect((await repo().watchAll().first).map((r) => r.id), [1]);
    });

    test('offline keeps the cached history', () async {
      when(() => env.attendanceApi.page(1)).thenAnswer((_) async => attendanceJson([(1, visit2, 'qr')]));
      await repo().refresh();
      when(() => env.attendanceApi.page(1)).thenThrow(
        DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
      );

      await expectLater(repo().refresh(), throwsA(isA<NetworkFailure>()));
      expect(await repo().watchAll().first, hasLength(1));
    });
  });

  group('check-in screen', () {
    final haptics = <String>[];

    setUp(() async {
      await env.signIn();
      env.dashboardReturns(dashboardJson());
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
          return null;
        },
      );
    });

    Future<ProviderContainer> openCheckIn(WidgetTester tester) async {
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
      await tester.pumpAndSettle();
      c.read(routerProvider).push(Routes.checkIn);
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('shows the QR at full brightness and restores it on leave', (tester) async {
      when(() => env.attendanceApi.page(any())).thenAnswer((_) async => attendanceJson([]));
      await openCheckIn(tester);

      expect(find.byType(QrImageView), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Show this code at the front desk'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(env.brightness.calls, ['boost']);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(env.brightness.calls, ['boost', 'restore']);
    });

    testWidgets('lists visits with the month count', (tester) async {
      when(() => env.attendanceApi.page(1)).thenAnswer(
        (_) async => attendanceJson([(2, visit1, 'manual'), (1, visit2, 'qr')], thisMonth: 7),
      );
      await openCheckIn(tester);

      await tester.scrollUntilVisible(find.text('Tuesday 20 October'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('7 this month'), findsOneWidget);
      expect(find.text('Thursday 22 October'), findsOneWidget);
      expect(find.text('6:05 PM · Checked in by staff'), findsOneWidget);
      expect(find.text('7:00 AM · QR scan'), findsOneWidget);
    });

    testWidgets('confirms the front-desk scan while open, with a haptic', (tester) async {
      when(() => env.attendanceApi.page(1)).thenAnswer((_) async => attendanceJson([(1, visit2, 'qr')]));
      await openCheckIn(tester);
      expect(find.textContaining('Checked in at'), findsNothing);

      // The desk scans the code a little later.
      final scanned = testNow.add(const Duration(seconds: 20));
      env.now = scanned;
      when(() => env.attendanceApi.page(1))
          .thenAnswer((_) async => attendanceJson([(2, scanned, 'qr'), (1, visit2, 'qr')]));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Checked in at 10:00 AM. Have a great session!'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(haptics, contains('HapticFeedbackType.lightImpact'));

      // Polling stops after the confirmation.
      clearInteractions(env.attendanceApi);
      await tester.pump(const Duration(seconds: 3));
      verifyNever(() => env.attendanceApi.page(any()));
    });

    testWidgets('an older visit is not mistaken for this one', (tester) async {
      when(() => env.attendanceApi.page(1)).thenAnswer((_) async => attendanceJson([(1, visit1, 'qr')]));
      await openCheckIn(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.textContaining('Checked in at'), findsNothing);
      expect(haptics, isEmpty);
      await tester.pageBack(); // stop polling
      await tester.pumpAndSettle();
    });

    testWidgets('inactive membership warns that the desk cannot check you in', (tester) async {
      env.dashboardReturns(dashboardJson(membership: {
        'plan_name': 'Monthly',
        'expires_at_iso': '2026-10-20',
        'days_remaining': 0,
        'state': 'expired',
      }));
      when(() => env.attendanceApi.page(any())).thenAnswer((_) async => attendanceJson([]));
      await openCheckIn(tester);

      await tester.scrollUntilVisible(
        find.textContaining('the front desk cannot check you in'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('load older visits', (tester) async {
      when(() => env.attendanceApi.page(1))
          .thenAnswer((_) async => attendanceJson([(2, visit1, 'qr')], lastPage: 2));
      when(() => env.attendanceApi.page(2))
          .thenAnswer((_) async => attendanceJson([(1, DateTime(2026, 9, 1, 7), 'qr')], page: 2, lastPage: 2));
      await openCheckIn(tester);

      final more = find.text('Load older visits');
      await tester.scrollUntilVisible(more, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Tuesday 1 September'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Load older visits'), findsNothing);
    });

    testWidgets('no visits yet', (tester) async {
      when(() => env.attendanceApi.page(any())).thenAnswer((_) async => attendanceJson([]));
      await openCheckIn(tester);
      await tester.scrollUntilVisible(find.text('No visits yet'), 300, scrollable: find.byType(Scrollable).first);
    });

    testWidgets('dashboard quick action opens check-in', (tester) async {
      when(() => env.attendanceApi.page(any())).thenAnswer((_) async => attendanceJson([]));
      await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
      await tester.pumpAndSettle();

      final action = find.descendant(of: find.byType(Card), matching: find.text('Check-in'));
      await tester.scrollUntilVisible(action, 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    });
  });
}
