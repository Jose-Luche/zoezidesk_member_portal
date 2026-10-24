import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// Reads only. Writes (session sync and discard) go through the outbox.
class WorkoutsApi {
  const WorkoutsApi(this._dio);

  static String syncPath(String clientId) => '/member/workouts/sync/$clientId';

  final Dio _dio;

  Future<Map<String, dynamic>> exercises() async =>
      (await _dio.get<Map<String, dynamic>>('/member/workouts/exercises')).data!;

  Future<Map<String, dynamic>> page(int page) async => (await _dio.get<Map<String, dynamic>>(
        '/member/workouts',
        queryParameters: {'page': page},
      ))
          .data!;

  Future<Map<String, dynamic>> show(int serverId) async =>
      (await _dio.get<Map<String, dynamic>>('/member/workouts/$serverId')).data!;

  Future<Map<String, dynamic>> prs() async =>
      (await _dio.get<Map<String, dynamic>>('/member/workouts/prs')).data!;
}

final workoutsApiProvider = Provider<WorkoutsApi>((ref) => WorkoutsApi(ref.watch(dioProvider)));
