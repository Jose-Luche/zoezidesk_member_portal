import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../errors/app_failure.dart';
import '../network/retry_interceptor.dart';

/// Applies a queued write's outcome to local data (e.g. a class row).
abstract interface class OutboxHandler {
  Future<void> onSent(OutboxEntry entry, Map<String, dynamic> response);
  Future<void> onFailed(OutboxEntry entry, String message);
}

/// Emitted when a queued write is confirmed or rejected by the server.
class OutboxEvent {
  const OutboxEvent.sent(this.entry, this.response) : error = null;
  const OutboxEvent.failed(this.entry, String this.error) : response = const {};

  final OutboxEntry entry;
  final Map<String, dynamic> response;
  final String? error;

  bool get succeeded => error == null;
}

abstract final class OutboxStatus {
  static const pending = 'pending';
  static const sending = 'sending';
  static const sent = 'sent';
  static const failed = 'failed';
}

/// Queues writes in the local database and sends them when the server can
/// be reached, oldest first.
///
/// - Every entry has an idempotency key; the backend answers a repeat from
///   its stored response, so resending after a lost reply is safe.
/// - Network errors, timeouts, 5xx, 409 and 429 retry with exponential
///   backoff (2s, 4s, 8s … up to 5 minutes).
/// - Other 4xx responses mark the entry failed with the server's message.
/// - A 401 stops the queue; the session layer logs the member out.
class OutboxService {
  OutboxService({
    required this._db,
    required this._dio,
    required this._clock,
    this._uuid = const Uuid(),
  });

  static const maxBackoff = Duration(minutes: 5);
  static const keepSentFor = Duration(days: 1);

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _clock;
  final _handlers = <String, OutboxHandler>{};
  final Uuid _uuid;
  final _events = StreamController<OutboxEvent>.broadcast();

  bool _again = false;
  Future<void>? _running;
  Timer? _timer;

  Stream<OutboxEvent> get events => _events.stream;

  /// Features register how a kind of write updates local data.
  void register(String kind, OutboxHandler handler) => _handlers[kind] = handler;

  static Duration backoff(int attempts) {
    final seconds = pow(2, attempts.clamp(1, 16)).toInt();
    final d = Duration(seconds: seconds);
    return d > maxBackoff ? maxBackoff : d;
  }

  Future<OutboxEntry> enqueue({
    required String kind,
    required int targetId,
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final now = _clock();
    final id = await _db.into(_db.outbox).insert(OutboxCompanion.insert(
          idempotencyKey: _uuid.v4(),
          kind: kind,
          targetId: targetId,
          method: method,
          path: path,
          body: Value(body == null ? null : jsonEncode(body)),
          createdAt: now,
          updatedAt: now,
        ));
    return (_db.select(_db.outbox)..where((o) => o.id.equals(id))).getSingle();
  }

  /// Drops a queued entry that has not started sending. Returns true if one
  /// was removed (so the write never reaches the server).
  Future<bool> withdraw(String kind, int targetId) async {
    final removed = await (_db.delete(_db.outbox)
          ..where((o) =>
              o.kind.equals(kind) &
              o.targetId.equals(targetId) &
              o.status.equals(OutboxStatus.pending)))
        .go();
    return removed > 0;
  }

  /// Forget failed entries for a target after the member has seen them.
  Future<void> dismissFailed(String kind, int targetId) => (_db.delete(_db.outbox)
        ..where((o) =>
            o.kind.equals(kind) & o.targetId.equals(targetId) & o.status.equals(OutboxStatus.failed)))
      .go();

  Stream<int> watchPendingCount() {
    final count = _db.outbox.id.count();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.status.isIn([OutboxStatus.pending, OutboxStatus.sending]));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// After a crash or kill, entries left "sending" may or may not have
  /// reached the server; the idempotency key makes resending them safe.
  Future<void> recover() => (_db.update(_db.outbox)
        ..where((o) => o.status.equals(OutboxStatus.sending)))
      .write(const OutboxCompanion(status: Value(OutboxStatus.pending)));

  /// Sends every due entry. Safe to call often: a call made while a drain
  /// is running joins it (the running drain makes one more pass) and
  /// completes when that drain finishes.
  Future<void> drain() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    if (_disposed) return Future.value();
    return _running = _drainOnce().catchError((Object e, StackTrace st) {
      // A failed pass must not crash the app; the next trigger retries.
      lastDrainError = e;
    }).whenComplete(() => _running = null);
  }

