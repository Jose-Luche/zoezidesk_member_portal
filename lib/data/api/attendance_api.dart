import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

class AttendanceApi {
  const AttendanceApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> page(int page) async => (await _dio.get<Map<String, dynamic>>(
        '/member/attendance',
        queryParameters: {'page': page},
      ))
          .data!;
}

final attendanceApiProvider = Provider<AttendanceApi>((ref) => AttendanceApi(ref.watch(dioProvider)));
