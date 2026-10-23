import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';

DioException _response(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('timeouts and connection errors are network failures', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ]) {
      final e = DioException(requestOptions: RequestOptions(), type: type);
      expect(mapDioException(e), isA<NetworkFailure>());
    }
  });

  test('401 is unauthorized', () {
    expect(mapDioException(_response(401, {'message': 'Unauthenticated.'})),
        isA<UnauthorizedFailure>());
  });

  test('422 uses the first Laravel field error', () {
    final f = mapDioException(_response(422, {
      'message': 'The code field must be 6 digits.',
      'errors': {
        'code': ['The code field must be 6 digits.'],
      },
    }));
    expect(f, isA<ValidationFailure>());
    expect(f.message, 'The code field must be 6 digits.');
    expect((f as ValidationFailure).fieldErrors['code'], isNotNull);
  });

  test('422 without field errors uses the message', () {
    final f = mapDioException(_response(422, {
      'success': false,
      'message': 'Invalid or expired code. Please request a new one.',
    }));
    expect(f.message, 'Invalid or expired code. Please request a new one.');
  });

  test('429 carries retry_after', () {
    final f = mapDioException(_response(429, {
      'message': 'Too many attempts.',
      'retry_after': 120,
    }));
    expect((f as RateLimitedFailure).retryAfter, const Duration(seconds: 120));
  });

  test('5xx and HTML bodies never leak server text', () {
    final f = mapDioException(_response(500, '<html>Server Error</html>'));
    expect(f, isA<ServerFailure>());
    expect(f.message, 'Something went wrong. Please try again.');
  });

  test('guardRequest turns parse errors into ServerFailure', () async {
    await expectLater(
      guardRequest<int>(() async => (null as dynamic) as int),
      throwsA(isA<ServerFailure>()),
    );
  });
}
