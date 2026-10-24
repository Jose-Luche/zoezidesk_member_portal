import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/sync/outbox_service.dart';
import '../api/workouts_api.dart';
import '../db/app_database.dart';
import '../db/encrypted_cache.dart';
import 'workout_progress.dart';

export 'workout_progress.dart';

abstract final class WorkoutOutboxKind {
  static const sync = 'workout_sync';
  static const discard = 'workout_discard';
}

abstract final class SyncState {
  static const synced = 'synced';
  static const pending = 'pending';
  static const failed = 'failed';
}

/// What one set records. Strength sets use weight and reps; cardio uses
/// duration and distance.
class SetValues {
  const SetValues({this.weight, this.reps, this.durationMinutes, this.distanceKm, this.rpe});

  factory SetValues.fromRow(WorkoutSetRow s) => SetValues(
        weight: s.weight,
        reps: s.reps,
        durationMinutes: s.durationMinutes,
        distanceKm: s.distanceKm,
        rpe: s.rpe,
      );

  factory SetValues.fromJson(Map<String, dynamic> j) => SetValues(
        weight: (j['weight'] as num?)?.toDouble(),
        reps: (j['reps'] as num?)?.toInt(),
        durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        rpe: (j['rpe'] as num?)?.toInt(),
      );

  final double? weight;
  final int? reps;
  final int? durationMinutes;
  final double? distanceKm;
  final int? rpe;

  bool get isEmpty => weight == null && reps == null && durationMinutes == null && distanceKm == null;

  double get volume => (weight ?? 0) * (reps ?? 0);
}

/// The member's sets for an exercise the last time they did it.
class LastTime {
  const LastTime(this.date, this.sets);

  final DateTime date;
  final List<SetValues> sets;

  static LastTime? of(LibraryExercise e) {
    if (e.lastDate == null || e.lastSets == null) return null;
    final sets = [
      for (final s in jsonDecode(e.lastSets!) as List) SetValues.fromJson((s as Map).cast<String, dynamic>()),
    ];
    return sets.isEmpty ? null : LastTime(e.lastDate!, sets);
  }
}

class ExerciseWithSets {
  const ExerciseWithSets(this.exercise, this.sets);

  final WorkoutExerciseRow exercise;
  final List<WorkoutSetRow> sets;
}

class SessionDetail {
  const SessionDetail(this.session, this.exercises);

  final WorkoutSessionRow session;
  final List<ExerciseWithSets> exercises;

  bool get isActive => session.status == 'in_progress';
  int get prCount => exercises.expand((e) => e.sets).where((s) => s.prTypes.isNotEmpty).length;
}

/// A record the server found when a set reached it.
class NewPr {
  const NewPr({
    required this.sessionClientId,
    required this.setClientId,
    required this.exerciseName,
    required this.metricType,
    required this.value,
    this.repCount,
  });

  final String sessionClientId;
  final String setClientId;
  final String exerciseName;

  /// max_weight_1rm or max_weight_at_reps
  final String metricType;
  final double value;
  final int? repCount;
}

class HistoryPage {
  const HistoryPage({required this.page, required this.lastPage});

  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

/// Records per exercise, from GET /workouts/prs.
class PersonalRecords {
  const PersonalRecords({required this.total, required this.thisMonth, required this.exercises});

  factory PersonalRecords.fromJson(Map<String, dynamic> j) => PersonalRecords(
        total: (j['total'] as num?)?.toInt() ?? 0,
        thisMonth: (j['this_month'] as num?)?.toInt() ?? 0,
        exercises: [
          for (final e in (j['exercises'] as List? ?? const []))
            ExerciseRecords.fromJson((e as Map).cast<String, dynamic>()),
        ],
      );

  final int total;
  final int thisMonth;
  final List<ExerciseRecords> exercises;
}

class ExerciseRecords {
  const ExerciseRecords({
    required this.exerciseId,
    required this.name,
    required this.records,
    this.best1rm,
    this.lastAt,
  });

  factory ExerciseRecords.fromJson(Map<String, dynamic> j) => ExerciseRecords(
        exerciseId: (j['exercise_id'] as num).toInt(),
        name: '${j['name'] ?? 'Exercise'}',
        best1rm: (j['best_1rm'] as num?)?.toDouble(),
        lastAt: DateTime.tryParse('${j['last_at']}'),
        records: [
          for (final r in (j['records'] as List? ?? const []))
            (
              metricType: '${(r as Map)['metric_type']}',
              value: (r['value'] as num).toDouble(),
              repCount: (r['rep_count'] as num?)?.toInt(),
              loggedAt: DateTime.parse('${r['logged_at']}'),
            ),
        ],
      );

