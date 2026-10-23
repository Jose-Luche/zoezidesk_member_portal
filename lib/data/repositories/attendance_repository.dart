import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/clock.dart';
import '../api/attendance_api.dart';
import '../db/app_database.dart';
import '../db/encrypted_cache.dart';

/// Server totals: the first page may not hold every check-in of the month.
class AttendanceSummary {
  const AttendanceSummary({required this.thisMonth, this.lastVisit, this.total = 0});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
        thisMonth: (json['this_month'] as num?)?.toInt() ?? 0,
        lastVisit: DateTime.tryParse('${json['last_visit']}'),
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  final int thisMonth;
  final DateTime? lastVisit;
  final int total;
}

/// Result of fetching one page, so the screen knows whether to offer more.
class AttendancePage {
  const AttendancePage({required this.page, required this.lastPage});

  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

/// Check-in history, cached for offline reading. Read-only: check-ins are
/// created by the front desk. A refresh replaces the cache with the first
/// page (server wins); older pages load on demand.
class AttendanceRepository {
  const AttendanceRepository({
    required this._db,
    required this._cache,
    required this._api,
    required this._clock,
  });

  static const syncKey = 'attendance';
  static const summaryKey = 'attendance_summary';

  final AppDatabase _db;
  final EncryptedCache _cache;
  final AttendanceApi _api;
  final DateTime Function() _clock;

  Stream<List<Attendance>> watchAll() => (_db.select(_db.attendances)
        ..orderBy([(a) => OrderingTerm.desc(a.checkedInAt), (a) => OrderingTerm.desc(a.id)]))
      .watch();

  Stream<DateTime?> watchFetchedAt() =>
      (_db.select(_db.syncMeta)..where((m) => m.key.equals(syncKey)))
          .watchSingleOrNull()
          .map((m) => m?.fetchedAt);

  Stream<AttendanceSummary?> watchSummary() =>
      _cache.watch(summaryKey).map((c) => c == null ? null : AttendanceSummary.fromJson(c.data));

  Future<Attendance?> latest() => (_db.select(_db.attendances)
        ..orderBy([(a) => OrderingTerm.desc(a.checkedInAt)])
        ..limit(1))
      .getSingleOrNull();

  /// Throws [AppFailure].
  Future<AttendancePage> refresh() async {
    final (rows, page, summary) = await _fetch(1);
    await _db.transaction(() async {
      await _db.delete(_db.attendances).go();
      await _insert(rows);
      await _db.into(_db.syncMeta).insertOnConflictUpdate(
            SyncMetaCompanion.insert(key: syncKey, fetchedAt: _clock()),
          );
    });
    await _cache.put(summaryKey, summary, _clock());
    return page;
  }

  /// Throws [AppFailure].
  Future<AttendancePage> loadPage(int pageNumber) async {
    final (rows, page, _) = await _fetch(pageNumber);
    await _insert(rows);
    return page;
  }

  Future<(List<AttendancesCompanion>, AttendancePage, Map<String, dynamic>)> _fetch(int page) =>
      guardRequest(() async {
        final json = await _api.page(page);
        final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
        final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
        int n(Object? v, int fallback) => v is num ? v.toInt() : fallback;
        final rows = [
          for (final raw in (json['data'] as List? ?? const []))
            AttendancesCompanion.insert(
              id: Value(n((raw as Map)['id'], 0)),
              checkedInAt: DateTime.parse('${raw['checked_in_at']}'),
              method: '${raw['method'] ?? 'qr'}',
            ),
        ];
        return (
          rows,
          AttendancePage(page: n(meta['current_page'], page), lastPage: n(meta['last_page'], page)),
          {...summary, 'total': meta['total']},
        );
      });

  Future<void> _insert(List<AttendancesCompanion> rows) => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.attendances, rows),
      );
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(
    db: ref.watch(appDatabaseProvider),
    cache: ref.watch(encryptedCacheProvider),
    api: ref.watch(attendanceApiProvider),
    clock: ref.watch(clockProvider),
  ),
);
