import 'package:dio/dio.dart';

/// Adds the bearer token and reports a 401 on an authenticated request so
/// the session can be ended. There are no refresh tokens: the backend
/// issues one Sanctum token per login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readToken, required this.onUnauthorized});

  /// Set in [RequestOptions.extra] to skip the 401 handler, e.g. for logout.
  static const skipUnauthorizedHandler = 'skip_unauthorized_handler';

  final Future<String?> Function() readToken;
  final void Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final hadToken = options.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 &&
        hadToken &&
        options.extra[skipUnauthorizedHandler] != true) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
