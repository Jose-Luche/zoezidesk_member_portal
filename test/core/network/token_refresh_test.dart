import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/network/auth_interceptor.dart';
import 'package:zoezidesk_member/core/network/dio_client.dart';
import 'package:zoezidesk_member/core/network/retry_interceptor.dart';
import 'package:zoezidesk_member/core/network/token_refresher.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAdapter adapter;
  late SessionStorage storage;
  late Dio dio;
  late int unauthorizedCalls;

  setUp(() async {
    adapter = FakeAdapter();
    storage = SessionStorage(InMemorySecureStore());
    await storage.save(token: 'old', refreshToken: 'r1', member: testMember);
    unauthorizedCalls = 0;
    dio = buildDio(
      baseUrl: 'https://api.test',
      auth: AuthInterceptor(
        readToken: storage.readToken,
        refresh: TokenRefresher(storage).call,
        onUnauthorized: () => unauthorizedCalls++,
      ),
    );
    dio.httpClientAdapter = adapter;
    dio.interceptors
      ..removeWhere((i) => i is RetryInterceptor)
      ..add(RetryInterceptor(dio, sleep: (_) async {}));
  });

  List<String> paths() => [for (final r in adapter.requests) '${r.method} ${r.path}'];

  test('an expired token is renewed and the request repeated', () async {
    adapter
      ..reply(401, {'message': 'Unauthenticated.'})
      ..reply(200, {'token': 'new', 'refresh_token': 'r2'})
      ..reply(200, {'ok': true});

    final res = await dio.get<Map<String, dynamic>>('/member/dashboard');

    expect(res.data, {'ok': true});
    expect(paths(), ['GET /member/dashboard', 'POST /member/token/refresh', 'GET /member/dashboard']);
    expect(adapter.requests[1].data, {'refresh_token': 'r1'});
    expect(adapter.requests[2].headers['Authorization'], 'Bearer new');
    expect(await storage.readToken(), 'new');
    expect(await storage.readRefreshToken(), 'r2');
    expect(unauthorizedCalls, 0);
  });

  test('requests failing together share one refresh', () async {
    adapter
      ..reply(401)
      ..reply(401)
      ..reply(200, {'token': 'new', 'refresh_token': 'r2'})
      ..reply(200, {'n': 1})
      ..reply(200, {'n': 2});

    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/member/dashboard'),
      dio.get<Map<String, dynamic>>('/member/classes'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(paths().where((p) => p.contains('refresh')), hasLength(1));
    expect(adapter.requests.skip(3).map((r) => r.headers['Authorization']), everyElement('Bearer new'));
  });

  test('a refused refresh ends the session', () async {
    adapter
      ..reply(401)
      ..reply(401, {'message': 'Your session has ended. Please log in again.'});

    await expectLater(
      dio.get<dynamic>('/member/dashboard'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(unauthorizedCalls, 1);
    expect(paths(), hasLength(2));
  });

  test('offline during the refresh keeps the session', () async {
    adapter
      ..reply(401)
      ..fail(DioExceptionType.connectionError);

    await expectLater(
      dio.get<dynamic>('/member/dashboard'),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
    );
    expect(unauthorizedCalls, 0);
    expect(await storage.readRefreshToken(), 'r1');
  });

  test('a 401 after renewing ends the session instead of looping', () async {
    adapter
      ..reply(401)
      ..reply(200, {'token': 'new', 'refresh_token': 'r2'})
      ..reply(401);

    await expectLater(dio.get<dynamic>('/member/dashboard'), throwsA(isA<DioException>()));
    expect(unauthorizedCalls, 1);
    expect(paths(), hasLength(3));
  });

  test('a token renewed by another request is used without refreshing again', () async {
    adapter
      ..reply(401)
      ..reply(200, {'ok': true});
    // Sent with 'old'; by the time its 401 arrives, 'new' is stored.
    dio.interceptors.insert(0, InterceptorsWrapper(onResponse: (r, h) => h.next(r), onError: (e, h) async {
      await storage.saveTokens(token: 'new', refreshToken: 'r2');
      h.next(e);
    }));

    final res = await dio.get<Map<String, dynamic>>('/member/dashboard');

    expect(res.data, {'ok': true});
    expect(paths(), ['GET /member/dashboard', 'GET /member/dashboard']);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
  });

  test('without a refresh token (older server) a 401 ends the session', () async {
    storage = SessionStorage(InMemorySecureStore());
    await storage.save(token: 'old', member: testMember);
    dio = buildDio(
      baseUrl: 'https://api.test',
      auth: AuthInterceptor(
        readToken: storage.readToken,
        refresh: TokenRefresher(storage).call,
        onUnauthorized: () => unauthorizedCalls++,
      ),
    )..httpClientAdapter = adapter;
    adapter.reply(401);

    await expectLater(dio.get<dynamic>('/member/dashboard'), throwsA(isA<DioException>()));
    expect(unauthorizedCalls, 1);
    expect(paths(), ['GET /member/dashboard']);
  });

  test('a queued write keeps its idempotency key when repeated', () async {
    adapter
      ..reply(401)
      ..reply(200, {'token': 'new', 'refresh_token': 'r2'})
      ..reply(200, {'ok': true});

    await dio.post<dynamic>('/member/classes/5/book', options: Options(headers: {'Idempotency-Key': 'k1'}));

    expect(adapter.requests.last.headers['Idempotency-Key'], 'k1');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
  });
}