  /// The last unexpected error from a drain pass (not request failures,
  /// which are stored on the entry). For diagnostics.
  Object? lastDrainError;
  bool _disposed = false;

  Future<void> _drainOnce() async {
    _timer?.cancel();
    try {
      await _purgeSent();
      do {
        _again = false;
        final now = _clock();
        final due = await (_db.select(_db.outbox)
              ..where((o) =>
                  o.status.equals(OutboxStatus.pending) &
                  (o.nextAttemptAt.isNull() | o.nextAttemptAt.isSmallerOrEqualValue(now)))
              ..orderBy([(o) => OrderingTerm.asc(o.id)]))
            .get();
        for (final entry in due) {
          if (!await _send(entry)) return; // queue stopped (401)
        }
      } while (_again);
    } finally {
      await _scheduleNext();
    }
  }

  /// Returns false when the queue must stop.
  Future<bool> _send(OutboxEntry entry) async {
    await _setStatus(entry, OutboxStatus.sending);
    try {
      final res = await _dio.request<dynamic>(
        entry.path,
        data: entry.body == null ? null : jsonDecode(entry.body!),
        options: Options(
          method: entry.method,
          headers: {RetryInterceptor.idempotencyHeader: entry.idempotencyKey},
        ),
      );
      final json = res.data is Map ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
      await _handlers[entry.kind]?.onSent(entry, json);
      await _setStatus(entry, OutboxStatus.sent);
      _events.add(OutboxEvent.sent(entry, json));
      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      final status = e.response?.statusCode;
      if (failure is UnauthorizedFailure) {
        await _setStatus(entry, OutboxStatus.pending);
        return false;
      }
      final transient = failure is NetworkFailure ||
          failure is TimeoutFailure ||
          failure is RateLimitedFailure ||
          status == 409 ||
          status == null ||
          status >= 500;
      if (transient) {
        await _retryLater(entry, failure.message);
      } else {
        await (_db.update(_db.outbox)..where((o) => o.id.equals(entry.id))).write(OutboxCompanion(
              status: const Value(OutboxStatus.failed),
              lastError: Value(failure.message),
              attempts: Value(entry.attempts + 1),
              updatedAt: Value(_clock()),
            ));
        await _handlers[entry.kind]?.onFailed(entry, failure.message);
        _events.add(OutboxEvent.failed(entry, failure.message));
      }
      return true;
    }
  }

  Future<void> _retryLater(OutboxEntry entry, String reason) {
    final attempts = entry.attempts + 1;
    return (_db.update(_db.outbox)..where((o) => o.id.equals(entry.id))).write(OutboxCompanion(
          status: const Value(OutboxStatus.pending),
          attempts: Value(attempts),
          lastError: Value(reason),
          nextAttemptAt: Value(_clock().add(backoff(attempts))),
          updatedAt: Value(_clock()),
        ));
  }

  Future<void> _setStatus(OutboxEntry entry, String status) =>
      (_db.update(_db.outbox)..where((o) => o.id.equals(entry.id))).write(OutboxCompanion(
            status: Value(status),
            updatedAt: Value(_clock()),
          ));

  Future<void> _purgeSent() => (_db.delete(_db.outbox)
        ..where((o) =>
            o.status.equals(OutboxStatus.sent) &
            o.updatedAt.isSmallerThanValue(_clock().subtract(keepSentFor))))
      .go();

  /// Wake up for the earliest backed-off entry.
  Future<void> _scheduleNext() async {
    if (_disposed) return;
    final next = await (_db.select(_db.outbox)
          ..where((o) => o.status.equals(OutboxStatus.pending) & o.nextAttemptAt.isNotNull())
          ..orderBy([(o) => OrderingTerm.asc(o.nextAttemptAt)])
          ..limit(1))
        .getSingleOrNull();
    if (next == null) return;
    final wait = next.nextAttemptAt!.difference(_clock());
    _timer?.cancel();
    _timer = Timer(wait.isNegative ? Duration.zero : wait, drain);
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _events.close();
  }
}
