import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// Phones that receive notifications (`/member/devices`).
class DevicesApi {
  const DevicesApi(this._dio);

  final Dio _dio;

  /// Registering the same token again only refreshes it.
  Future<void> register(String token) => _dio.put<void>(
        '/member/devices',
        data: {'token': token, 'platform': 'android'},
      );

  Future<void> unregister(String token) =>
      _dio.delete<void>('/member/devices', data: {'token': token});
}

final devicesApiProvider = Provider<DevicesApi>((ref) => DevicesApi(ref.watch(dioProvider)));
