import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/network/retry_interceptor.dart';
import 'package:zoezidesk_member/core/sync/outbox_service.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

class _RecordingHandler implements OutboxHandler {
  final sent = <(OutboxEntry, Map<String, dynamic>)>[];
  final failed = <(OutboxEntry, String)>[];

  @override
  Future<void> onSent(OutboxEntry entry, Map<String, dynamic> response) async => sent.add((entry, response));

  @override
  Future<void> onFailed(OutboxEntry entry, String message) async => failed.add((entry, message));
}

void main() {
  late AppDatabase db;
  late FakeAdapter http;
  late _RecordingHandler handler;
  late OutboxService outbox;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    http = FakeAdapter();
    handler = _RecordingHandler();
    now = testNow;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = http;
    outbox = OutboxService(db: db, dio: dio, clock: () => now)
      ..register('class_book', handler)
      ..register('class_cancel', handler);
  });

  tearDown(() async {
    outbox.dispose();
    await db.close();
  });

  Future<OutboxEntry> queue([String kind = 'class_book', int target = 1]) =>
      outbox.enqueue(kind: kind, targetId: target, method: 'POST', path: '/member/classes/$target/book');

  Future<List<OutboxEntry>> rows() => db.select(db.outbox).get();

  test('sends with the idempotency key and reports success', () async {
    final entry = await queue();
    http.reply(200, {'success': true, 'class': {'id': 1}});

    await outbox.drain();

    expect(http.requests.single.headers[RetryInterceptor.idempotencyHeader], entry.idempotencyKey);
    expect(http.requests.single.method, 'POST');
    expect(handler.sent.single.$2['success'], isTrue);
    expect((await rows()).single.status, OutboxStatus.sent);
  });

  test('a server rejection fails the entry with the server message', () async {
    await queue();
    http.reply(422, {'success': false, 'code': 'full', 'message': 'This class is fully booked.'});

    await outbox.drain();

    final row = (await rows()).single;
    expect(row.status, OutboxStatus.failed);
    expect(row.lastError, 'This class is fully booked.');
    expect(handler.failed.single.$2, 'This class is fully booked.');
  });

  test('offline retries later with exponential backoff and the same key', () async {
    final entry = await queue();
    http.fail(DioExceptionType.connectionError);

    await outbox.drain();

    var row = (await rows()).single;
    expect(row.status, OutboxStatus.pending);
    expect(row.attempts, 1);
    expect(row.nextAttemptAt, testNow.add(const Duration(seconds: 2)));

    // Not due yet: nothing is sent.
    await outbox.drain();
    expect(http.requests, hasLength(1));

    now = testNow.add(const Duration(seconds: 3));
    http.reply(503);
    await outbox.drain();
    row = (await rows()).single;
    expect(row.attempts, 2);
    expect(row.nextAttemptAt, now.add(const Duration(seconds: 4)));

    now = now.add(const Duration(seconds: 5));
    http.reply(200, {'success': true});
    await outbox.drain();
    expect((await rows()).single.status, OutboxStatus.sent);
    expect(
      http.requests.map((r) => r.headers[RetryInterceptor.idempotencyHeader]).toSet(),
      {entry.idempotencyKey},
    );
  });

  test('409 (still processing) and 429 are retried, not failed', () async {
    await queue('class_book', 1);
    await queue('class_book', 2);
    http
      ..reply(409, {'message': 'This request is still being processed.'})
      ..reply(429, {'message': 'Too many'});

    await outbox.drain();

    expect((await rows()).map((r) => r.status), everyElement(OutboxStatus.pending));
    expect(handler.failed, isEmpty);
  });

  test('a 401 stops the queue and keeps the entries', () async {
    await queue('class_book', 1);
    await queue('class_book', 2);
    http.reply(401, {'message': 'Unauthenticated.'});

    await outbox.drain();

    expect(http.requests, hasLength(1));
    expect((await rows()).map((r) => r.status), everyElement(OutboxStatus.pending));
  });

  test('entries go oldest first', () async {
    await queue('class_book', 7);
    await queue('class_cancel', 8);
    http
      ..reply(200, {})
      ..reply(200, {});

    await outbox.drain();

    expect(http.requests.map((r) => r.path), ['/member/classes/7/book', '/member/classes/8/book']);
  });

  test('recover puts interrupted sends back in the queue', () async {
    final e = await queue();
    await (db.update(db.outbox)..where((o) => o.id.equals(e.id)))
        .write(const OutboxCompanion(status: Value(OutboxStatus.sending)));

    await outbox.recover();

    expect((await rows()).single.status, OutboxStatus.pending);
  });

  test('withdraw removes an unsent entry only', () async {
    await queue('class_book', 1);
    expect(await outbox.withdraw('class_book', 1), isTrue);
    expect(await rows(), isEmpty);
    expect(await outbox.withdraw('class_book', 1), isFalse);
  });

  test('pending count covers pending and sending', () async {
    final counts = <int>[];
    final sub = outbox.watchPendingCount().listen(counts.add);
    await queue('class_book', 1);
    await queue('class_book', 2);
    await pumpEventQueue();
    expect(counts.last, 2);
    await sub.cancel();
  });

  test('coalescing kinds send only the newest entry per target', () async {
    outbox
      ..register('workout_sync', handler)
      ..coalesce('workout_sync');
    await queue('workout_sync', 1);
    await queue('workout_sync', 2);
    final newest = await queue('workout_sync', 1);
    http
      ..reply(200, {'n': 1})
      ..reply(200, {'n': 2});

    await outbox.drain();

    expect(http.requests, hasLength(2));
    expect(handler.sent.map((s) => s.$1.id), containsAll([newest.id]));
    expect(handler.sent.where((s) => s.$1.targetId == 1).single.$1.id, newest.id);
  });

  test('an entry that fails while a newer one waits is dropped, not retried', () async {
    outbox
      ..register('workout_sync', handler)
      ..coalesce('workout_sync');
    final older = await queue('workout_sync', 1);
    // The newer copy arrives while the older one is being sent.
    http.fail(DioExceptionType.connectionError);
    final sending = outbox.drain();
    final newer = await queue('workout_sync', 1);
    await sending;

    final left = await rows();
    expect(left.map((r) => r.id), isNot(contains(older.id)));
    expect(left.map((r) => r.id), contains(newer.id));
  });

  test('backoff doubles and caps at five minutes', () {
    expect(OutboxService.backoff(1), const Duration(seconds: 2));
    expect(OutboxService.backoff(3), const Duration(seconds: 8));
    expect(OutboxService.backoff(20), OutboxService.maxBackoff);
  });
}
