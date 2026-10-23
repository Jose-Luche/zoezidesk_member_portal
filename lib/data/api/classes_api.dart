import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';

/// Reads the timetable. Book and cancel go through the outbox (queued,
/// idempotent), so they are paths here, not calls.
class ClassesApi {
  const ClassesApi(this._dio);

  final Dio _dio;

  static String bookPath(int classId) => '/member/classes/$classId/book';
  static String cancelPath(int classId) => '/member/classes/$classId/cancel';

  Future<Map<String, dynamic>> classes({required DateTime from, required int days}) async =>
      (await _dio.get<Map<String, dynamic>>(
        '/member/classes',
        queryParameters: {'from': DateFormat('yyyy-MM-dd').format(from), 'days': days},
      ))
          .data!;
}

final classesApiProvider = Provider<ClassesApi>((ref) => ClassesApi(ref.watch(dioProvider)));
