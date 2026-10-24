import 'package:dio/dio.dart';

import '../storage/session_storage.dart';
import 'auth_interceptor.dart';

/// Exchanges the stored refresh token for new tokens
/// (`POST /member/token/refresh`) and stores them.
class TokenRefresher {
  const TokenRefresher(this._storage);

  final SessionStorage _storage;

  Future<RefreshResult> call(Dio dio) async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const RefreshRejected();
    }
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/member/token/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {AuthInterceptor.skipUnauthorizedHandler: true}),
      );
      final token = res.data?['token'];
      final next = res.data?['refresh_token'];
      if (token is! String || next is! String) {
        return RefreshUnavailable(DioException.badResponse(
          statusCode: res.statusCode ?? 200,
          requestOptions: res.requestOptions,
          response: res,
        ));
      }
      await _storage.saveTokens(token: token, refreshToken: next);
      return Refreshed(token);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 401: ended, expired or replaced; 422: not a token we can send.
      if (status == 401 || status == 422) return const RefreshRejected();
      return RefreshUnavailable(e);
    }
  }
}
