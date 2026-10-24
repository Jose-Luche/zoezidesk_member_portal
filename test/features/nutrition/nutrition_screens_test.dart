import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_app.dart';

DioException offline() => DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late TestEnv env;
  ProviderContainer? current;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.nutritionApi.foods()).thenAnswer((_) async => foodsJson());
    when(() => env.nutritionApi.days(any(), any())).thenAnswer((_) async => {'logs': [], 'goal': goalJson});
    when(() => env.nutritionApi.goal()).thenAnswer((_) async => goalSettingsJson());
  });
  tearDown(() => env.dispose());

  /// Unmounts and disposes the container so the outbox timer stops.
  void nutritionTest(String description, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(description, (tester) async {
        current = null;
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        current?.dispose();
      });

  Future<ProviderContainer> open(WidgetTester tester, [String route = Routes.nutrition]) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    c.read(routerProvider).push(route);
    await settle(tester);
    return c;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await settle(tester);
  }

  nutritionTest('add food offline: totals update and it waits to be sent', (tester) async {
    await open(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('2,300 kcal left'), findsOneWidget);

    await tapText(tester, 'Add food');
    await tester.enterText(find.byType(TextField), 'uga');
    await tester.pumpAndSettle();
    expect(find.text('Chapati'), findsNothing);
    await tapText(tester, 'Ugali');

    // A serving to start with, and the macros for it.
    expect(find.text('1 plate = 250g'), findsOneWidget);
    expect(find.textContaining('900 kcal · protein 20.3 g'), findsOneWidget);
    await tester.tap(find.text('Dinner'));
    await tester.pump();
    await tester.tap(find.text('Add to diary'));
    await settle(tester);

    expect(find.text('Ugali'), findsOneWidget);
    expect(find.text('250 g · 900 kcal'), findsOneWidget);
    expect(find.text('Not sent yet'), findsOneWidget);
    expect(find.text('900 kcal'), findsWidgets);
    expect(find.text('1,400 kcal left'), findsOneWidget);
  });

  nutritionTest('Swahili names are searchable; servings set the amount', (tester) async {
    await open(tester);
    await tapText(tester, 'Add food');
    await tester.enterText(find.byType(TextField), 'sukuma');
    await tester.pumpAndSettle();
    await tapText(tester, 'Sukuma wiki');

    await tester.tap(find.text('2 servings (200 g)'));
    await tester.pump();
    expect(find.textContaining('70 kcal'), findsOneWidget);
  });

  nutritionTest('edit the amount, and remove an entry', (tester) async {
    when(() => env.nutritionApi.days(any(), any())).thenAnswer((_) async => {
          'logs': [diaryEntryJson('srv-1', date: '2026-10-23')],
          'goal': goalJson,
        });
    await open(tester);
    expect(find.text('250 g · 900 kcal'), findsOneWidget);

    await tapText(tester, 'Ugali');
    await tester.enterText(find.widgetWithText(TextField, 'Amount (grams)'), '100');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await settle(tester);
    expect(find.text('100 g · 360 kcal'), findsOneWidget);

    await tapText(tester, 'Ugali');
    await tester.tap(find.text('Remove from diary'));
    await settle(tester);
    expect(find.text('Ugali'), findsNothing);
  });

  nutritionTest('over the goal is flagged', (tester) async {
    when(() => env.nutritionApi.days(any(), any())).thenAnswer((_) async => {
          'logs': [diaryEntryJson('srv-1', date: '2026-10-23', calories: 2500)],
          'goal': goalJson,
        });
    await open(tester);
    expect(find.text('200 kcal over'), findsOneWidget);
  });

  nutritionTest('earlier days, but not the future', (tester) async {
    await open(tester);
    final next = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
    expect(next.onPressed, isNull);

    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    expect(find.text('Yesterday'), findsOneWidget);
    verify(() => env.nutritionApi.days('2026-10-16', '2026-10-22')).called(1);
  });

  nutritionTest('no goal yet points to setting one', (tester) async {
    when(() => env.nutritionApi.days(any(), any())).thenAnswer((_) async => {'logs': [], 'goal': null});
    when(() => env.nutritionApi.goal()).thenAnswer((_) async => goalSettingsJson(goal: null));
    await open(tester);

    expect(find.text('Set a daily goal to see how your day adds up.'), findsOneWidget);
    await tester.tap(find.text('Set goal'));
    await settle(tester);
    expect(find.text('Start from a goal'), findsOneWidget);
  });

  nutritionTest('set a goal from a preset and adjust it', (tester) async {
    when(() => env.nutritionApi.setGoal(any())).thenAnswer((inv) async => {
          'goal': inv.positionalArguments.first as Map<String, dynamic>,
        });
    await open(tester, Routes.nutritionGoal);

    await tapText(tester, 'Fat Loss');
    expect(find.widgetWithText(TextField, '2000'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal)'), '1900');
    await tapText(tester, 'Save daily goal');

    verify(() => env.nutritionApi.setGoal({'goal_type': 'fat_loss', 'calories': 1900, 'protein': 150.0, 'carbs': 200.0, 'fat': 67.0}))
        .called(1);
    expect(find.text('Daily goal saved.'), findsOneWidget);
  });

  nutritionTest('goal checks and offline saving', (tester) async {
    when(() => env.nutritionApi.setGoal(any())).thenThrow(offline());
    await open(tester, Routes.nutritionGoal);

    await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal)'), '900');
    await tapText(tester, 'Save daily goal');
    expect(find.text('Daily calories should be at least 1,200.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal)'), '2100');
    await tapText(tester, 'Save daily goal');
    expect(find.text('You are offline. Saving your goal needs an internet connection.'), findsOneWidget);
  });

  nutritionTest('food list not saved and offline', (tester) async {
    when(() => env.nutritionApi.foods()).thenThrow(offline());
    when(() => env.nutritionApi.days(any(), any())).thenThrow(offline());
    await open(tester);

    expect(find.text('You are offline'), findsOneWidget);
    await tapText(tester, 'Add food');
    expect(find.text('Food list not saved yet'), findsOneWidget);
  });

  nutritionTest('More opens Nutrition', (tester) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    await tester.tap(find.text('More'));
    await settle(tester);
    await tapText(tester, 'Nutrition');
    expect(find.text('Today'), findsOneWidget);
  });
}
