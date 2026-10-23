import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../dto/auth_dto.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<OtpRequestResult> requestOtp(String phone) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/member/otp/request',
      data: {'phone': phone},
    );
    return OtpRequestResult.fromJson(res.data!);
  }

  Future<LoginResult> verifyOtp({
    required String phone,
    required String code,
    required String deviceName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/member/otp/verify',
      data: {'phone': phone, 'code': code, 'device_name': deviceName},
    );
    return LoginResult.fromJson(res.data!);
  }

  /// Revokes the current token on the server. A 401 here means the token
  /// is already gone, so it must not trigger the session-expired flow.
  Future<void> logout() => _dio.post<void>(
        '/member/logout',
        options: Options(
          extra: {AuthInterceptor.skipUnauthorizedHandler: true},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
