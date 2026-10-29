import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/core/theme/app_theme.dart';
import 'package:zoezidesk_member/data/sync/sync.dart';
import 'package:zoezidesk_member/shared/widgets/weekly_bars.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_app.dart';

const _weeks8 = ['1 Sep', '8 Sep', '15 Sep', '22 Sep', '29 Sep', '6 Oct', '13 Oct', '20 Oct'];

Map<String, dynamic> muscleJson(String key, String label, String status, {int sets = 0, double? change, int? daysSince}) => {
      'key': key,
      'label': label,
      'status': status,
      'status_label': switch (status) {
        'progressing' => 'Progressing',
        'neglected' => 'Neglected',
        'no_data' => 'Not trained yet',
        _ => 'Plateau',
      },
      'strength_change': change,
      'sets_this_week': sets,
      'volume_status': sets < 6 ? 'below' : 'within',
      'weekly_sets': [0, 2, 0, 4, 6, 0, 3, sets],
      'last_trained': daysSince == null ? null : '2026-10-20',
      'days_since': daysSince,
    };

Map<String, dynamic> progressJson({int sessions = 12, int streak = 3}) => {
      'all_time': {'sessions': sessions, 'sets': 140, 'volume': 48200, 'prs': 9},
      'this_month': {'sessions': 5, 'sets': 60, 'volume': 21000, 'prs': 3},
      'streak': streak,
      'averages': {'volume_per_session': 4017, 'sets_per_session': 11.7},
      'top_exercises': [
        {'exercise_id': 1, 'name': 'Bench Press', 'muscle_group': 'chest', 'volume': 18000, 'sets': 40},
        {'exercise_id': 2, 'name': 'Back Squat', 'muscle_group': 'quads', 'volume': 15000, 'sets': 30},
      ],
      'muscles': {
        'goal': 'growth',
        'target_sets': [10, 20],
        'week_labels': _weeks8,
        'has_data': true,
        'items': [
          muscleJson('chest', 'Chest', 'progressing', sets: 12, change: 3.4, daysSince: 4),
          muscleJson('back_lats', 'Lats', 'neglected', sets: 0, daysSince: 21),
          muscleJson('calves', 'Calves', 'no_data'),
        ],
      },
      'generated_at': testNow.toIso8601String(),
    };

Map<String, dynamic> chestJson() => {
      'muscle': muscleJson('chest', 'Chest', 'progressing', sets: 12, change: 3.4, daysSince: 4),
      'goal': 'growth',
      'target_sets': [10, 20],
      'week_labels': ['4 Aug', '11 Aug', '18 Aug', '25 Aug', '1 Sep', '8 Sep', '15 Sep', '22 Sep', '29 Sep', '6 Oct', '13 Oct', '20 Oct'],
      'weekly_volume': [0, 0, 1200, 0, 1500, 0, 1800, 2000, 0, 2100, 0, 2400],
      'exercises': [
        {
          'id': 1, 'name': 'Bench Press', 'sets': 20, 'sessions': 6, 'last_date': '2026-10-20', 'best_set': '70 kg × 5',
          'best_e1rm': 78.8, 'uses_weight': true, 'change': 3.4,
          'weekly_best': [null, null, 70, null, 72, null, 74, 75, null, 77, null, 78.8],
        },
        {
          'id': 3, 'name': 'Push-up', 'sets': 6, 'sessions': 2, 'last_date': '2026-10-13', 'best_set': '20 reps',
          'best_e1rm': null, 'uses_weight': false, 'change': null,
          'weekly_best': [null, null, null, null, null, null, null, null, null, 15, null, 20],
        },
      ],
      'prs': [
        {'exercise': 'Bench Press', 'description': 'Est. 1RM 78.8 kg', 'date': '2026-10-20'},
      ],
      'generated_at': testNow.toIso8601String(),
    };

DioException offline() => DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);

