import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

class ProfileApi {
  const ProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> profile() async =>
      (await _dio.get<Map<String, dynamic>>('/member/profile')).data!;

  /// Sends only the changed fields; returns the updated profile.
  Future<Map<String, dynamic>> update(Map<String, Object?> changes) async =>
      (await _dio.patch<Map<String, dynamic>>('/member/profile', data: changes)).data!;
}

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(dioProvider)));
