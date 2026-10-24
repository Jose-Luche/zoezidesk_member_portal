import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/core/sync/outbox_service.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';
import 'package:zoezidesk_member/data/repositories/workouts_repository.dart';
import 'package:zoezidesk_member/data/sync/sync.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  final haptics = <String>[];

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.workoutsApi.exercises()).thenAnswer((_) async => workoutLibraryJson());
    when(() => env.workoutsApi.page(any())).thenAnswer((_) async => workoutHistoryJson([]));
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
        return null;
      },
    );
  });
  tearDown(() => env.dispose());

  ProviderContainer? current;

  Future<ProviderContainer> openHub(WidgetTester tester) async {
    final c = current = ProviderContainer(overrides: env.overrides);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workouts'));
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

  /// Unmounts the app and disposes the container, which stops the outbox's
  /// retry timer before the test ends.
  void workoutTest(String description, Future<void> Function(WidgetTester tester) body) =>
      testWidgets(description, (tester) async {
        current = null;
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        current?.dispose();
      });

  Future<void> sendQueued(ProviderContainer c) async {
    await env.db.update(env.db.outbox).write(const OutboxCompanion(nextAttemptAt: Value(null)));
    await c.read(outboxServiceProvider).drain();
  }

  workoutTest('start, add an exercise, log sets offline, finish', (tester) async {
    final c = await openHub(tester);

    await tapText(tester, 'Chest');
    expect(find.text('Chest workout'), findsOneWidget);
    expect(find.text('Add your first exercise'), findsOneWidget);

    // The picker starts filtered to the workout's focus.
    await tapText(tester, 'Add exercise');
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Treadmill Run'), findsNothing);
    await tapText(tester, 'Bench Press');

    expect(find.textContaining('Last time (20 Oct 2026): 60 kg × 8, 62.5 kg × 6'), findsOneWidget);
    await tapText(tester, 'Log first set');
    // Prefilled from last time.
    expect(find.widgetWithText(TextField, '60'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase reps')); // 8 → 9
    await tester.pump();
    await tester.tap(find.text('Log set'));
    await settle(tester);

    expect(find.text('60 kg × 9'), findsOneWidget);
    expect(find.text('Saved on this phone. Sends to your account when online.'), findsOneWidget);

    // The next set starts from the previous one.
    await tapText(tester, 'Add set');
    await tester.tap(find.byTooltip('Increase weight')); // 60 → 62.5
    await tester.pump();
    await tester.tap(find.text('Log set'));
    await settle(tester);
    expect(find.text('62.5 kg × 9'), findsOneWidget);

    env.now = testNow.add(const Duration(minutes: 35));
    await tapText(tester, 'Finish workout');
    await tester.tap(find.text('Great'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish workout').last);
    await settle(tester);

    expect(find.text('Workout complete. Nice work!'), findsOneWidget);
    expect(find.textContaining('35 min'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Repeat this workout'), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    expect(await io(tester, () => c.read(workoutsRepositoryProvider).active()), isNull);
  });

  workoutTest('when the session reaches the server: saved, with a PR celebration', (tester) async {
    final c = await openHub(tester);
    final repo = c.read(workoutsRepositoryProvider);
    await io(tester, () => repo.refreshLibrary());
    final bench = (await io(tester, () => repo.watchLibrary().first)).first;
    final id = await io(tester, () => repo.start(dayType: 'Chest workout', muscleGroup: 'chest'));
    await io(tester, () => repo.addExercise(id, bench));
    final ex = (await io(tester, () => repo.watchSession(id).first))!.exercises.single.exercise;
    await io(tester, () => repo.addSet(ex.clientId, const SetValues(weight: 70, reps: 5)));
    c.read(routerProvider).push(Routes.workoutSession(id));
    await settle(tester);
    final set = (await io(tester, () => repo.watchSession(id).first))!.exercises.single.sets.single;

    env.http.reply(200, {
      'session': workoutSummaryJson(55, id, status: 'in_progress', date: '2026-10-23'),
      'exercises': [
        {
          'client_id': ex.clientId,
          'sets': [
            {'client_id': set.clientId, 'pr_types': ['max_weight_1rm']},
          ],
        },
      ],
      'new_prs': [
        {'set_client_id': set.clientId, 'exercise_name': 'Bench Press', 'metric_type': 'max_weight_1rm', 'value': 78.75, 'rep_count': null},
      ],
    });
    await io(tester, () => sendQueued(c));
    await settle(tester);

    expect(find.text('Saved to your account'), findsOneWidget);
    expect(find.text('New personal record! Bench Press: Estimated 1RM 78.75 kg'), findsOneWidget);
    expect(find.text('PR'), findsOneWidget);
    expect(find.text('1 PR'), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
  });

  workoutTest('a refusal shows why, and retry sends it again', (tester) async {
    final c = await openHub(tester);
    final id = await io(tester, () => c.read(workoutsRepositoryProvider).start(dayType: 'Chest workout'));
    env.http.reply(422, {'message': 'One of the exercises is no longer available at your gym.'});
    await io(tester, () => sendQueued(c));
    c.read(routerProvider).push(Routes.workoutSession(id));
    await settle(tester);

    expect(find.textContaining('Not saved to your account: One of the exercises'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Saved on this phone. Sends to your account when online.'), findsOneWidget);
  });

  workoutTest('edit and delete a set', (tester) async {
    final c = await openHub(tester);
    final repo = c.read(workoutsRepositoryProvider);
    await io(tester, () => repo.refreshLibrary());
    final id = await io(tester, () => repo.start(dayType: 'Chest workout'));
    final lib = await io(tester, () => repo.watchLibrary().first);
    await io(tester, () => repo.addExercise(id, lib.first));
    final ex = (await io(tester, () => repo.watchSession(id).first))!.exercises.single.exercise;
    await io(tester, () => repo.addSet(ex.clientId, const SetValues(weight: 60, reps: 8)));
    await io(tester, () => repo.addSet(ex.clientId, const SetValues(weight: 65, reps: 6)));
    c.read(routerProvider).push(Routes.workoutSession(id));
    await settle(tester);

    await tapText(tester, '60 kg × 8');
    await tester.enterText(find.widgetWithText(TextField, '8'), '10');
    await tester.tap(find.text('Save changes'));
    await settle(tester);
    expect(find.text('60 kg × 10'), findsOneWidget);

    await tapText(tester, '60 kg × 10');
    await tester.tap(find.text('Delete set'));
    await settle(tester);
    expect(find.text('60 kg × 10'), findsNothing);
    expect(find.text('Set 1'), findsOneWidget); // renumbered
    expect(find.text('65 kg × 6'), findsOneWidget);
  });

  workoutTest('cardio sets take time and distance; reps are required for strength', (tester) async {
    final c = await openHub(tester);
    final repo = c.read(workoutsRepositoryProvider);
    await io(tester, () => repo.refreshLibrary());
    final lib = await io(tester, () => repo.watchLibrary().first);
    final id = await io(tester, () => repo.start(dayType: 'Cardio workout', muscleGroup: 'cardio'));
    await io(tester, () => repo.addExercise(id, lib.firstWhere((e) => e.muscleGroup == 'cardio')));
    c.read(routerProvider).push(Routes.workoutSession(id));
    await settle(tester);

    await tapText(tester, 'Log first set');
    expect(find.text('Weight (kg)'), findsNothing);
    await tester.tap(find.text('Log set'));
    await tester.pump();
    expect(find.text('Enter the time or the distance.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Time (minutes)'), '30');
    await tester.enterText(find.widgetWithText(TextField, 'Distance (km)'), '5.2');
    await tester.tap(find.text('Log set'));
    await settle(tester);
    expect(find.text('30 min · 5.2 km'), findsOneWidget);
  });

  workoutTest('discard asks first and removes the workout', (tester) async {
    final c = await openHub(tester);
    final id = await io(tester, () => c.read(workoutsRepositoryProvider).start(dayType: 'Chest workout'));
    c.read(routerProvider).push(Routes.workoutSession(id));
    await settle(tester);

    await tester.tap(find.byTooltip('Workout options'));
    await settle(tester);
    await tester.tap(find.text('Discard workout'));
    await settle(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);

    expect(find.text('Start a workout'), findsOneWidget);
    expect(find.text('Workout in progress'), findsNothing);
    final queued = await io(tester, () => env.db.select(env.db.outbox).get());
    expect(queued.where((o) => o.status == OutboxStatus.pending).single.kind, WorkoutOutboxKind.discard);
  });

  workoutTest('a workout in progress shows on the hub; starting another asks first', (tester) async {
    final c = await openHub(tester);
    await io(tester, () => c.read(workoutsRepositoryProvider).start(dayType: 'Leg workout', muscleGroup: 'legs'));
    await settle(tester);

    expect(find.text('Workout in progress'), findsOneWidget);
    expect(find.text('Leg workout'), findsOneWidget);

    await tapText(tester, 'Chest');
    expect(find.text('A workout is in progress'), findsOneWidget);
    await tester.tap(find.text('Open it'));
    await settle(tester);
    expect(find.text('Add your first exercise'), findsOneWidget);

    // "Legs" picks leg exercises, which are tagged by part.
    await tapText(tester, 'Add exercise');
    expect(find.text('No matches'), findsOneWidget);
  });

  workoutTest('history opens a past workout, loads its sets, and repeats it', (tester) async {
    when(() => env.workoutsApi.page(1)).thenAnswer((_) async => workoutHistoryJson([
          workoutSummaryJson(21, 'srv-21', dayType: 'Push day', date: '2026-10-21'),
        ]));
    when(() => env.workoutsApi.show(21)).thenAnswer((_) async => {
          'session': workoutSummaryJson(21, 'srv-21', dayType: 'Push day', date: '2026-10-21'),
          'exercises': [
            {
              'client_id': 'we-1',
              'exercise_id': 1,
              'name': 'Bench Press',
              'muscle_group': 'chest',
              'position': 1,
              'notes': null,
              'sets': [
                {'client_id': 'st-1', 'set_number': 1, 'weight': 60, 'reps': 8, 'completed_at': null, 'pr_types': []},
              ],
            },
          ],
        });
    final c = await openHub(tester);

    // Recent on the hub.
    await tester.scrollUntilVisible(find.text('Push day'), 200, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('Workout history'), -200, scrollable: find.byType(Scrollable).first);
    await tapText(tester, 'Workout history');
    expect(find.textContaining('Wed 21 Oct · 45 min · 6 sets · 2,400 kg'), findsOneWidget);

    await tapText(tester, 'Push day');
    expect(find.text('60 kg × 8'), findsOneWidget);
    expect(find.text('Add set'), findsNothing); // read-only
    expect(find.text('Good'), findsOneWidget);

    await tapText(tester, 'Repeat this workout');
    expect(find.text('Log first set'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect((await io(tester, () => c.read(workoutsRepositoryProvider).active()))!.dayType, 'Push day');
  });

  workoutTest('a past workout offline without its sets says so', (tester) async {
    when(() => env.workoutsApi.page(1)).thenAnswer((_) async => workoutHistoryJson([
          workoutSummaryJson(21, 'srv-21', dayType: 'Push day'),
        ]));
    when(() => env.workoutsApi.show(21)).thenThrow(
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
    );
    await openHub(tester);

    await tapText(tester, 'Push day');
    expect(find.text('You are offline'), findsOneWidget);
  });

  workoutTest('personal records', (tester) async {
    when(() => env.workoutsApi.prs()).thenAnswer((_) async => {
          'total': 2,
          'this_month': 2,
          'exercises': [
            {
              'exercise_id': 1,
              'name': 'Bench Press',
              'muscle_group': 'chest',
              'best_1rm': 78.75,
              'last_at': '2026-10-23T09:15:00+03:00',
              'records': [
                {'id': 2, 'metric_type': 'max_weight_1rm', 'value': 78.75, 'rep_count': null, 'logged_at': '2026-10-23T09:15:00+03:00'},
                {'id': 1, 'metric_type': 'max_weight_at_reps', 'value': 70, 'rep_count': 5, 'logged_at': '2026-10-23T09:15:00+03:00'},
              ],
            },
          ],
        });
    await openHub(tester);

    await tapText(tester, 'Personal records');
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.textContaining('Best est. 1RM 78.75 kg'), findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await settle(tester);
    expect(find.text('Heaviest for 5 reps: 70 kg'), findsOneWidget);
  });

  workoutTest('exercise library works offline once saved and shows how to', (tester) async {
    when(() => env.workoutsApi.exercises()).thenAnswer((_) async => workoutLibraryJson([
          libraryExerciseJson(1, 'Bench Press', instructions: 'Lie on the bench.\nLower the bar to your chest.'),
          libraryExerciseJson(3, 'Treadmill Run', muscle: 'cardio'),
        ]));
    final c = await openHub(tester);
    await io(tester, () => c.read(workoutsRepositoryProvider).refreshLibrary());
    when(() => env.workoutsApi.exercises()).thenThrow(
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
    );

    await tapText(tester, 'Exercise library');
    await tester.enterText(find.byType(TextField), 'bench');
    await settle(tester);
    expect(find.text('Treadmill Run'), findsNothing);
    await tester.tap(find.text('Bench Press'));
    await settle(tester);
    expect(find.text('Lower the bar to your chest.'), findsOneWidget);
  });
}
