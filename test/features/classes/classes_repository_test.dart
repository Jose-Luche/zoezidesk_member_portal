import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/sync/outbox_service.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';
import 'package:zoezidesk_member/data/repositories/classes_repository.dart';
import 'package:zoezidesk_member/data/sync/sync.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  late TestEnv env;
  late ProviderContainer c;

  setUp(() {
    env = TestEnv();
    c = ProviderContainer(overrides: env.overrides);
  });

  tearDown(() async {
    c.dispose();
    await env.dispose();
  });

  ClassesRepository repo() => c.read(classesRepositoryProvider);
  OutboxService outbox() => c.read(outboxServiceProvider);

  void serverHas(List<Map<String, dynamic>> classes) {
    when(() => env.classesApi.classes(from: any(named: 'from'), days: any(named: 'days')))
        .thenAnswer((_) async => {'classes': classes});
  }

  Future<ClassSession> row(int id) =>
      (env.db.select(env.db.classSessions)..where((t) => t.id.equals(id))).getSingle();

  test('refresh caches two weeks and records when', () async {
    serverHas([classJson(1), classJson(2, day: 24, booked: true)]);

    await repo().refresh(testNow);

    final rows = await repo().watchFrom(DateTime(2026, 10, 23)).first;
    expect(rows.map((r) => r.id), [1, 2]);
    expect(rows.last.booked, isTrue);
    expect(await repo().watchFetchedAt().first, testNow);
    verify(() => env.classesApi.classes(from: DateTime(2026, 10, 23), days: 14)).called(1);
  });

  test('refresh failure keeps the cache', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);
    when(() => env.classesApi.classes(from: any(named: 'from'), days: any(named: 'days'))).thenThrow(
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
    );

    await expectLater(repo().refresh(testNow), throwsA(isA<NetworkFailure>()));
    expect(await repo().watchFrom(DateTime(2026, 10, 23)).first, hasLength(1));
  });

  test('booking is queued and shown as pending, then confirmed by the server', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);
    env.http.reply(200, {'success': true, 'class': classJson(1, spotsLeft: 5, booked: true)});

    await repo().book(1);
    expect((await row(1)).localState, LocalBookingState.bookPending);
    await outbox().drain();

    final r = await row(1);
    expect(r.booked, isTrue);
    expect(r.spotsLeft, 5);
    expect(r.localState, LocalBookingState.none);
    expect(env.http.requests.single.path, '/member/classes/1/book');
  });

  test('offline booking stays pending and survives a refresh', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);

    await repo().book(1); // nothing queued in the fake HTTP: offline
    await outbox().drain();
    serverHas([classJson(1, spotsLeft: 3)]);
    await repo().refresh(testNow);

    final r = await row(1);
    expect(r.localState, LocalBookingState.bookPending);
    expect(r.spotsLeft, 3); // server columns still update
  });

  test('a rejected booking shows the server reason until dismissed', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);
    env.http.reply(422, {'success': false, 'code': 'full', 'message': 'This class is fully booked.'});

    await repo().book(1);
    await outbox().drain();

    var r = await row(1);
    expect(r.localState, LocalBookingState.bookFailed);
    expect(r.localError, 'This class is fully booked.');
    expect(r.booked, isFalse);

    await repo().dismissFailure(1);
    r = await row(1);
    expect(r.localState, LocalBookingState.none);
    expect(await env.db.select(env.db.outbox).get(), isEmpty);
  });

  test('cancelling an unsent booking withdraws it without a request', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);

    await repo().book(1);
    await repo().cancel(1);
    await outbox().drain();

    expect((await row(1)).localState, LocalBookingState.none);
    expect(env.http.requests.where((r) => r.method == 'POST' && r.path.endsWith('/cancel')), isEmpty);
    expect(await env.db.select(env.db.outbox).get(), isEmpty);
  });

  test('cancel is queued for a confirmed booking', () async {
    serverHas([classJson(1, booked: true)]);
    await repo().refresh(testNow);
    env.http.reply(200, {'success': true, 'class': classJson(1, spotsLeft: 7)});

    await repo().cancel(1);
    expect((await row(1)).localState, LocalBookingState.cancelPending);
    await outbox().drain();

    expect((await row(1)).booked, isFalse);
    expect(env.http.requests.single.path, '/member/classes/1/cancel');
  });

  test('classes cancelled by the gym disappear unless a change is pending', () async {
    serverHas([classJson(1), classJson(2)]);
    await repo().refresh(testNow);
    await repo().book(2);

    serverHas([]);
    await repo().refresh(testNow);

    final ids = (await repo().watchFrom(DateTime(2026, 10, 23)).first).map((r) => r.id);
    expect(ids, [2]);
  });

  test('logout wipes classes and the outbox', () async {
    serverHas([classJson(1)]);
    await repo().refresh(testNow);
    await repo().book(1);

    await env.db.wipe();

    expect(await env.db.select(env.db.classSessions).get(), isEmpty);
    expect(await env.db.select(env.db.outbox).get(), isEmpty);
  });
}
