import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

class PaymentsApi {
  const PaymentsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> page(int page) async => (await _dio.get<Map<String, dynamic>>(
        '/member/payments',
        queryParameters: {'page': page},
      ))
          .data!;

  /// A short-lived signed link to the receipt PDF; opens without the token.
  Future<Map<String, dynamic>> receiptLink(int paymentId) async =>
      (await _dio.post<Map<String, dynamic>>('/member/payments/$paymentId/receipt-link')).data!;
}

final paymentsApiProvider = Provider<PaymentsApi>((ref) => PaymentsApi(ref.watch(dioProvider)));
