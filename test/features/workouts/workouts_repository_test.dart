import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/sync/outbox_service.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';
import 'package:zoezidesk_member/data/repositories/workouts_repository.dart';
import 'package:zoezidesk_member/data/sync/sync.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late ProviderContainer c;

  setUp(() {
    env = TestEnv();
    c = ProviderContainer(overrides: env.overrides);
  });
  tearDown(() async {
    c.dispose();
    await env.dispose();
  });

  WorkoutsRepository repo() => c.read(workoutsRepositoryProvider);
  OutboxService outbox() => c.read(outboxServiceProvider);

  Future<List<OutboxEntry>> queued() => env.db.select(env.db.outbox).get();

  Future<LibraryExercise> libraryExercise(int id) async {
    when(() => env.workoutsApi.exercises()).thenAnswer((_) async => workoutLibraryJson());
    await repo().refreshLibrary();
    return (await repo().watchLibrary().first).firstWhere((e) => e.id == id);
  }

  test('library is cached with the last time per exercise', () async {
    final bench = await libraryExercise(1);

    final last = LastTime.of(bench)!;
    expect(last.date, DateTime(2026, 10, 20));
    expect(last.sets.map((s) => (s.weight, s.reps)), [(60.0, 8), (62.5, 6)]);
    expect(LastTime.of((await repo().watchLibrary().first).firstWhere((e) => e.id == 2)), isNull);
    expect(await repo().watchLibraryFetchedAt().first, testNow);
  });

  test('logging offline saves locally and queues one whole-session document', () async {
    final bench = await libraryExercise(1);
    final id = await repo().start(dayType: 'Chest Workout', muscleGroup: 'chest');
    final active = await repo().active();
    expect(active!.clientId, id);

    await repo().addExercise(id, bench);
    final ex = (await repo().watchSession(id).first)!.exercises.single.exercise;
    await repo().addSet(ex.clientId, const SetValues(weight: 60, reps: 8));
    await repo().addSet(ex.clientId, const SetValues(weight: 62.5, reps: 6));
    await outbox().drain();

    final detail = (await repo().watchSession(id).first)!;
    expect(detail.session.syncState, SyncState.pending);
    expect(detail.session.totalSets, 2);
    expect(detail.session.totalVolume, 60 * 8 + 62.5 * 6);
    expect(detail.exercises.single.sets.map((s) => s.setNumber), [1, 2]);

    // Only the latest document waits to be sent.
    final entries = (await queued()).where((o) => o.kind == WorkoutOutboxKind.sync).toList();
    expect(entries, hasLength(1));
    expect(entries.single.method, 'PUT');
    expect(entries.single.path, '/member/workouts/sync/$id');
    final body = jsonDecode(entries.single.body!) as Map<String, dynamic>;
    expect(body['status'], 'in_progress');
    expect(body['session_date'], '2026-10-23');
    expect((body['exercises'] as List).single['exercise_id'], 1);
    expect(((body['exercises'] as List).single['sets'] as List).map((s) => s['weight']), [60.0, 62.5]);
  });

  test('when the server confirms, the session is synced and PRs are reported', () async {
    final bench = await libraryExercise(1);
    final id = await repo().start(dayType: 'Chest Workout');
    await repo().addExercise(id, bench);
    final ex = (await repo().watchSession(id).first)!.exercises.single.exercise;
    await repo().addSet(ex.clientId, const SetValues(weight: 70, reps: 5));
    await outbox().drain(); // offline: stays queued
    final set = (await repo().watchSession(id).first)!.exercises.single.sets.single;

    final prs = <NewPr>[];
    final sub = repo().newPrs.listen(prs.add);
    addTearDown(sub.cancel);
    env.http.reply(200, {
      'session': workoutSummaryJson(55, id, status: 'in_progress', date: '2026-10-23'),
      'exercises': [
        {
          'client_id': ex.clientId,
          'sets': [
            {'client_id': set.clientId, 'pr_types': ['max_weight_at_reps', 'max_weight_1rm']},
          ],
        },
      ],
      'new_prs': [
        {'set_client_id': set.clientId, 'exercise_name': 'Bench Press', 'metric_type': 'max_weight_1rm', 'value': 78.75, 'rep_count': null},
      ],
    });
    await env.db.update(env.db.outbox).write(const OutboxCompanion(nextAttemptAt: Value(null)));
    await outbox().drain();
    await pumpEventQueue();

    final detail = (await repo().watchSession(id).first)!;
    expect(detail.session.syncState, SyncState.synced);
    expect(detail.session.serverId, 55);
    expect(detail.exercises.single.sets.single.prTypes, 'max_weight_at_reps,max_weight_1rm');
    expect(detail.prCount, 1);
    expect(prs.single.value, 78.75);
  });

  test('a refusal marks the session failed with the reason; retry queues it again', () async {
    final id = await repo().start(dayType: 'Chest Workout');
    env.http.reply(422, {'message': 'One of the exercises is no longer available at your gym.'});
    await env.db.update(env.db.outbox).write(const OutboxCompanion(nextAttemptAt: Value(null)));
    await outbox().drain();

    var s = (await repo().watchSession(id).first)!.session;
    expect(s.syncState, SyncState.failed);
    expect(s.syncError, contains('no longer available'));

    await repo().retrySync(id);
    await outbox().drain();
    s = (await repo().watchSession(id).first)!.session;
    expect(s.syncState, SyncState.pending);
    expect((await queued()).where((o) => o.status == OutboxStatus.pending), hasLength(1));
  });

  test('deleting a set renumbers the rest; finishing records duration and rating', () async {
    final bench = await libraryExercise(1);
    final id = await repo().start(dayType: 'Chest Workout');
    await repo().addExercise(id, bench);
    final ex = (await repo().watchSession(id).first)!.exercises.single.exercise;
    for (final w in [50.0, 55.0, 60.0]) {
      await repo().addSet(ex.clientId, SetValues(weight: w, reps: 8));
    }
    final first = (await repo().watchSession(id).first)!.exercises.single.sets.first;
    await repo().deleteSet(first.clientId);
    var sets = (await repo().watchSession(id).first)!.exercises.single.sets;
    expect(sets.map((s) => (s.setNumber, s.weight)), [(1, 55.0), (2, 60.0)]);

    env.now = testNow.add(const Duration(minutes: 42));
    await repo().finish(id, rating: 'great', notes: '  Felt strong ');
    final s = (await repo().watchSession(id).first)!.session;
    expect(s.status, 'completed');
    expect(s.durationMinutes, 42);
    expect(s.rating, 'great');
    expect(s.notes, 'Felt strong');
    expect(await repo().active(), isNull);
    await outbox().drain();
    final body = jsonDecode((await queued()).single.body!) as Map<String, dynamic>;
    expect(body['status'], 'completed');
    expect(body['ended_at'], isNotNull);
  });

  test('discard removes it locally and queues a delete instead of the sync', () async {
    final id = await repo().start(dayType: 'Chest Workout');
    await repo().discard(id);

    expect(await repo().watchSession(id).first, isNull);
    final entries = await queued();
    expect(entries.single.kind, WorkoutOutboxKind.discard);
    expect(entries.single.method, 'DELETE');
  });

  test('repeat copies the exercises, not the sets', () async {
    final bench = await libraryExercise(1);
    final old = await repo().start(dayType: 'Chest Workout');
    await repo().addExercise(old, bench);
    final ex = (await repo().watchSession(old).first)!.exercises.single.exercise;
    await repo().addSet(ex.clientId, const SetValues(weight: 60, reps: 8));
    await repo().finish(old);

    final again = await repo().start(dayType: 'Chest Workout', copyFrom: old);
    final detail = (await repo().watchSession(again).first)!;
    expect(detail.exercises.single.exercise.name, 'Bench Press');
    expect(detail.exercises.single.exercise.clientId, isNot(ex.clientId));
    expect(detail.exercises.single.sets, isEmpty);
  });

  group('history', () {
    test('refresh caches summaries; server wins except for unsent sessions', () async {
      final local = await repo().start(dayType: 'Leg Workout');
      when(() => env.workoutsApi.page(1)).thenAnswer((_) async => workoutHistoryJson([
            workoutSummaryJson(2, 'srv-2', date: '2026-10-21'),
            workoutSummaryJson(1, 'srv-1', date: '2026-10-19', dayType: 'Back Workout'),
          ]));
      await repo().refreshHistory();

      expect((await repo().watchHistory().first).map((s) => s.clientId), [local, 'srv-2', 'srv-1']);

      // Session 1 was deleted on the web.
      when(() => env.workoutsApi.page(1))
          .thenAnswer((_) async => workoutHistoryJson([workoutSummaryJson(2, 'srv-2', date: '2026-10-21')]));
      await repo().refreshHistory();
      expect((await repo().watchHistory().first).map((s) => s.clientId), [local, 'srv-2']);
    });

    test('older pages append and are kept until they should have appeared', () async {
      when(() => env.workoutsApi.page(1)).thenAnswer((_) async =>
          workoutHistoryJson([workoutSummaryJson(3, 'srv-3', date: '2026-10-21')], lastPage: 2));
      when(() => env.workoutsApi.page(2)).thenAnswer((_) async =>
          workoutHistoryJson([workoutSummaryJson(1, 'srv-1', date: '2026-09-01')], page: 2, lastPage: 2));
      await repo().refreshHistory();
      final page2 = await repo().loadHistoryPage(2);
      expect(page2.hasMore, isFalse);

      await repo().refreshHistory();
      expect((await repo().watchHistory().first).map((s) => s.clientId), ['srv-3', 'srv-1']);
    });

    test('detail loads exercises and sets; a builder session is adopted for logging', () async {
      when(() => env.workoutsApi.show(9)).thenAnswer((_) async => {
            'session': workoutSummaryJson(9, 'srv-9', status: 'in_progress', date: '2026-10-23'),
            'exercises': [
              {
                'client_id': 'we-1',
                'exercise_id': 1,
                'name': 'Bench Press',
                'muscle_group': 'chest',
                'position': 1,
                'notes': null,
                'sets': [
                  {'client_id': 'set-1', 'set_number': 1, 'weight': 60, 'reps': 8, 'completed_at': null, 'pr_types': []},
                ],
              },
            ],
          });

      final id = await repo().adoptServerSession(9);

      expect(id, 'srv-9');
      final detail = (await repo().watchSession(id).first)!;
      expect(detail.isActive, isTrue);
      expect(detail.session.detailLoaded, isTrue);
      expect(detail.exercises.single.sets.single.weight, 60);
      expect((await repo().active())!.clientId, 'srv-9');
    });

    test('offline keeps the cached history', () async {
      when(() => env.workoutsApi.page(1))
          .thenAnswer((_) async => workoutHistoryJson([workoutSummaryJson(2, 'srv-2')]));
      await repo().refreshHistory();
      when(() => env.workoutsApi.page(1)).thenThrow(
        DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
      );

      await expectLater(repo().refreshHistory(), throwsA(isA<NetworkFailure>()));
      expect(await repo().watchHistory().first, hasLength(1));
    });
  });

  test('records are cached', () async {
    when(() => env.workoutsApi.prs()).thenAnswer((_) async => {
          'total': 3,
          'this_month': 2,
          'exercises': [
            {
              'exercise_id': 1,
              'name': 'Bench Press',
              'muscle_group': 'chest',
              'best_1rm': 78.75,
              'last_at': '2026-10-23T09:15:00+03:00',
              'records': [
                {'id': 1, 'metric_type': 'max_weight_1rm', 'value': 78.75, 'rep_count': null, 'logged_at': '2026-10-23T09:15:00+03:00'},
              ],
            },
          ],
        });
    await repo().refreshRecords();

    final records = (await repo().watchRecords().first)!.data;
    expect(records.total, 3);
    expect(records.exercises.single.best1rm, 78.75);
    expect(records.exercises.single.records.single.metricType, 'max_weight_1rm');
  });
}
