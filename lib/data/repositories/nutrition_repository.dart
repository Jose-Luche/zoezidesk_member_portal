import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/sync/outbox_service.dart';
import '../api/nutrition_api.dart';
import '../db/app_database.dart';
import '../db/encrypted_cache.dart';
import 'workouts_repository.dart' show SyncState;

abstract final class DiaryOutboxKind {
  static const put = 'diary_put';
  static const delete = 'diary_delete';
}

const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack', 'post_workout'];

/// Calories and macros for an amount of food.
class Macros {
  const Macros({this.calories = 0, this.protein = 0, this.carbs = 0, this.fat = 0});

  /// As the web's Food::calculateMacros: per 100 g, rounded to 0.1.
  factory Macros.of(FoodItem f, double grams) {
    double r(double per100) => (per100 * grams / 100 * 10).round() / 10;
    return Macros(
      calories: r(f.caloriesPer100g),
      protein: r(f.proteinPer100g),
      carbs: r(f.carbsPer100g),
      fat: r(f.fatPer100g),
    );
  }

  factory Macros.sum(Iterable<DiaryEntry> entries) => entries.fold(
        const Macros(),
        (t, e) => Macros(
          calories: t.calories + e.calories,
          protein: t.protein + e.protein,
          carbs: t.carbs + e.carbs,
          fat: t.fat + e.fat,
        ),
      );

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

/// Daily targets.
class NutritionGoalInfo {
  const NutritionGoalInfo({
    required this.goalType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.name,
  });