  final int exerciseId;
  final String name;
  final double? best1rm;
  final DateTime? lastAt;
  final List<({String metricType, double value, int? repCount, DateTime loggedAt})> records;
}

/// Workouts, offline first.
///
/// - Sessions logged in the app are written to the local database, then
///   sent as one whole-session document through the outbox. Each change
///   replaces the queued document, so only the latest state is sent; the
///   server applies it idempotently, by the app's ids.
/// - History, the exercise library and records are cached for reading
///   offline. For history the server wins, except for sessions with local
///   changes not yet sent.
class WorkoutsRepository {
  WorkoutsRepository({
    required this._db,
    required this._cache,
    required this._api,
    required this._outbox,
    required this._clock,
    this._uuid = const Uuid(),
  });

  static const librarySyncKey = 'exercise_library';
  static const historySyncKey = 'workout_history';
  static const recordsKey = 'workout_prs';
  static const progressKey = 'workout_progress';
  static String muscleKey(String muscle) => 'muscle_progress:$muscle';

  final AppDatabase _db;
  final EncryptedCache _cache;
  final WorkoutsApi _api;
  final OutboxService _outbox;
  final DateTime Function() _clock;
  final Uuid _uuid;
  final _prs = StreamController<NewPr>.broadcast();

  late final OutboxHandler outboxHandler = _WorkoutOutboxHandler(this);

  /// Records found by the server as queued sets arrive.
  Stream<NewPr> get newPrs => _prs.stream;

  void dispose() => _prs.close();

  // ── Library ────────────────────────────────────────────────────────

  Stream<List<LibraryExercise>> watchLibrary() =>
      (_db.select(_db.libraryExercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).watch();

  Stream<DateTime?> watchLibraryFetchedAt() => _watchFetchedAt(librarySyncKey);

  /// Throws [AppFailure].
  Future<void> refreshLibrary() async {
    final json = await guardRequest(_api.exercises);
    final rows = [
      for (final raw in (json['exercises'] as List? ?? const []))
        _libraryRow((raw as Map).cast<String, dynamic>()),
    ];
    await _db.transaction(() async {
      await _db.delete(_db.libraryExercises).go();
      await _db.batch((b) => b.insertAll(_db.libraryExercises, rows));
      await _markFetched(librarySyncKey);
    });
  }

  LibraryExercisesCompanion _libraryRow(Map<String, dynamic> e) {
    final last = (e['last'] as Map?)?.cast<String, dynamic>();
    return LibraryExercisesCompanion.insert(
      id: Value((e['id'] as num).toInt()),
      name: '${e['name']}',
      muscleGroup: '${e['muscle_group'] ?? 'full_body'}',
      category: Value(e['category'] as String?),
      equipment: Value(jsonEncode(e['equipment'] is List ? e['equipment'] : const [])),
      difficulty: Value(e['difficulty'] as String?),
      instructions: Value(e['instructions'] as String?),
      imageUrl: Value(e['demo_image_url'] as String?),
      lastDate: Value(DateTime.tryParse('${last?['date']}')),
      lastSets: Value(last == null ? null : jsonEncode(last['sets'])),
    );
  }

  // ── History ────────────────────────────────────────────────────────

  Stream<List<WorkoutSessionRow>> watchHistory() => (_db.select(_db.workoutSessions)
        ..orderBy([
          (s) => OrderingTerm.desc(s.sessionDate),
          (s) => OrderingTerm.desc(s.startedAt),
          (s) => OrderingTerm.desc(s.id),
        ]))
      .watch();

  Stream<WorkoutSessionRow?> watchActive() => (_db.select(_db.workoutSessions)
        ..where((s) => s.status.equals('in_progress'))
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1))
      .watchSingleOrNull();

  Future<WorkoutSessionRow?> active() => watchActive().first;

  Stream<DateTime?> watchHistoryFetchedAt() => _watchFetchedAt(historySyncKey);

