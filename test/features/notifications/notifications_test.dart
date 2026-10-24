import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/notifications/push_messaging.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/core/storage/device_preferences.dart';
import 'package:zoezidesk_member/features/auth/state/session_controller.dart';
import 'package:zoezidesk_member/features/notifications/notifications_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late FakePushMessaging push;
  ProviderContainer? current;

  setUp(() async {
    env = TestEnv();
    push = FakePushMessaging();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.devicesApi.register(any())).thenAnswer((_) async {});
    when(() => env.devicesApi.unregister(any())).thenAnswer((_) async {});
  });
  tearDown(() => env.dispose());

  void pushTest(String description, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(description, (tester) async {
        current = null;
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        current?.dispose();
      });

  Future<ProviderContainer> start(WidgetTester tester) async {
    final c = current = ProviderContainer(overrides: [
      ...env.overrides,
      pushMessagingProvider.overrideWithValue(push),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    return c;
  }

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  pushTest('a signed-in phone asks once and registers its token', (tester) async {
    final c = await start(tester);

    expect(push.calls, ['permission']);
    verify(() => env.devicesApi.register('fcm-1')).called(1);
    expect(c.read(notificationsControllerProvider), NotificationStatus.on);
  });

  pushTest('a new token from Firebase is registered too', (tester) async {
    await start(tester);

    push.refreshes.add('fcm-2');
    await settle(tester);

    verify(() => env.devicesApi.register('fcm-2')).called(1);
  });

  pushTest('when the phone blocks notifications, nothing is registered', (tester) async {
    push.allow = false;
    final c = await start(tester);

    expect(c.read(notificationsControllerProvider), NotificationStatus.blocked);
    verifyNever(() => env.devicesApi.register(any()));
  });

  pushTest('offline registration does not break the app', (tester) async {
    when(() => env.devicesApi.register(any())).thenThrow(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    ));
    final c = await start(tester);

    expect(c.read(notificationsControllerProvider), NotificationStatus.on);
    expect(find.text('Hi, Jane'), findsOneWidget);
  });

  pushTest('turning notifications off and on in Settings', (tester) async {
    final c = await start(tester);
    c.read(routerProvider).push(Routes.settings);
    await settle(tester);

    await tester.scrollUntilVisible(find.text('App notifications'), 200);
    await tester.tap(find.text('App notifications'));
    await settle(tester);

    expect(c.read(notificationsControllerProvider), NotificationStatus.off);
    verify(() => env.devicesApi.unregister('fcm-1')).called(1);
    expect(push.calls, contains('deleteToken'));
    expect(await io(tester, () => DevicePreferences(env.store).readNotificationsEnabled()), isFalse);

    await tester.tap(find.text('App notifications'));
    await settle(tester);

    expect(c.read(notificationsControllerProvider), NotificationStatus.on);
    verify(() => env.devicesApi.register('fcm-1')).called(2);
  });

  pushTest('turned off stays off at the next start', (tester) async {
    await io(tester, () => DevicePreferences(env.store).writeNotificationsEnabled(false));
    final c = await start(tester);

    expect(c.read(notificationsControllerProvider), NotificationStatus.off);
    expect(push.calls, isEmpty);
    verifyNever(() => env.devicesApi.register(any()));
  });

  pushTest('the blocked state explains where to allow notifications', (tester) async {
    push.allow = false;
    final c = await start(tester);
    c.read(routerProvider).push(Routes.settings);
    await settle(tester);

    await tester.scrollUntilVisible(find.textContaining('blocking notifications'), 200);
    expect(find.textContaining('Apps > ZoeziDesk > Notifications'), findsOneWidget);
  });

  pushTest('tapping a class booking notification opens Classes', (tester) async {
    when(() => env.classesApi.classes(from: any(named: 'from'), days: any(named: 'days')))
        .thenAnswer((_) async => {'classes': <dynamic>[]});
    final c = await start(tester);

    push.opened.add(const PushMessage(title: 'Class Booked ✅', body: 'Spin', url: '/member/classes'));
    await settle(tester);

    expect(location(c), Routes.classes);
  });

  pushTest('the notification that started the app is opened once signed in', (tester) async {
    push.launchedFrom = const PushMessage(title: 'Payment Confirmed ✅', url: '/member/dashboard');
    final c = await start(tester);

    expect(location(c), Routes.home);
  });

  pushTest('a notification while the app is open shows a banner', (tester) async {
    await start(tester);

    push.foreground.add(const PushMessage(
      title: 'Payment Confirmed ✅',
      body: 'KES 3,000 received.',
      url: '/member/dashboard',
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Payment Confirmed ✅ · KES 3,000 received.'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'View'), findsOneWidget);
  });

  pushTest('nothing is registered while signed out', (tester) async {
    final c = await start(tester);
    clearInteractions(env.devicesApi);

    await c.read(sessionControllerProvider.notifier).logout();
    await settle(tester);
    push.refreshes.add('fcm-3');
    await settle(tester);

    verifyNever(() => env.devicesApi.register(any()));
  });

  test('web portal paths map to app screens', () {
    expect(const PushMessage(url: '/member/classes').route, Routes.classes);
    expect(const PushMessage(url: '/member/payments').route, Routes.payments);
    expect(const PushMessage(url: '/member/dashboard').route, Routes.home);
    expect(const PushMessage(url: '').route, Routes.home);
  });
}
