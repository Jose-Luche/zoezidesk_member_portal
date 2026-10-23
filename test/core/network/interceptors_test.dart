import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/network/auth_interceptor.dart';
import 'package:zoezidesk_member/core/network/dio_client.dart';
import 'package:zoezidesk_member/core/network/retry_interceptor.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAdapter adapter;
  late Dio dio;
  late int unauthorizedCalls;
  String? token;

  setUp(() {
    adapter = FakeAdapter();
    unauthorizedCalls = 0;
    token = 'abc';
    dio = buildDio(
      baseUrl: 'https://api.test',
      auth: AuthInterceptor(
        readToken: () async => token,
        onUnauthorized: () => unauthorizedCalls++,
      ),
    );
    dio.httpClientAdapter = adapter;
    // Replace the default retry interceptor with one that does not sleep.
    dio.interceptors
      ..removeWhere((i) => i is RetryInterceptor)
      ..add(RetryInterceptor(dio, sleep: (_) async {}));
  });

  group('AuthInterceptor', () {
    test('adds the bearer token', () async {
      adapter.reply(200, {'ok': true});
      await dio.get<dynamic>('/member/qr');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
    });

    test('omits the header when signed out', () async {
      token = null;
      adapter.reply(200, {'ok': true});
      await dio.get<dynamic>('/member/qr');
      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('reports 401 on authenticated requests', () async {
      adapter.reply(401, {'message': 'Unauthenticated.'});
      await expectLater(dio.get<dynamic>('/member/qr'), throwsA(isA<DioException>()));
      expect(unauthorizedCalls, 1);
    });

    test('ignores 401 when the request opts out (logout)', () async {
      adapter.reply(401, {'message': 'Unauthenticated.'});
      await expectLater(
        dio.post<dynamic>(
          '/member/logout',
          options: Options(extra: {AuthInterceptor.skipUnauthorizedHandler: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, 0);
    });

    test('ignores 401 on unauthenticated requests (wrong code)', () async {
      token = null;
      adapter.reply(401, {'message': 'nope'});
      await expectLater(dio.post<dynamic>('/member/otp/verify'), throwsA(anything));
      expect(unauthorizedCalls, 0);
    });
  });

  group('RetryInterceptor', () {
    test('retries GET on 503 then succeeds', () async {
      adapter
        ..reply(503)
        ..reply(503)
        ..reply(200, {'ok': true});
      final res = await dio.get<Map<String, dynamic>>('/member/dashboard');
      expect(res.data, {'ok': true});
      expect(adapter.requests, hasLength(3));
    });

    test('retries GET on connection errors', () async {
      adapter
        ..fail(DioExceptionType.connectionError)
        ..reply(200, {'ok': true});
      await dio.get<dynamic>('/member/dashboard');
      expect(adapter.requests, hasLength(2));
    });

    test('gives up after 3 retries', () async {
      for (var i = 0; i < 4; i++) {
        adapter.reply(503);
      }
      await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(4));
    });

    test('never retries a POST without an idempotency key', () async {
      adapter.reply(503);
      await expectLater(dio.post<dynamic>('/member/otp/verify'), throwsA(anything));
      expect(adapter.requests, hasLength(1));
    });

    test('retries a POST that carries an idempotency key', () async {
      adapter
        ..reply(503)
        ..reply(200, {'ok': true});
      await dio.post<dynamic>(
        '/member/classes/1/book',
        options: Options(headers: {RetryInterceptor.idempotencyHeader: 'k1'}),
      );
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers[RetryInterceptor.idempotencyHeader], 'k1');
    });

    test('does not retry client errors', () async {
      adapter.reply(422, {'message': 'bad'});
      await expectLater(dio.get<dynamic>('/x'), throwsA(anything));
      expect(adapter.requests, hasLength(1));
    });

    test('backoff doubles with bounded jitter', () {
      final r = RetryInterceptor(Dio());
      for (var attempt = 0; attempt < 3; attempt++) {
        final base = 500 * (1 << attempt);
        final ms = r.delayFor(attempt).inMilliseconds;
        expect(ms, inInclusiveRange(base, base + 500));
      }
    });
  });
}