  /// First page of history. Throws [AppFailure].
  Future<HistoryPage> refreshHistory() async {
    final (rows, page) = await _fetchHistory(1);
    await _db.transaction(() async {
      await _upsertSummaries(rows);
      // Sessions deleted on the server (e.g. on the web) disappear here,
      // unless they hold changes not yet sent. Only rows the first page
      // should have contained are checked.
      final ids = rows.map((r) => r.clientId.value).toSet();
      final oldest = rows.isEmpty ? null : rows.last.sessionDate.value;
      final stale = await (_db.select(_db.workoutSessions)
            ..where((s) =>
                s.syncState.equals(SyncState.synced) &
                s.clientId.isNotIn(ids) &
                (page.hasMore && oldest != null
                    ? s.sessionDate.isBiggerOrEqualValue(oldest)
                    : const Constant(true))))
          .get();
      for (final s in stale) {
        await _deleteLocal(s.clientId);
      }
      await _markFetched(historySyncKey);
    });
    return page;
  }

  /// Throws [AppFailure].
  Future<HistoryPage> loadHistoryPage(int n) async {
    final (rows, page) = await _fetchHistory(n);
    await _db.transaction(() => _upsertSummaries(rows));
    return page;
  }

  Future<(List<WorkoutSessionsCompanion>, HistoryPage)> _fetchHistory(int n) async {
    final json = await guardRequest(() => _api.page(n));
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    int i(Object? v, int fallback) => v is num ? v.toInt() : fallback;
    return (
      [for (final raw in (json['data'] as List? ?? const [])) _summaryRow((raw as Map).cast<String, dynamic>())],
      HistoryPage(page: i(meta['current_page'], n), lastPage: i(meta['last_page'], n)),
    );
  }

  WorkoutSessionsCompanion _summaryRow(Map<String, dynamic> s) => WorkoutSessionsCompanion(
        clientId: Value('${s['client_id']}'),
        serverId: Value((s['id'] as num).toInt()),
        dayType: Value('${s['day_type'] ?? 'Workout'}'),
        muscleGroup: Value(s['muscle_group'] as String?),
        sessionDate: Value(DateTime.parse('${s['session_date']}')),
        startedAt: Value(
          DateTime.tryParse('${s['started_at']}')?.toLocal() ?? DateTime.parse('${s['session_date']}'),
        ),
        endedAt: Value(DateTime.tryParse('${s['ended_at']}')?.toLocal()),
        durationMinutes: Value((s['duration_minutes'] as num?)?.toInt()),
        status: Value('${s['status'] ?? 'completed'}'),
        rating: Value(s['rating'] as String?),
        exerciseCount: Value((s['exercise_count'] as num?)?.toInt() ?? 0),
        totalSets: Value((s['total_sets'] as num?)?.toInt() ?? 0),
        totalVolume: Value((s['total_volume'] as num?)?.toDouble() ?? 0),
        serverUpdatedAt: Value(DateTime.tryParse('${s['updated_at']}')),
        syncState: const Value(SyncState.synced),
      );

  Future<void> _upsertSummaries(List<WorkoutSessionsCompanion> rows) async {
    for (final row in rows) {
      final local = await _byClientId(row.clientId.value);
      if (local == null) {
        await _db.into(_db.workoutSessions).insert(row);
      } else if (local.syncState == SyncState.synced) {
        final changed = local.serverUpdatedAt != row.serverUpdatedAt.value;
        await (_db.update(_db.workoutSessions)..where((s) => s.id.equals(local.id)))
            .write(row.copyWith(detailLoaded: changed ? const Value(false) : const Value.absent()));
      }
      // Local changes not yet sent win until they reach the server.
    }
  }

  // ── One session ────────────────────────────────────────────────────

