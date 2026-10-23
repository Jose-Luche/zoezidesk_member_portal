import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/storage/local_data_wiper.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/data/dto/auth_dto.dart';
import 'package:zoezidesk_member/data/repositories/auth_repository.dart';

import '../helpers/fakes.dart';

void main() {
  late MockAuthApi api;
  late InMemorySecureStore store;
  late SessionStorage storage;
  late AuthRepository repo;

  setUp(() {
    api = MockAuthApi();
    store = InMemorySecureStore();
    storage = SessionStorage(store);
    repo = AuthRepository(
      api: api,
      storage: storage,
      wiper: LocalDataWiper(sessionStorage: storage),
    );
  });

  test('verifyOtp stores token and member in secure storage', () async {
    when(() => api.verifyOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          deviceName: any(named: 'deviceName'),
        )).thenAnswer((_) async => const LoginResult(token: 't1', member: testMember));

    final member = await repo.verifyOtp(phone: '0711000001', code: '123456');

    expect(member, testMember);
    expect(await storage.readToken(), 't1');
    expect(await storage.readMember(), testMember);
  });

  test('verifyOtp maps dio errors and stores nothing', () async {
    final options = RequestOptions(path: '/member/otp/verify');
    when(() => api.verifyOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          deviceName: any(named: 'deviceName'),
        )).thenThrow(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 422,
        data: {'success': false, 'message': 'Invalid or expired code.'},
      ),
    ));

    await expectLater(
      repo.verifyOtp(phone: '0711000001', code: '000000'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(store.values, isEmpty);
  });

  test('restoreSession returns the stored member', () async {
    await storage.save(token: 't1', member: testMember);
    expect(await repo.restoreSession(), testMember);
  });

  test('restoreSession wipes a token without a member', () async {
    await store.write('auth_token', 't1');
    expect(await repo.restoreSession(), isNull);
    expect(store.values, isEmpty);
  });

  test('restoreSession wipes unreadable member data', () async {
    await store.write('auth_token', 't1');
    await store.write('auth_member', '{not json');
    expect(await repo.restoreSession(), isNull);
    expect(store.values, isEmpty);
  });

  test('logout revokes on the server and wipes local data', () async {
    await storage.save(token: 't1', member: testMember);
    when(() => api.logout()).thenAnswer((_) async {});

    await repo.logout();

    verify(() => api.logout()).called(1);
    expect(store.values, isEmpty);
  });

  test('logout still wipes local data when offline', () async {
    await storage.save(token: 't1', member: testMember);
    when(() => api.logout()).thenThrow(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    ));

    await repo.logout();

    expect(store.values, isEmpty);
  });

  test('requestOtp returns the server result', () async {
    when(() => api.requestOtp(any())).thenAnswer(
      (_) async => const OtpRequestResult(success: true, message: 'sent'),
    );
    final result = await repo.requestOtp('0711000001');
    expect(result.message, 'sent');
  });
}
