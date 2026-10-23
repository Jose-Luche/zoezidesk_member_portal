import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/clock.dart';
import '../api/builder_api.dart';
import '../db/encrypted_cache.dart';
import '../dto/builder_dto.dart';

/// Builder data. The form options and the latest workout are cached so the
/// member can review them offline; generating and editing are online only
/// because the server builds the workout. After every edit the workout is
/// re-read from the server, so the server always wins.
class BuilderRepository {
  const BuilderRepository({
    required this._api,
    required this._cache,
    required this._clock,
  });

  static const optionsKey = 'builder_options';
  static const workoutKey = 'builder_workout';

  final BuilderApi _api;
  final EncryptedCache _cache;
  final DateTime Function() _clock;

  Stream<Cached<BuilderOptions>?> watchOptions() =>
      _cache.watch(optionsKey).map((c) => c?.map(BuilderOptions.fromJson));

  Stream<Cached<GuidedWorkout>?> watchWorkout() =>
      _cache.watch(workoutKey).map((c) => c?.map(GuidedWorkout.fromJson));

  Future<void> refreshOptions() async {
    final json = await guardRequest(() async {
      final json = await _api.options();
      BuilderOptions.fromJson(json);
      return json;
    });
    await _cache.put(optionsKey, json, _clock());
  }

  Future<InterpretResult> interpret(String prompt) =>
      guardRequest(() async => InterpretResult.fromJson(await _api.interpret(prompt)));

  Future<GuidedWorkout> generate(BuilderInputs inputs) async {
    final json = await guardRequest(() => _api.generate(inputs));
    final workout = GuidedWorkout.fromJson(json);
    await _cache.put(workoutKey, json, _clock());
    return workout;
  }

  Future<List<ExerciseAlternative>> alternatives(int workoutId, int guidedExerciseId) =>
      guardRequest(() async => [
            for (final j in await _api.alternatives(workoutId, guidedExerciseId))
              ExerciseAlternative.fromJson(j),
          ]);

  Future<void> swap(int workoutId, int guidedExerciseId, int newExerciseId) =>
      _thenReload(workoutId, () => _api.swap(workoutId, guidedExerciseId, newExerciseId));

  Future<void> remove(int workoutId, int guidedExerciseId) =>
      _thenReload(workoutId, () => _api.remove(workoutId, guidedExerciseId));

  Future<void> reorder(int workoutId, List<int> orderedIds) =>
      _thenReload(workoutId, () => _api.reorder(workoutId, orderedIds));

  Future<void> saveTemplate(int workoutId, String name) =>
      _thenReload(workoutId, () => _api.saveTemplate(workoutId, name));

  Future<int> startSession(int workoutId) async {
    final sessionId = await guardRequest(() => _api.startSession(workoutId));
    await _reload(workoutId);
    return sessionId;
  }

  Future<void> _thenReload(int workoutId, Future<void> Function() action) async {
    await guardRequest(action);
    await _reload(workoutId);
  }

  Future<void> _reload(int workoutId) async {
    final json = await guardRequest(() => _api.workout(workoutId));
    await _cache.put(workoutKey, json, _clock());
  }
}

final builderRepositoryProvider = Provider<BuilderRepository>(
  (ref) => BuilderRepository(
    api: ref.watch(builderApiProvider),
    cache: ref.watch(encryptedCacheProvider),
    clock: ref.watch(clockProvider),
  ),
);
