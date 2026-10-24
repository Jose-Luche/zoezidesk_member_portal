import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// Reads and the goal. Diary entries are written through the outbox.
class NutritionApi {
  const NutritionApi(this._dio);

  static String entryPath(String clientId) => '/member/diary/logs/$clientId';

  final Dio _dio;

  Future<Map<String, dynamic>> foods() async =>
      (await _dio.get<Map<String, dynamic>>('/member/diary/foods')).data!;

  Future<Map<String, dynamic>> days(String from, String to) async => (await _dio.get<Map<String, dynamic>>(
        '/member/diary',
        queryParameters: {'from': from, 'to': to},
      ))
          .data!;

  Future<Map<String, dynamic>> goal() async =>
      (await _dio.get<Map<String, dynamic>>('/member/diary/goal')).data!;

  Future<Map<String, dynamic>> setGoal(Map<String, dynamic> body) async =>
      (await _dio.put<Map<String, dynamic>>('/member/diary/goal', data: body)).data!;
}

final nutritionApiProvider = Provider<NutritionApi>((ref) => NutritionApi(ref.watch(dioProvider)));
