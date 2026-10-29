import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/core/storage/device_preferences.dart';
import 'package:zoezidesk_member/core/storage/local_data_wiper.dart';
import 'package:zoezidesk_member/core/theme/theme_mode_controller.dart';
import 'package:zoezidesk_member/data/sync/sync.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  ProviderContainer? current;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
  });
  tearDown(() => env.dispose());

  void settingsTest(String description, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(description, (tester) async {
        current = null;
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        current?.dispose();
      });

  Future<ProviderContainer> openSettings(WidgetTester tester, {List<dynamic> extra = const []}) async {
    final c = current = ProviderContainer(overrides: [...env.overrides, ...extra.cast()]);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    c.read(routerProvider).push(Routes.settings);
    await settle(tester);
    return c;
  }

  ThemeMode appMode(WidgetTester tester) => tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  test('device preferences round-trip and ignore unknown values', () async {
    final prefs = DevicePreferences(env.store);
    expect(await prefs.readThemeMode(), isNull);
    await prefs.writeThemeMode(ThemeMode.light);
    expect(await prefs.readThemeMode(), ThemeMode.light);
    env.store.values[DevicePreferences.themeModeKey] = 'purple';
    expect(await prefs.readThemeMode(), isNull);
  });

  test('logging out keeps the theme but removes the member data', () async {
    await DevicePreferences(env.store).writeThemeMode(ThemeMode.light);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(c.dispose);

    await c.read(localDataWiperProvider).wipeAll();

    expect(env.store.values, {DevicePreferences.themeModeKey: 'light'});
  });

  settingsTest('light by default; choosing dark applies and is saved', (tester) async {
    await openSettings(tester);
    expect(appMode(tester), ThemeMode.light);

    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(appMode(tester), ThemeMode.dark);
    expect(env.store.values[DevicePreferences.themeModeKey], 'dark');

    await tester.tap(find.text('Match my phone'));
    await settle(tester);
    expect(appMode(tester), ThemeMode.system);
  });

  settingsTest('the saved theme is used from the first frame', (tester) async {
    await openSettings(tester, extra: [initialThemeModeProvider.overrideWithValue(ThemeMode.dark)]);
    expect(appMode(tester), ThemeMode.dark);
  });

  settingsTest('unsent changes are shown and can be sent now', (tester) async {
    final c = await openSettings(tester);
    expect(find.text('Everything is saved to your account'), findsOneWidget);

    await io(tester, () => c.read(outboxServiceProvider).enqueue(
          kind: 'class_book',
          targetId: 1,
          method: 'POST',
          path: '/member/classes/1/book',
        ));
    await settle(tester);
    expect(find.textContaining('1 change is waiting to be sent'), findsOneWidget);

    final before = env.http.requests.length;
    await tester.tap(find.text('Send now'));
    await settle(tester);
    expect(env.http.requests.length, greaterThan(before));
  });

  settingsTest('logging out with unsent changes warns first', (tester) async {
    final c = await openSettings(tester);
    await io(tester, () => c.read(outboxServiceProvider).enqueue(
          kind: 'class_book',
          targetId: 1,
          method: 'POST',
          path: '/member/classes/1/book',
        ));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Log out'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(find.textContaining('1 change has not been sent yet and will be lost'), findsOneWidget);
    await tester.tap(find.text('Log out anyway'));
    await settle(tester);

    expect(find.text('Send code'), findsOneWidget);
  });

  settingsTest('logging out with nothing unsent has no warning', (tester) async {
    await openSettings(tester);
    await tester.scrollUntilVisible(find.text('Log out'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await settle(tester);

    expect(find.textContaining('will be lost'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Log out'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
  });

  settingsTest('More opens Settings', (tester) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    await tester.tap(find.text('More'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Appearance'), findsOneWidget);
    // Test builds have no Firebase project.
    expect(find.textContaining('Notifications are not available on this phone'), findsOneWidget);
  });
}
