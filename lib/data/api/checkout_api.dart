import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/retry_interceptor.dart';

class CheckoutApi {
  const CheckoutApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> plans() async =>
      (await _dio.get<Map<String, dynamic>>('/member/payments/plans')).data!;

  /// Sends the M-Pesa prompt. The same [idempotencyKey] never sends twice.
  Future<Map<String, dynamic>> stkPush({
    required int planId,
    required String phone,
    required String idempotencyKey,
  }) async =>
      (await _dio.post<Map<String, dynamic>>(
        '/member/payments/stk',
        data: {'plan_id': planId, 'phone': phone},
        options: Options(headers: {RetryInterceptor.idempotencyHeader: idempotencyKey}),
      ))
          .data!;

  Future<Map<String, dynamic>> status(int paymentId) async =>
      (await _dio.get<Map<String, dynamic>>('/member/payments/$paymentId/status')).data!;
}

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi(ref.watch(dioProvider)));
