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

@DriftDatabase(tables: [CachedDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'zoezi_member'));

  @override
  int get schemaVersion => 1;

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
