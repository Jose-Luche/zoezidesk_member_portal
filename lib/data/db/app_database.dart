import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Read-only API snapshots shown offline (dashboard, membership card).
/// [payload] is AES-GCM encrypted JSON; see FieldCipher.
class CachedDocuments extends Table {
  TextColumn get key => text()();
  BlobColumn get payload => blob()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Cached class timetable. Server columns are replaced on every refresh;
/// [localState] and [localError] belong to the app and survive refreshes.
class ClassSessions extends Table {
  IntColumn get id => integer()();
  TextColumn get className => text()();
  TextColumn get color => text().nullable()();
  TextColumn get instructor => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  IntColumn get capacity => integer()();
  IntColumn get spotsLeft => integer()();
  BoolColumn get isFull => boolean()();
  BoolColumn get booked => boolean()();

  /// none, book_pending, cancel_pending, book_failed, cancel_failed
  TextColumn get localState => text().withDefault(const Constant('none'))();
  TextColumn get localError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Writes waiting to reach the server. Each carries an idempotency key so a
/// retry is never applied twice.
@DataClassName('OutboxEntry')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().unique()();

  /// What the write is for, e.g. class_book; routes the result back.
  TextColumn get kind => text()();
  IntColumn get targetId => integer()();
  TextColumn get method => text()();
  TextColumn get path => text()();
  TextColumn get body => text().nullable()();

  /// pending, sending, sent, failed
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// The member's check-ins (recorded by the front desk), newest first.
class Attendances extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get checkedInAt => dateTime()();

  /// qr or manual
  TextColumn get method => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Payment history, newest first. Amount, receipt, plan and method are
/// AES-GCM encrypted in [payload]; status and dates stay clear for ordering.
class Payments extends Table {
  IntColumn get id => integer()();
  TextColumn get status => text()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  BlobColumn get payload => blob()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The gym's exercise library, for picking exercises offline. [lastSets]
/// is JSON: what the member did the last time, for prefilling sets.
@DataClassName('LibraryExercise')
class LibraryExercises extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get category => text().nullable()();

  /// JSON list of strings.
  TextColumn get equipment => text().withDefault(const Constant('[]'))();
  TextColumn get difficulty => text().nullable()();
  TextColumn get instructions => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get lastDate => dateTime().nullable()();
  TextColumn get lastSets => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Workouts: the member's history from the server, plus sessions logged in
/// the app (possibly offline). Addressed by [clientId], which the server
/// stores too; [serverId] is known once the server has it.
@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get dayType => text()();
  TextColumn get muscleGroup => text().nullable()();
  DateTimeColumn get sessionDate => dateTime()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();

  /// in_progress, completed or abandoned
  TextColumn get status => text()();
  TextColumn get rating => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get exerciseCount => integer().withDefault(const Constant(0))();
  IntColumn get totalSets => integer().withDefault(const Constant(0))();
  RealColumn get totalVolume => real().withDefault(const Constant(0))();

  /// Exercises and sets are stored locally (only summaries come with the
  /// history list).
  BoolColumn get detailLoaded => boolean().withDefault(const Constant(false))();

  /// synced, pending (changes not yet sent) or failed
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  TextColumn get syncError => text().nullable()();

  /// The server's updated_at, to know when a cached detail is stale.
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
}

@DataClassName('WorkoutExerciseRow')
class WorkoutExercises extends Table {
  TextColumn get clientId => text()();
  TextColumn get sessionClientId => text()();
  IntColumn get exerciseId => integer()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text().nullable()();
  IntColumn get position => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

@DataClassName('WorkoutSetRow')
class WorkoutSets extends Table {
  TextColumn get clientId => text()();
  TextColumn get exerciseClientId => text()();
  IntColumn get setNumber => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  RealColumn get distanceKm => real().nullable()();
  IntColumn get rpe => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Comma-separated PR metric types the server found for this set.
  TextColumn get prTypes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

/// When each cached list was last refreshed from the server.
class SyncMeta extends Table {
  TextColumn get key => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [
  CachedDocuments, ClassSessions, Outbox, SyncMeta, Attendances, Payments,
  LibraryExercises, WorkoutSessions, WorkoutExercises, WorkoutSets,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'zoezi_member'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 adds tables only; existing cached data is untouched.
          if (from < 2) {
            await m.createTable(classSessions);
            await m.createTable(outbox);
            await m.createTable(syncMeta);
          }
          // v3 adds the check-in history table.
          if (from < 3) await m.createTable(attendances);
          // v4 adds the payment history table.
          if (from < 4) await m.createTable(payments);
          // v5 adds the exercise library and workout logging tables.
          if (from < 5) {
            await m.createTable(libraryExercises);
            await m.createTable(workoutSessions);
            await m.createTable(workoutExercises);
            await m.createTable(workoutSets);
          }
        },
      );

  /// Deletes every row in every table. Used on logout.
  Future<void> wipe() => transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
