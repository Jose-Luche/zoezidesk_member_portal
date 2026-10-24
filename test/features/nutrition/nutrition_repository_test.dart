import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/sync/outbox_service.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';
import 'package:zoezidesk_member/data/repositories/nutrition_repository.dart';
import 'package:zoezidesk_member/data/repositories/workouts_repository.dart' show SyncState;
import 'package:zoezidesk_member/data/sync/sync.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestEnv env;
  late ProviderContainer c;

  setUp(() {
    env = TestEnv();
    c = ProviderContainer(overrides: env.overrides);
    when(() => env.nutritionApi.foods()).thenAnswer((_) async => foodsJson());
  });
  tearDown(() async {
    c.dispose();
    await env.dispose();
  });

  NutritionRepository repo() => c.read(nutritionRepositoryProvider);
  OutboxService outbox() => c.read(outboxServiceProvider);
  final today = DateTime(2026, 10, 23);

  Future<FoodItem> food(int id) async {
    await repo().refreshFoods();
    return (await repo().watchFoods().first).firstWhere((f) => f.id == id);
  }

  Future<void> sendNow() async {
    await env.db.update(env.db.outbox).write(const OutboxCompanion(nextAttemptAt: Value(null)));
    await outbox().drain();
  }

  test('macros are worked out per 100 g, as on the web', () async {
    final ugali = await food(1);
    final m = Macros.of(ugali, 250);
    expect((m.calories, m.protein, m.carbs, m.fat), (900.0, 20.3, 192.5, 3.0));
  });

  test('logging offline saves the entry and queues it by its id', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 250, mealType: 'lunch', day: today);
    await outbox().drain();

    final entry = (await repo().watchDay(today).first).single;
    expect(entry.calories, 900);
    expect(entry.syncState, SyncState.pending);
    final queued = (await env.db.select(env.db.outbox).get()).single;
    expect(queued.method, 'PUT');
    expect(queued.path, '/member/diary/logs/${entry.clientId}');
    expect(jsonDecode(queued.body!), {'food_id': 1, 'quantity_g': 250.0, 'meal_type': 'lunch', 'logged_date': '2026-10-23'});
  });

  test('editing before it is sent sends only the latest version', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 250, mealType: 'lunch', day: today);
    await outbox().drain();
    final entry = (await repo().watchDay(today).first).single;

    await repo().update(entry, grams: 100, mealType: 'dinner');
    await outbox().drain();

    final updated = (await repo().watchDay(today).first).single;
    expect((updated.quantityG, updated.mealType, updated.calories), (100.0, 'dinner', 360.0));
    final pending = (await env.db.select(env.db.outbox).get());
    expect(pending, hasLength(1));
    expect(jsonDecode(pending.single.body!)['quantity_g'], 100.0);
  });

  test('confirmed by the server: synced, with the server numbers', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 250, mealType: 'lunch', day: today);
    await outbox().drain();
    final entry = (await repo().watchDay(today).first).single;

    env.http.reply(200, {'log': diaryEntryJson(entry.clientId, id: 77, calories: 901)});
    await sendNow();

    final synced = (await repo().watchDay(today).first).single;
    expect(synced.syncState, SyncState.synced);
    expect(synced.serverId, 77);
    expect(synced.calories, 901);
  });

  test('a refusal marks it failed with the reason; retry queues it again', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 250, mealType: 'lunch', day: today);
    env.http.reply(422, {'message': 'This food is no longer in the list.'});
    await sendNow();

    var entry = (await repo().watchDay(today).first).single;
    expect(entry.syncState, SyncState.failed);
    expect(entry.syncError, contains('no longer in the list'));

    await repo().retry(entry);
    await outbox().drain();
    entry = (await repo().watchDay(today).first).single;
    expect(entry.syncState, SyncState.pending);
  });

  test('delete removes it here and queues a delete instead of the save', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 250, mealType: 'lunch', day: today);
    await outbox().drain();
    final entry = (await repo().watchDay(today).first).single;

    await repo().delete(entry);
    await outbox().drain();

    expect(await repo().watchDay(today).first, isEmpty);
    final queued = await env.db.select(env.db.outbox).get();
    expect(queued.single.kind, DiaryOutboxKind.delete);
  });

  test('refreshing days: server wins, unsent entries stay, goal is cached', () async {
    final ugali = await food(1);
    await repo().add(ugali, grams: 100, mealType: 'snack', day: today);
    when(() => env.nutritionApi.days('2026-10-22', '2026-10-23')).thenAnswer((_) async => {
          'logs': [
            diaryEntryJson('srv-1', date: '2026-10-22', meal: 'breakfast'),
            diaryEntryJson('srv-2', id: 2, food: 'Chapati', foodId: 2, grams: 80, calories: 240),
          ],
          'goal': goalJson,
        });
    await repo().refreshDays(DateTime(2026, 10, 22), today);

    expect((await repo().watchDay(today).first).map((e) => e.foodName), ['Ugali', 'Chapati']);
    expect((await repo().watchDay(DateTime(2026, 10, 22)).first).single.clientId, 'srv-1');
    expect(await repo().watchDayFetchedAt(today).first, testNow);
    expect((await repo().watchGoal().first)!.data.goal!.calories, 2300);

    // Chapati was deleted on the web.
    when(() => env.nutritionApi.days('2026-10-22', '2026-10-23'))
        .thenAnswer((_) async => {'logs': [diaryEntryJson('srv-1', date: '2026-10-22')], 'goal': goalJson});
    await repo().refreshDays(DateTime(2026, 10, 22), today);
    expect((await repo().watchDay(today).first).map((e) => e.foodName), ['Ugali']);
  });

  test('offline keeps the cached day', () async {
    when(() => env.nutritionApi.days(any(), any())).thenAnswer((_) async => {'logs': [diaryEntryJson('srv-1')], 'goal': null});
    await repo().refreshDays(today, today);
    when(() => env.nutritionApi.days(any(), any())).thenThrow(
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
    );

    await expectLater(repo().refreshDays(today, today), throwsA(isA<NetworkFailure>()));
    expect(await repo().watchDay(today).first, hasLength(1));
  });

  test('goal: presets are cached and a new goal replaces the old one', () async {
    when(() => env.nutritionApi.goal()).thenAnswer((_) async => goalSettingsJson(goal: null));
    await repo().refreshGoal();
    var settings = (await repo().watchGoal().first)!.data;
    expect(settings.goal, isNull);
    expect(settings.presets.map((p) => p.name), contains('Fat Loss'));

    const chosen = NutritionGoalInfo(goalType: 'fat_loss', calories: 1900, protein: 140, carbs: 190, fat: 60);
    when(() => env.nutritionApi.setGoal(chosen.toJson())).thenAnswer((_) async => {'goal': chosen.toJson()});
    await repo().setGoal(chosen);

    settings = (await repo().watchGoal().first)!.data;
    expect(settings.goal!.calories, 1900);
    expect(settings.presets, hasLength(4)); // kept
  });
}
