import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/features/dashboard/widgets/membership_card.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.profileApi.profile()).thenAnswer((_) async => profileJson());
  });

  tearDown(() => env.dispose());

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZoeziApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DioException offline() => DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );

  group('membership card', () {
    testWidgets('dashboard card opens the full-screen card with a Hero', (tester) async {
      await pumpApp(tester);
      expect(find.byType(Hero), findsOneWidget);

      await tester.tap(find.text('Jane Wanjiru'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-flight: the Hero is in the overlay between the two routes.
      expect(find.byType(MembershipCard), findsWidgets);
      await tester.pumpAndSettle();

      expect(find.text('Membership card'), findsOneWidget);
      expect(find.text('Show this code at the front desk to check in.'), findsOneWidget);
      final qr = tester.getSize(find.byType(QrImageView));
      expect(qr.width, greaterThan(200));
    });

    testWidgets('works offline from the cache', (tester) async {
      final container = await pumpApp(tester);
      when(() => env.dashboardApi.dashboard()).thenThrow(offline());
      when(() => env.dashboardApi.memberCard()).thenThrow(offline());

      container.read(routerProvider).push(Routes.membershipCard);
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Expires in 3 days'), findsNothing);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('explains when nothing is cached yet', (tester) async {
      when(() => env.dashboardApi.dashboard()).thenThrow(offline());
      when(() => env.dashboardApi.memberCard()).thenThrow(offline());
      final container = await pumpApp(tester);

      container.read(routerProvider).push(Routes.membershipCard);
      await tester.pumpAndSettle();

      expect(find.text('Card not saved yet'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });
  });

  group('profile', () {
    Future<void> openProfile(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows details, history and gym contact', (tester) async {
      await pumpApp(tester);
      await openProfile(tester);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Active member'), findsOneWidget);
      expect(find.text('254711000001'), findsOneWidget);
      expect(find.text('12 Apr 1995'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('John Wanjiru'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      final history = find.text('Membership history');
      await tester.scrollUntilVisible(history, 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('13 Oct 2026 – 12 Nov 2026'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget); // lapsed record

      final note = find.text('To change your details, contact the front desk.');
      await tester.scrollUntilVisible(note, 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Moi Avenue, Nairobi'), findsOneWidget);
    });

    testWidgets('without a photo shows initials', (tester) async {
      await pumpApp(tester);
      await openProfile(tester);
      expect(find.text('JW'), findsOneWidget);
    });

    testWidgets('offline first visit shows the offline state', (tester) async {
      when(() => env.profileApi.profile()).thenThrow(offline());
      await pumpApp(tester);
      await openProfile(tester);

      expect(find.text('You are offline'), findsOneWidget);
    });

    testWidgets('offline later shows the saved profile', (tester) async {
      await pumpApp(tester);
      await openProfile(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      when(() => env.profileApi.profile()).thenThrow(offline());
      await openProfile(tester);

      expect(find.text('254711000001'), findsOneWidget);
      expect(find.textContaining('You are offline. Showing saved data'), findsOneWidget);
    });

    testWidgets('More tab links to profile and card', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Membership card'));
      await tester.pumpAndSettle();
      expect(find.text('Show this code at the front desk to check in.'), findsOneWidget);
    });
  });

  testWidgets('logout clears cached photos', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(env.imageCacheCleared, 1);
  });
}
