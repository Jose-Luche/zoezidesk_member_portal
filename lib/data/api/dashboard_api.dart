import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// Returns raw JSON: the repository caches exactly what the server sent and
/// parses on read, so a newer app can read an older cache.
class DashboardApi {
  const DashboardApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> dashboard() async =>
      (await _dio.get<Map<String, dynamic>>('/member/dashboard')).data!;

  Future<Map<String, dynamic>> memberCard() async =>
      (await _dio.get<Map<String, dynamic>>('/member/qr')).data!;
}

final dashboardApiProvider =
    Provider<DashboardApi>((ref) => DashboardApi(ref.watch(dioProvider)));