void main() {
  late TestEnv env;
  ProviderContainer? current;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.workoutsApi.progress()).thenAnswer((_) async => progressJson());
    when(() => env.workoutsApi.muscleProgress('chest')).thenAnswer((_) async => chestJson());
    when(() => env.workoutsApi.page(any())).thenAnswer((_) async => workoutHistoryJson([]));
    when(() => env.workoutsApi.exercises()).thenAnswer((_) async => workoutLibraryJson());
  });
  tearDown(() => env.dispose());

  void progressTest(String description, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(description, (tester) async {
        current = null;
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        current?.dispose();
      });

  Future<ProviderContainer> open(WidgetTester tester, String route) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    c.read(routerProvider).push(route);
    await settle(tester);
    return c;
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    if (f.evaluate().isEmpty) await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
  }

  progressTest('streak, this month, all time and top exercises', (tester) async {
    await open(tester, Routes.workoutProgress);

    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('21,000'), findsOneWidget); // kg this month
    expect(find.text('48,200'), findsOneWidget); // kg all time
    expect(find.text('Per workout: 11.7 sets and 4,017 kg on average.'), findsOneWidget);
    await scrollTo(tester, find.text('Bench Press'));
    expect(find.text('18,000 kg'), findsOneWidget);
  });

  progressTest('muscle balance flags neglected muscles and opens the detail', (tester) async {
    await open(tester, Routes.workoutProgress);

    await scrollTo(tester, find.text('Lats'));
    expect(find.text('Neglected'), findsOneWidget);
    expect(find.textContaining('Last trained 21 days ago'), findsOneWidget);
    await scrollTo(tester, find.text('Chest'));
    expect(find.textContaining('+3.4% strength'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Not trained in the last 8 weeks'));
    expect(find.text('Not trained in the last 8 weeks: Calves.'), findsOneWidget);
    await scrollTo(tester, find.text('Chest'));

    await tester.tap(find.text('Chest'));
    await settle(tester);

    expect(find.text('Weight lifted per week'), findsOneWidget);
    // The latest week is shown to start with.
    expect(find.text('Week of 20 Oct: 2,400 kg'), findsOneWidget);
  });

  progressTest('muscle detail: choose an exercise, read the numbers as text', (tester) async {
    await open(tester, Routes.muscleProgress('chest'));

    await scrollTo(tester, find.text('Best estimated 1RM per week'));
    expect(find.text('Week of 20 Oct: 78.8 kg'), findsOneWidget);
    expect(find.textContaining('Best set 70 kg × 5'), findsOneWidget);

    final chip = find.widgetWithText(ChoiceChip, 'Push-up');
    await tester.scrollUntilVisible(chip, -150, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Best reps per week'));
    expect(find.text('Week of 20 Oct: 20 reps'), findsOneWidget);

    await scrollTo(tester, find.text('Recent records'));
    expect(find.text('Est. 1RM 78.8 kg'), findsOneWidget);

    await scrollTo(tester, find.text('See the numbers').first);
    await tester.tap(find.text('See the numbers').first);
    await tester.pumpAndSettle();
    expect(find.text('Week of 6 Oct'), findsWidgets);
  });

  progressTest('records sent as an object (PHP kept collection keys) still show', (tester) async {
    when(() => env.workoutsApi.muscleProgress('chest')).thenAnswer((_) async => {
          ...chestJson(),
          'prs': {
            '3': {'exercise': 'Bench Press', 'description': 'Est. 1RM 78.8 kg', 'date': '2026-10-20'},
          },
        });
    await open(tester, Routes.muscleProgress('chest'));

    await scrollTo(tester, find.text('Recent records'));
    expect(find.text('Est. 1RM 78.8 kg'), findsOneWidget);
  });

  progressTest('saved progress shows offline with its age', (tester) async {
    final c = ProviderContainer(overrides: env.overrides);
    await io(tester, () => c.read(workoutsRepositoryProvider).refreshProgress());
    c.dispose();
    when(() => env.workoutsApi.progress()).thenThrow(offline());
    env.now = testNow.add(const Duration(days: 2));

    await open(tester, Routes.workoutProgress);

    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.textContaining('You are offline. Showing saved data from'), findsOneWidget);
  });

  progressTest('first visit offline, and no workouts yet', (tester) async {
    when(() => env.workoutsApi.progress()).thenThrow(offline());
    await open(tester, Routes.workoutProgress);
    expect(find.text('You are offline'), findsOneWidget);
  });

  progressTest('no finished workouts yet', (tester) async {
    when(() => env.workoutsApi.progress()).thenAnswer((_) async => progressJson(sessions: 0, streak: 0));
    await open(tester, Routes.workoutProgress);
    expect(find.text('No finished workouts yet'), findsOneWidget);
  });

  progressTest('the Workouts tab links to Progress', (tester) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await settle(tester);
    await tester.tap(find.text('Workouts'));
    await settle(tester);
    await scrollTo(tester, find.text('Progress'));
    await tester.tap(find.text('Progress'));
    await settle(tester);
    expect(find.text('3-day streak'), findsOneWidget);
  });

  testWidgets('tapping a bar shows that week; screen readers get every week', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: WeeklyBars(
            values: const [100, null, 300],
            labels: const ['6 Oct', '13 Oct', '20 Oct'],
            format: (v) => '${v.round()} kg',
            semanticTitle: 'Weight lifted per week',
          ),
        ),
      ),
    ));

    expect(find.text('Week of 20 Oct: 300 kg'), findsOneWidget);
    await tester.tapAt(tester.getTopLeft(find.byType(CustomPaint).last) + const Offset(10, 70));
    await tester.pump();
    expect(find.text('Week of 6 Oct: 100 kg'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Weight lifted per week. Week of 6 Oct: 100 kg. Week of 13 Oct: none. Week of 20 Oct: 300 kg')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