  Stream<SessionDetail?> watchSession(String clientId) async* {
    yield await _loadDetail(clientId);
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([
      _db.workoutSessions,
      _db.workoutExercises,
      _db.workoutSets,
    ]))) {
      yield await _loadDetail(clientId);
    }
  }

  Future<SessionDetail?> _loadDetail(String clientId) async {
    final session = await _byClientId(clientId);
    if (session == null) return null;
    final exercises = await (_db.select(_db.workoutExercises)
          ..where((e) => e.sessionClientId.equals(clientId))
          ..orderBy([(e) => OrderingTerm.asc(e.position)]))
        .get();
    final sets = exercises.isEmpty
        ? const <WorkoutSetRow>[]
        : await (_db.select(_db.workoutSets)
              ..where((s) => s.exerciseClientId.isIn(exercises.map((e) => e.clientId)))
              ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
            .get();
    return SessionDetail(session, [
      for (final e in exercises) ExerciseWithSets(e, sets.where((s) => s.exerciseClientId == e.clientId).toList()),
    ]);
  }

  /// Fetches exercises and sets for a session from history. Sessions with
  /// unsent changes are left alone. Throws [AppFailure].
  Future<void> loadDetail(String clientId) async {
    final local = await _byClientId(clientId);
    if (local == null || local.serverId == null || local.syncState != SyncState.synced) return;
    final json = await guardRequest(() => _api.show(local.serverId!));
    await _storeDocument(json);
  }

  /// A session started on the server (by the workout builder): store it
  /// and return its id for logging. Throws [AppFailure].
  Future<String> adoptServerSession(int serverId) async {
    final json = await guardRequest(() => _api.show(serverId));
    return _storeDocument(json);
  }

  Future<String> _storeDocument(Map<String, dynamic> json) async {
    final s = (json['session'] as Map).cast<String, dynamic>();
    final clientId = '${s['client_id']}';
    await _db.transaction(() async {
      await _upsertSummaries([_summaryRow(s)]);
      final local = await _byClientId(clientId);
      if (local == null || local.syncState != SyncState.synced) return;
      await _deleteChildren(clientId);
      for (final raw in (json['exercises'] as List? ?? const [])) {
        final e = (raw as Map).cast<String, dynamic>();
        await _db.into(_db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
              clientId: '${e['client_id']}',
              sessionClientId: clientId,
              exerciseId: (e['exercise_id'] as num).toInt(),
              name: '${e['name'] ?? 'Exercise'}',
              muscleGroup: Value(e['muscle_group'] as String?),
              position: (e['position'] as num).toInt(),
              notes: Value(e['notes'] as String?),
            ));
        for (final rawSet in (e['sets'] as List? ?? const [])) {
          final set = (rawSet as Map).cast<String, dynamic>();
          final v = SetValues.fromJson(set);
          await _db.into(_db.workoutSets).insert(WorkoutSetsCompanion.insert(
                clientId: '${set['client_id']}',
                exerciseClientId: '${e['client_id']}',
                setNumber: (set['set_number'] as num).toInt(),
                weight: Value(v.weight),
                reps: Value(v.reps),
                durationMinutes: Value(v.durationMinutes),
                distanceKm: Value(v.distanceKm),
                rpe: Value(v.rpe),
                completedAt: Value(DateTime.tryParse('${set['completed_at']}')?.toLocal()),
                prTypes: Value(((set['pr_types'] as List?) ?? const []).join(',')),
              ));
        }
      }
      await (_db.update(_db.workoutSessions)..where((r) => r.id.equals(local.id)))
          .write(const WorkoutSessionsCompanion(detailLoaded: Value(true)));
    });
    return clientId;
  }

  // ── Logging (local first, then queued) ─────────────────────────────

  /// Starts a session now. [copyFrom] repeats another session's exercises
  /// (without its sets; the last time's numbers prefill new sets).
  Future<String> start({required String dayType, String? muscleGroup, String? copyFrom}) async {
    final now = _clock();
    final clientId = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
            clientId: clientId,
            dayType: dayType,
            muscleGroup: Value(muscleGroup),
            sessionDate: DateTime(now.year, now.month, now.day),
            startedAt: now,
            status: 'in_progress',
            detailLoaded: const Value(true),
            syncState: const Value(SyncState.pending),
          ));
      if (copyFrom != null) {
        final source = await _loadDetail(copyFrom);
        for (final e in source?.exercises ?? const <ExerciseWithSets>[]) {
          await _db.into(_db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
                clientId: _uuid.v4(),
                sessionClientId: clientId,
                exerciseId: e.exercise.exerciseId,
                name: e.exercise.name,
                muscleGroup: Value(e.exercise.muscleGroup),
                position: e.exercise.position,
              ));
        }
      }
    });
    await _changed(clientId);
    return clientId;
  }

  Future<void> addExercise(String sessionClientId, LibraryExercise exercise) async {
    final last = await (_db.select(_db.workoutExercises)
          ..where((e) => e.sessionClientId.equals(sessionClientId))
          ..orderBy([(e) => OrderingTerm.desc(e.position)])
          ..limit(1))
        .getSingleOrNull();
    await _db.into(_db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
          clientId: _uuid.v4(),
          sessionClientId: sessionClientId,
          exerciseId: exercise.id,
          name: exercise.name,
          muscleGroup: Value(exercise.muscleGroup),
          position: (last?.position ?? 0) + 1,
        ));
    await _changed(sessionClientId);
  }

  Future<void> removeExercise(String exerciseClientId) async {
    final e = await _exercise(exerciseClientId);
    if (e == null) return;
    await _db.transaction(() async {
      await (_db.delete(_db.workoutSets)..where((s) => s.exerciseClientId.equals(exerciseClientId))).go();
      await (_db.delete(_db.workoutExercises)..where((x) => x.clientId.equals(exerciseClientId))).go();
    });
    await _changed(e.sessionClientId);
  }

  Future<void> addSet(String exerciseClientId, SetValues v) async {
    final e = await _exercise(exerciseClientId);
    if (e == null) return;
    final count = await _setCount(exerciseClientId);
    await _db.into(_db.workoutSets).insert(WorkoutSetsCompanion.insert(
          clientId: _uuid.v4(),
          exerciseClientId: exerciseClientId,
          setNumber: count + 1,
          weight: Value(v.weight),
          reps: Value(v.reps),
          durationMinutes: Value(v.durationMinutes),
          distanceKm: Value(v.distanceKm),
          rpe: Value(v.rpe),
          completedAt: Value(_clock()),
        ));
    await _changed(e.sessionClientId);
  }

  Future<void> updateSet(String setClientId, SetValues v) async {
    final set = await (_db.select(_db.workoutSets)..where((s) => s.clientId.equals(setClientId))).getSingleOrNull();
    if (set == null) return;
    await (_db.update(_db.workoutSets)..where((s) => s.clientId.equals(setClientId))).write(WorkoutSetsCompanion(
          weight: Value(v.weight),
          reps: Value(v.reps),
          durationMinutes: Value(v.durationMinutes),
          distanceKm: Value(v.distanceKm),
          rpe: Value(v.rpe),
        ));
    final e = await _exercise(set.exerciseClientId);
    if (e != null) await _changed(e.sessionClientId);
  }

  Future<void> deleteSet(String setClientId) async {
    final set = await (_db.select(_db.workoutSets)..where((s) => s.clientId.equals(setClientId))).getSingleOrNull();
    if (set == null) return;
    await _db.transaction(() async {
      await (_db.delete(_db.workoutSets)..where((s) => s.clientId.equals(setClientId))).go();
      // Keep set numbers 1, 2, 3 … as on the web.
      final rest = await (_db.select(_db.workoutSets)
            ..where((s) => s.exerciseClientId.equals(set.exerciseClientId))
            ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
          .get();
      for (var i = 0; i < rest.length; i++) {
        await (_db.update(_db.workoutSets)..where((s) => s.clientId.equals(rest[i].clientId)))
            .write(WorkoutSetsCompanion(setNumber: Value(i + 1)));
      }
    });
    final e = await _exercise(set.exerciseClientId);
    if (e != null) await _changed(e.sessionClientId);
  }

  Future<void> finish(String sessionClientId, {String? rating, String? notes}) async {
    final s = await _byClientId(sessionClientId);
    if (s == null) return;
    final now = _clock();
    await (_db.update(_db.workoutSessions)..where((r) => r.id.equals(s.id))).write(WorkoutSessionsCompanion(
          status: const Value('completed'),
          endedAt: Value(now),
          durationMinutes: Value(now.difference(s.startedAt).inMinutes),
          rating: Value(rating),
          notes: Value(notes == null || notes.trim().isEmpty ? s.notes : notes.trim()),
        ));
    await _changed(sessionClientId);
  }

  /// Throws the session away, here and on the server.
  Future<void> discard(String sessionClientId) async {
    final s = await _byClientId(sessionClientId);
    if (s == null) return;
    await _outbox.withdraw(WorkoutOutboxKind.sync, s.id);
    await _db.transaction(() => _deleteLocal(sessionClientId));
    await _outbox.enqueue(
      kind: WorkoutOutboxKind.discard,
      targetId: s.id,
      method: 'DELETE',
      path: WorkoutsApi.syncPath(sessionClientId),
    );
    unawaited(_outbox.drain());
  }

  /// Sends a session again after the server refused it.
  Future<void> retrySync(String sessionClientId) async {
    final s = await _byClientId(sessionClientId);
    if (s == null) return;
    await _outbox.dismissFailed(WorkoutOutboxKind.sync, s.id);
    await _changed(sessionClientId);
  }

  /// Recount, mark unsent and queue the whole session (replacing any
  /// queued copy that has not started sending).
  Future<void> _changed(String sessionClientId) async {
    final detail = await _loadDetail(sessionClientId);
    if (detail == null) return;
    final sets = detail.exercises.expand((e) => e.sets).toList();
    await (_db.update(_db.workoutSessions)..where((r) => r.id.equals(detail.session.id))).write(WorkoutSessionsCompanion(
          exerciseCount: Value(detail.exercises.length),
          totalSets: Value(sets.length),
          totalVolume: Value(sets.fold(0.0, (sum, s) => sum + SetValues.fromRow(s).volume)),
          syncState: const Value(SyncState.pending),
          syncError: const Value(null),
        ));
    await _outbox.withdraw(WorkoutOutboxKind.sync, detail.session.id);
    await _outbox.enqueue(
      kind: WorkoutOutboxKind.sync,
      targetId: detail.session.id,
      method: 'PUT',
      path: WorkoutsApi.syncPath(sessionClientId),
      body: _document(detail),
    );
    unawaited(_outbox.drain());
  }

  Map<String, dynamic> _document(SessionDetail d) {
    final s = d.session;
    String? iso(DateTime? t) => t?.toUtc().toIso8601String();
    return {
      'day_type': s.dayType,
      'muscle_group': s.muscleGroup,
      'session_date':
          '${s.sessionDate.year.toString().padLeft(4, '0')}-${s.sessionDate.month.toString().padLeft(2, '0')}-${s.sessionDate.day.toString().padLeft(2, '0')}',
      'started_at': iso(s.startedAt),
      'ended_at': iso(s.endedAt),
      'status': s.status == 'completed' ? 'completed' : 'in_progress',
      'rating': s.rating,
      'notes': s.notes,
      'exercises': [
        for (final e in d.exercises)
          {
            'client_id': e.exercise.clientId,
            'exercise_id': e.exercise.exerciseId,
            'position': e.exercise.position,
            'notes': e.exercise.notes,
            'sets': [
              for (final set in e.sets)
                {
                  'client_id': set.clientId,
                  'set_number': set.setNumber,
                  'weight': set.weight,
                  'reps': set.reps,
                  'duration_minutes': set.durationMinutes,
                  'distance_km': set.distanceKm,
                  'rpe': set.rpe,
                  'completed_at': iso(set.completedAt),
                },
            ],
          },
      ],
    };
  }

  // ── Records ────────────────────────────────────────────────────────

  Stream<Cached<PersonalRecords>?> watchRecords() =>
      _cache.watch(recordsKey).map((c) => c?.map(PersonalRecords.fromJson));

  /// Throws [AppFailure].
  Future<void> refreshRecords() async {
    final json = await guardRequest(_api.prs);
    await _cache.put(recordsKey, json, _clock());
  }

  // ── Progress (worked out on the server, cached for offline) ────────

  Stream<Cached<ProgressSummary>?> watchProgress() =>
      _cache.watch(progressKey).map((c) => c?.map(ProgressSummary.fromJson));

  /// Throws [AppFailure].
  Future<void> refreshProgress() async {
    final json = await guardRequest(_api.progress);
    await _cache.put(progressKey, json, _clock());
  }

  Stream<Cached<MuscleDetail>?> watchMuscle(String muscle) =>
      _cache.watch(muscleKey(muscle)).map((c) => c?.map(MuscleDetail.fromJson));

  /// Throws [AppFailure].
  Future<void> refreshMuscle(String muscle) async {
    final json = await guardRequest(() => _api.muscleProgress(muscle));
    await _cache.put(muscleKey(muscle), json, _clock());
  }

  // ── Outbox results ─────────────────────────────────────────────────

  Future<void> _onSynced(OutboxEntry entry, Map<String, dynamic> json) async {
    final s = (json['session'] as Map?)?.cast<String, dynamic>();
    final local = await (_db.select(_db.workoutSessions)..where((r) => r.id.equals(entry.targetId))).getSingleOrNull();
    if (s == null || local == null) return;

    final prTypes = <String, String>{
      for (final e in (json['exercises'] as List? ?? const []))
        for (final set in ((e as Map)['sets'] as List? ?? const []))
          '${(set as Map)['client_id']}': ((set['pr_types'] as List?) ?? const []).join(','),
    };
    final newer = await _hasQueued(entry);
    await _db.transaction(() async {
      for (final MapEntry(:key, :value) in prTypes.entries) {
        await (_db.update(_db.workoutSets)..where((r) => r.clientId.equals(key)))
            .write(WorkoutSetsCompanion(prTypes: Value(value)));
      }
      await (_db.update(_db.workoutSessions)..where((r) => r.id.equals(local.id))).write(WorkoutSessionsCompanion(
            serverId: Value((s['id'] as num).toInt()),
            serverUpdatedAt: Value(DateTime.tryParse('${s['updated_at']}')),
            durationMinutes: Value((s['duration_minutes'] as num?)?.toInt() ?? local.durationMinutes),
            // A later change is already queued: still unsent.
            syncState: Value(newer ? SyncState.pending : SyncState.synced),
            syncError: const Value(null),
          ));
    });

    for (final raw in (json['new_prs'] as List? ?? const [])) {
      final pr = (raw as Map).cast<String, dynamic>();
      _prs.add(NewPr(
        sessionClientId: local.clientId,
        setClientId: '${pr['set_client_id']}',
        exerciseName: '${pr['exercise_name'] ?? 'Exercise'}',
        metricType: '${pr['metric_type']}',
        value: (pr['value'] as num).toDouble(),
        repCount: (pr['rep_count'] as num?)?.toInt(),
      ));
    }
  }

  Future<void> _onSyncFailed(OutboxEntry entry, String message) async {
    if (await _hasQueued(entry)) return;
    await (_db.update(_db.workoutSessions)..where((r) => r.id.equals(entry.targetId))).write(WorkoutSessionsCompanion(
          syncState: const Value(SyncState.failed),
          syncError: Value(message),
        ));
  }

  /// Another copy of this session waits to be sent.
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

  Future<WorkoutSessionRow?> _byClientId(String clientId) =>
      (_db.select(_db.workoutSessions)..where((s) => s.clientId.equals(clientId))).getSingleOrNull();

  Future<WorkoutExerciseRow?> _exercise(String clientId) =>
      (_db.select(_db.workoutExercises)..where((e) => e.clientId.equals(clientId))).getSingleOrNull();

  Future<int> _setCount(String exerciseClientId) async =>
      (await (_db.select(_db.workoutSets)..where((s) => s.exerciseClientId.equals(exerciseClientId))).get()).length;

  Future<void> _deleteChildren(String sessionClientId) async {
    final exercises = _db.selectOnly(_db.workoutExercises)
      ..addColumns([_db.workoutExercises.clientId])
      ..where(_db.workoutExercises.sessionClientId.equals(sessionClientId));
    await (_db.delete(_db.workoutSets)..where((s) => s.exerciseClientId.isInQuery(exercises))).go();
    await (_db.delete(_db.workoutExercises)..where((e) => e.sessionClientId.equals(sessionClientId))).go();
  }

  Future<void> _deleteLocal(String sessionClientId) async {
    await _deleteChildren(sessionClientId);
    await (_db.delete(_db.workoutSessions)..where((s) => s.clientId.equals(sessionClientId))).go();
  }

  Future<void> _markFetched(String key) => _db.into(_db.syncMeta).insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: key, fetchedAt: _clock()),
      );

  Stream<DateTime?> _watchFetchedAt(String key) =>
      (_db.select(_db.syncMeta)..where((m) => m.key.equals(key))).watchSingleOrNull().map((m) => m?.fetchedAt);
}

class _WorkoutOutboxHandler implements OutboxHandler {
  _WorkoutOutboxHandler(this._repo);

  final WorkoutsRepository _repo;

  @override
  Future<void> onSent(OutboxEntry entry, Map<String, dynamic> response) async {
    if (entry.kind == WorkoutOutboxKind.sync) await _repo._onSynced(entry, response);
  }

  @override
  Future<void> onFailed(OutboxEntry entry, String message) async {
    if (entry.kind == WorkoutOutboxKind.sync) await _repo._onSyncFailed(entry, message);
  }
}
