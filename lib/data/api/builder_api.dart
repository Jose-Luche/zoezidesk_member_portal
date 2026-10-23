import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../dto/builder_dto.dart';

/// Guided workout builder endpoints. Generation runs on the server, so
/// everything here except reading the cache needs a connection.
class BuilderApi {
  const BuilderApi(this._dio);

  static const _base = '/member/guided-workout';

  final Dio _dio;

  Future<Map<String, dynamic>> _get(String path) async =>
      (await _dio.get<Map<String, dynamic>>(path)).data!;

  Future<Map<String, dynamic>> _post(String path, [Object? data]) async =>
      (await _dio.post<Map<String, dynamic>>(path, data: data)).data ?? const {};

  Future<Map<String, dynamic>> options() => _get('$_base/options');

  Future<Map<String, dynamic>> generate(BuilderInputs inputs) => _post('$_base/generate', {
        'energy_level': inputs.energyLevel,
        'time_minutes': inputs.timeMinutes,
        'focus_muscles': inputs.focusMuscles,
        'excluded_muscles': inputs.excludedMuscles,
        'equipment': inputs.equipment,
        'goal': inputs.goal,
        'experience_level': inputs.experienceLevel,
      });

  Future<Map<String, dynamic>> workout(int id) => _get('$_base/$id');

  Future<List<Map<String, dynamic>>> alternatives(int workoutId, int guidedExerciseId) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/$workoutId/exercises/$guidedExerciseId/alternatives',
    );
    return [for (final e in res.data ?? const []) (e as Map).cast<String, dynamic>()];
  }

  Future<void> swap(int workoutId, int guidedExerciseId, int newExerciseId) =>
      _post('$_base/$workoutId/swap-exercise', {
        'guided_workout_exercise_id': guidedExerciseId,
        'new_exercise_id': newExerciseId,
      });

  Future<void> remove(int workoutId, int guidedExerciseId) =>
      _dio.delete<void>('$_base/$workoutId/exercises/$guidedExerciseId');

  /// [orderedIds] are guided-exercise ids in their new order.
  Future<void> reorder(int workoutId, List<int> orderedIds) => _post('$_base/$workoutId/reorder', {
        'exercises': [
          for (var i = 0; i < orderedIds.length; i++) {'id': orderedIds[i], 'order': i + 1},
        ],
      });

  Future<void> saveTemplate(int workoutId, String name) =>
      _post('$_base/$workoutId/save-template', {'template_name': name});

  /// Returns the new workout session id.
  Future<int> startSession(int workoutId) async {
    final json = await _post('$_base/$workoutId/start-session');
    return (json['session_id'] as num).toInt();
  }
}

final builderApiProvider = Provider<BuilderApi>((ref) => BuilderApi(ref.watch(dioProvider)));
