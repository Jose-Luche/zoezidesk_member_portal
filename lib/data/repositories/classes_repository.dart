import 'package:drift/drift.dart';

import '../../core/errors/app_failure.dart';
import '../../core/sync/outbox_service.dart';
import '../api/classes_api.dart';
import '../db/app_database.dart';
import '../dto/class_dto.dart';

/// Local booking state shown alongside the server's data.
abstract final class LocalBookingState {
  static const none = 'none';
  static const bookPending = 'book_pending';
  static const cancelPending = 'cancel_pending';
  static const bookFailed = 'book_failed';
  static const cancelFailed = 'cancel_failed';
}

abstract final class ClassOutboxKind {
  static const book = 'class_book';
  static const cancel = 'class_cancel';
}

/// Offline-first class timetable. Reads come from the local table; a
/// refresh replaces the server columns for the window and keeps local
/// booking state. Bookings and cancellations are queued in the outbox and
/// shown as pending until the server confirms.
class ClassesRepository {
  const ClassesRepository({
    required this._db,
    required this._api,
    required this._outbox,
    required this._clock,
  });

  static const syncKey = 'classes';
  static const windowDays = 14;

  final AppDatabase _db;
  final ClassesApi _api;
  final OutboxService _outbox;
  final DateTime Function() _clock;

  Stream<List<ClassSession>> watchFrom(DateTime from) => (_db.select(_db.classSessions)
        ..where((c) => c.endsAt.isBiggerOrEqualValue(from))
        ..orderBy([(c) => OrderingTerm.asc(c.startsAt)]))
      .watch();

  Stream<DateTime?> watchFetchedAt() =>
      (_db.select(_db.syncMeta)..where((m) => m.key.equals(syncKey)))
          .watchSingleOrNull()
          .map((m) => m?.fetchedAt);

  /// Fetches [windowDays] from the start of [from]'s day. Throws [AppFailure].
  Future<void> refresh(DateTime from) async {
    final day = DateTime(from.year, from.month, from.day);
    final classes = await guardRequest(() async {
      final json = await _api.classes(from: day, days: windowDays);
      return [
        for (final c in (json['classes'] as List? ?? const []))
          ClassDto.fromJson((c as Map).cast<String, dynamic>()),
      ];
    });

    final end = day.add(const Duration(days: windowDays));
    await _db.transaction(() async {
      for (final c in classes) {
        await _upsertServer(c);
      }
      // Classes gone from the server (cancelled) disappear, unless the
      // member has a pending change on them: that change will fail with
      // the server's reason instead.
      final ids = classes.map((c) => c.id).toList();
      await (_db.delete(_db.classSessions)
            ..where((c) =>
                c.startsAt.isBetweenValues(day, end) &
                c.id.isNotIn(ids) &
                c.localState.equals(LocalBookingState.none)))
          .go();
      await _db.into(_db.syncMeta).insertOnConflictUpdate(
            SyncMetaCompanion.insert(key: syncKey, fetchedAt: _clock()),
          );
    });
  }

  /// Server columns only, so local booking state survives refreshes.
  Future<void> _upsertServer(ClassDto c, {bool clearLocal = false}) {
    final server = ClassSessionsCompanion(
      id: Value(c.id),
      className: Value(c.className),
      color: Value(c.color),
      instructor: Value(c.instructor),
      description: Value(c.description),
      startsAt: Value(c.startsAt),
      endsAt: Value(c.endsAt),
      capacity: Value(c.capacity),
      spotsLeft: Value(c.spotsLeft),
      isFull: Value(c.isFull),
      booked: Value(c.booked),
    );
    final update = clearLocal
        ? server.copyWith(localState: const Value(LocalBookingState.none), localError: const Value(null))
        : server;
    return _db.into(_db.classSessions).insert(server, onConflict: DoUpdate((_) => update));
  }

  Future<ClassSession?> _row(int id) =>
      (_db.select(_db.classSessions)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> _setLocal(int id, String state, [String? error]) =>
      (_db.update(_db.classSessions)..where((c) => c.id.equals(id))).write(ClassSessionsCompanion(
            localState: Value(state),
            localError: Value(error),
          ));

  /// Queues a booking. Cancelling a not-yet-sent cancellation instead just
  /// withdraws it.
  Future<void> book(int classId) async {
    final row = await _row(classId);
    if (row?.localState == LocalBookingState.cancelPending &&
        await _outbox.withdraw(ClassOutboxKind.cancel, classId)) {
      await _setLocal(classId, LocalBookingState.none);
      return;
    }
    await _outbox.dismissFailed(ClassOutboxKind.book, classId);
    await _outbox.enqueue(
      kind: ClassOutboxKind.book,
      targetId: classId,
      method: 'POST',
      path: ClassesApi.bookPath(classId),
    );
    await _setLocal(classId, LocalBookingState.bookPending);
    _outbox.drain();
  }

  /// Queues a cancellation, or withdraws a booking that was never sent.
  Future<void> cancel(int classId) async {
    final row = await _row(classId);
    if (row?.localState == LocalBookingState.bookPending &&
        await _outbox.withdraw(ClassOutboxKind.book, classId)) {
      await _setLocal(classId, LocalBookingState.none);
      return;
    }
    await _outbox.dismissFailed(ClassOutboxKind.cancel, classId);
    await _outbox.enqueue(
      kind: ClassOutboxKind.cancel,
      targetId: classId,
      method: 'POST',
      path: ClassesApi.cancelPath(classId),
    );
    await _setLocal(classId, LocalBookingState.cancelPending);
    _outbox.drain();
  }

  /// Clears a failed booking or cancellation after the member has seen it.
  Future<void> dismissFailure(int classId) async {
    await _outbox.dismissFailed(ClassOutboxKind.book, classId);
    await _outbox.dismissFailed(ClassOutboxKind.cancel, classId);
    await _setLocal(classId, LocalBookingState.none);
  }

  /// Outbox results for class bookings: the server's class wins.
  OutboxHandler get outboxHandler => _ClassOutboxHandler(this);
}

class _ClassOutboxHandler implements OutboxHandler {
  const _ClassOutboxHandler(this._repo);

  final ClassesRepository _repo;

  @override
  Future<void> onSent(OutboxEntry entry, Map<String, dynamic> response) async {
    final json = response['class'];
    if (json is Map) {
      try {
        await _repo._upsertServer(ClassDto.fromJson(json.cast<String, dynamic>()), clearLocal: true);
        return;
      } on FormatException {
        // Fall through to a minimal update.
      }
    }
    await (_repo._db.update(_repo._db.classSessions)..where((c) => c.id.equals(entry.targetId)))
        .write(ClassSessionsCompanion(
      booked: Value(entry.kind == ClassOutboxKind.book),
      localState: const Value(LocalBookingState.none),
      localError: const Value(null),
    ));
  }

  @override
  Future<void> onFailed(OutboxEntry entry, String message) => _repo._setLocal(
        entry.targetId,
        entry.kind == ClassOutboxKind.book ? LocalBookingState.bookFailed : LocalBookingState.cancelFailed,
        message,
      );
}
