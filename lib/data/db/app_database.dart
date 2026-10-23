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

/// When each cached list was last refreshed from the server.
class SyncMeta extends Table {
  TextColumn get key => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [CachedDocuments, ClassSessions, Outbox, SyncMeta, Attendances])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'zoezi_member'));

  @override
  int get schemaVersion => 3;

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