  factory NutritionGoalInfo.fromJson(Map<String, dynamic> j) => NutritionGoalInfo(
        goalType: '${j['goal_type']}',
        name: j['name'] as String?,
        calories: (j['calories'] as num).toInt(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
      );

  final String goalType;
  final String? name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, dynamic> toJson() => {
        'goal_type': goalType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

class GoalSettings {
  const GoalSettings({this.goal, this.presets = const []});

  factory GoalSettings.fromJson(Map<String, dynamic> j) => GoalSettings(
        goal: j['goal'] == null ? null : NutritionGoalInfo.fromJson((j['goal'] as Map).cast<String, dynamic>()),
        presets: [
          for (final p in (j['presets'] as List? ?? const []))
            NutritionGoalInfo.fromJson((p as Map).cast<String, dynamic>()),
        ],
      );

  final NutritionGoalInfo? goal;
  final List<NutritionGoalInfo> presets;
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The food diary, offline first, as WorkoutsRepository: entries are saved
/// here, then sent one by one through the outbox, addressed by the app's
/// ids. Days fetched from the server replace synced entries (server wins)
/// but keep unsent ones. The goal is changed online only.
class NutritionRepository {
  NutritionRepository({
    required this._db,
    required this._cache,
    required this._api,
    required this._outbox,
    required this._clock,
    this._uuid = const Uuid(),
  });

  static const foodsSyncKey = 'food_catalogue';
  static const goalKey = 'nutrition_goal';
  static String daySyncKey(DateTime d) => 'diary:${dayKey(d)}';

  final AppDatabase _db;
  final EncryptedCache _cache;
  final NutritionApi _api;
  final OutboxService _outbox;
  final DateTime Function() _clock;
  final Uuid _uuid;

  late final OutboxHandler outboxHandler = _DiaryOutboxHandler(this);

  // ── Catalogue ──────────────────────────────────────────────────────

  Stream<List<FoodItem>> watchFoods() =>
      (_db.select(_db.foodItems)..orderBy([(f) => OrderingTerm.asc(f.name)])).watch();

  /// Throws [AppFailure].
  Future<void> refreshFoods() async {
    final json = await guardRequest(_api.foods);
    final rows = [
      for (final raw in (json['foods'] as List? ?? const [])) _foodRow((raw as Map).cast<String, dynamic>()),
    ];
    await _db.transaction(() async {
      await _db.delete(_db.foodItems).go();
      await _db.batch((b) => b.insertAll(_db.foodItems, rows));
      await _markFetched(foodsSyncKey);
    });
  }

  FoodItemsCompanion _foodRow(Map<String, dynamic> f) {
    final per = (f['per_100g'] as Map).cast<String, dynamic>();
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    final serving = n(f['default_serving_g']);
    return FoodItemsCompanion.insert(
      id: Value((f['id'] as num).toInt()),
      name: '${f['name']}',
      nameSwahili: Value(f['name_swahili'] as String?),
      category: '${f['category'] ?? 'snacks'}',
      caloriesPer100g: n(per['calories']),
      proteinPer100g: n(per['protein']),
      carbsPer100g: n(per['carbs']),
      fatPer100g: n(per['fat']),
      defaultServingG: Value(serving > 0 ? serving : 100),
      servingDescription: Value(f['serving_description'] as String?),
    );
  }

  // ── Days ───────────────────────────────────────────────────────────

  Stream<List<DiaryEntry>> watchDay(DateTime day) => (_db.select(_db.diaryEntries)
        ..where((e) => e.loggedDate.equals(_dateOnly(day)))
        ..orderBy([(e) => OrderingTerm.asc(e.id)]))
      .watch();

  Stream<DateTime?> watchDayFetchedAt(DateTime day) =>
      (_db.select(_db.syncMeta)..where((m) => m.key.equals(daySyncKey(day))))
          .watchSingleOrNull()
          .map((m) => m?.fetchedAt);

  /// Fetches [from]..[to] (both days included). Throws [AppFailure].
  Future<void> refreshDays(DateTime from, DateTime to) async {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    final json = await guardRequest(() => _api.days(dayKey(start), dayKey(end)));
    final logs = [for (final raw in (json['logs'] as List? ?? const [])) (raw as Map).cast<String, dynamic>()];

    await _db.transaction(() async {
      // Server wins for entries it has; unsent local changes stay.
      final ids = logs.map((l) => '${l['client_id']}').toSet();
      await (_db.delete(_db.diaryEntries)
            ..where((e) =>
                e.loggedDate.isBetweenValues(start, end) &
                e.syncState.equals(SyncState.synced) &
                e.clientId.isNotIn(ids)))
          .go();
      for (final l in logs) {
        final local = await _byClientId('${l['client_id']}');
        if (local != null && local.syncState != SyncState.synced) continue;
        await _db.into(_db.diaryEntries).insert(
              _entryFromJson(l),
              onConflict: DoUpdate((_) => _entryFromJson(l), target: [_db.diaryEntries.clientId]),
            );
      }
      for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
        await _markFetched(daySyncKey(d));
      }
    });
    if (json.containsKey('goal')) await _updateCachedGoal(json['goal'] as Map<String, dynamic>?);
  }

  DiaryEntriesCompanion _entryFromJson(Map<String, dynamic> l) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return DiaryEntriesCompanion.insert(
      clientId: '${l['client_id']}',
      serverId: Value((l['id'] as num?)?.toInt()),
      foodId: (l['food_id'] as num).toInt(),
      foodName: '${l['food_name'] ?? 'Food'}',
      quantityG: n(l['quantity_g']),
      mealType: '${l['meal_type']}',
      loggedDate: DateTime.parse('${l['logged_date']}'),
      calories: n(l['calories']),
      protein: n(l['protein']),
      carbs: n(l['carbs']),
      fat: n(l['fat']),
      syncState: const Value(SyncState.synced),
    );
  }

  // ── Entries (local first, then queued) ─────────────────────────────

  Future<void> add(FoodItem food, {required double grams, required String mealType, required DateTime day}) async {
    final m = Macros.of(food, grams);
    final id = await _db.into(_db.diaryEntries).insert(DiaryEntriesCompanion.insert(
          clientId: _uuid.v4(),
          foodId: food.id,
          foodName: food.name,
          quantityG: grams,
          mealType: mealType,
          loggedDate: _dateOnly(day),
          calories: m.calories,
          protein: m.protein,
          carbs: m.carbs,
          fat: m.fat,
          syncState: const Value(SyncState.pending),
        ));
    await _queuePut(id);
  }

  /// Changes amount or meal. The food's macros come from the catalogue
  /// (or, if it is no longer there, scale the entry's own).
  Future<void> update(DiaryEntry entry, {required double grams, required String mealType}) async {
    final food = await (_db.select(_db.foodItems)..where((f) => f.id.equals(entry.foodId))).getSingleOrNull();
    final scale = entry.quantityG == 0 ? 0.0 : grams / entry.quantityG;
    double r(double v) => (v * 10).round() / 10;
    final m = food != null
        ? Macros.of(food, grams)
        : Macros(
            calories: r(entry.calories * scale),
            protein: r(entry.protein * scale),
            carbs: r(entry.carbs * scale),
            fat: r(entry.fat * scale),
          );
    await (_db.update(_db.diaryEntries)..where((e) => e.id.equals(entry.id))).write(DiaryEntriesCompanion(
          quantityG: Value(grams),
          mealType: Value(mealType),
          calories: Value(m.calories),
          protein: Value(m.protein),
          carbs: Value(m.carbs),
          fat: Value(m.fat),
          syncState: const Value(SyncState.pending),
          syncError: const Value(null),
        ));
    await _queuePut(entry.id);
  }

  Future<void> delete(DiaryEntry entry) async {
    await _outbox.withdraw(DiaryOutboxKind.put, entry.id);
    await (_db.delete(_db.diaryEntries)..where((e) => e.id.equals(entry.id))).go();
    await _outbox.enqueue(
      kind: DiaryOutboxKind.delete,
      targetId: entry.id,
      method: 'DELETE',
      path: NutritionApi.entryPath(entry.clientId),
    );
    unawaited(_outbox.drain());
  }

  Future<void> retry(DiaryEntry entry) async {
    await _outbox.dismissFailed(DiaryOutboxKind.put, entry.id);
    await (_db.update(_db.diaryEntries)..where((e) => e.id.equals(entry.id))).write(
          const DiaryEntriesCompanion(syncState: Value(SyncState.pending), syncError: Value(null)),
        );
    await _queuePut(entry.id);
  }

  Future<void> _queuePut(int localId) async {
    final e = await (_db.select(_db.diaryEntries)..where((x) => x.id.equals(localId))).getSingle();
    await _outbox.withdraw(DiaryOutboxKind.put, localId);
    await _outbox.enqueue(
      kind: DiaryOutboxKind.put,
      targetId: localId,
      method: 'PUT',
      path: NutritionApi.entryPath(e.clientId),
      body: {
        'food_id': e.foodId,
        'quantity_g': e.quantityG,
        'meal_type': e.mealType,
        'logged_date': dayKey(e.loggedDate),
      },
    );
    unawaited(_outbox.drain());
  }

  // ── Goal (online) ──────────────────────────────────────────────────

  Stream<Cached<GoalSettings>?> watchGoal() =>
      _cache.watch(goalKey).map((c) => c?.map(GoalSettings.fromJson));

  /// Throws [AppFailure].
  Future<void> refreshGoal() async {
    final json = await guardRequest(_api.goal);
    await _cache.put(goalKey, json, _clock());
  }

  /// Throws [AppFailure].
  Future<void> setGoal(NutritionGoalInfo goal) async {
    final json = await guardRequest(() => _api.setGoal(goal.toJson()));
    await _updateCachedGoal(json['goal'] as Map<String, dynamic>?);
  }

  Future<void> _updateCachedGoal(Map<String, dynamic>? goal) async {
    final cached = await _cache.watch(goalKey).first;
    await _cache.put(goalKey, {...?cached?.data, 'goal': goal}, _clock());
  }

  // ── Outbox results ─────────────────────────────────────────────────

  Future<void> _onPutSent(OutboxEntry entry, Map<String, dynamic> json) async {
    final l = (json['log'] as Map?)?.cast<String, dynamic>();
    if (l == null) return;
    final newer = await _hasQueued(entry);
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    await (_db.update(_db.diaryEntries)..where((e) => e.id.equals(entry.targetId))).write(DiaryEntriesCompanion(
          serverId: Value((l['id'] as num?)?.toInt()),
          // The server's numbers are the record, unless a newer change waits.
          calories: newer ? const Value.absent() : Value(n(l['calories'])),
          protein: newer ? const Value.absent() : Value(n(l['protein'])),
          carbs: newer ? const Value.absent() : Value(n(l['carbs'])),
          fat: newer ? const Value.absent() : Value(n(l['fat'])),
          syncState: Value(newer ? SyncState.pending : SyncState.synced),
          syncError: const Value(null),
        ));
  }

  Future<void> _onPutFailed(OutboxEntry entry, String message) async {
    if (await _hasQueued(entry)) return;
    await (_db.update(_db.diaryEntries)..where((e) => e.id.equals(entry.targetId))).write(
          DiaryEntriesCompanion(syncState: const Value(SyncState.failed), syncError: Value(message)),
        );
  }

  Future<bool> _hasQueued(OutboxEntry entry) async {
    final other = await (_db.select(_db.outbox)
          ..where((o) =>
              o.kind.equals(entry.kind) &
              o.targetId.equals(entry.targetId) &
              o.id.isNotValue(entry.id) &
              o.status.isIn([OutboxStatus.pending, OutboxStatus.sending]))
          ..limit(1))
        .getSingleOrNull();
    return other != null;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<DiaryEntry?> _byClientId(String clientId) =>
      (_db.select(_db.diaryEntries)..where((e) => e.clientId.equals(clientId))).getSingleOrNull();

  Future<void> _markFetched(String key) => _db.into(_db.syncMeta).insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: key, fetchedAt: _clock()),
      );
}

class _DiaryOutboxHandler implements OutboxHandler {
  _DiaryOutboxHandler(this._repo);

  final NutritionRepository _repo;

  @override
  Future<void> onSent(OutboxEntry entry, Map<String, dynamic> response) async {
    if (entry.kind == DiaryOutboxKind.put) await _repo._onPutSent(entry, response);
  }

  @override
  Future<void> onFailed(OutboxEntry entry, String message) async {
    if (entry.kind == DiaryOutboxKind.put) await _repo._onPutFailed(entry, message);
  }
}
