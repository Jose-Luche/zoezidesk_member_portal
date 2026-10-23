import 'package:freezed_annotation/freezed_annotation.dart';

part 'builder_dto.freezed.dart';
part 'builder_dto.g.dart';

/// Laravel decimals arrive as strings ("12.50"); integers as numbers.
num? _numOrNull(Object? v) => switch (v) {
      final num n => n,
      final String s => num.tryParse(s),
      _ => null,
    };

int _intOr(Object? v, int fallback) => _numOrNull(v)?.round() ?? fallback;

List<String> _stringList(Object? v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

/// The builder answers: same fields as `POST /member/guided-workout/generate`.
@freezed
abstract class BuilderInputs with _$BuilderInputs {
  const factory BuilderInputs({
    @Default('medium') String energyLevel,
    @Default(45) int timeMinutes,
    @Default([]) List<String> focusMuscles,
    @Default([]) List<String> excludedMuscles,
    @Default([]) List<String> equipment,
    @Default('stay_active') String goal,
    @Default('beginner') String experienceLevel,
  }) = _BuilderInputs;

  /// Tolerant of the server's loose types (e.g. time as a string).
  factory BuilderInputs.fromServer(Map<String, dynamic> json) => BuilderInputs(
        energyLevel: json['energy_level'] as String? ?? 'medium',
        timeMinutes: _intOr(json['time_minutes'], 45).clamp(10, 180),
        focusMuscles: _stringList(json['focus_muscles']),
        excludedMuscles: _stringList(json['excluded_muscles']),
        equipment: _stringList(json['equipment']),
        goal: json['goal'] as String? ?? 'stay_active',
        experienceLevel: json['experience_level'] as String? ?? 'beginner',
      );

  factory BuilderInputs.fromJson(Map<String, dynamic> json) => _$BuilderInputsFromJson(json);
}

@freezed
abstract class SuggestedMuscle with _$SuggestedMuscle {
  const factory SuggestedMuscle({
    required String key,
    required String label,
    String? reason,
  }) = _SuggestedMuscle;

  factory SuggestedMuscle.fromJson(Map<String, dynamic> json) => _$SuggestedMuscleFromJson(json);
}

/// `GET /member/guided-workout/options`.
class BuilderOptions {
  const BuilderOptions({
    required this.muscles,
    required this.equipment,
    required this.goals,
    required this.experienceLevels,
    required this.energyLevels,
    required this.minMinutes,
    required this.maxMinutes,
    required this.lastInputs,
    required this.suggestedMuscles,
  });

  factory BuilderOptions.fromJson(Map<String, dynamic> json) {
    Map<String, String> labels(Object? v) =>
        v is Map ? v.map((k, l) => MapEntry('$k', '$l')) : const {};
    final time = json['time_minutes'] is Map ? json['time_minutes'] as Map : const {};
    return BuilderOptions(
      muscles: labels(json['muscles']),
      equipment: labels(json['equipment']),
      goals: labels(json['goals']),
      experienceLevels: labels(json['experience_levels']),
      energyLevels: labels(json['energy_levels']),
      minMinutes: _intOr(time['min'], 10),
      maxMinutes: _intOr(time['max'], 180),
      lastInputs: BuilderInputs.fromServer(
        (json['last_inputs'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      suggestedMuscles: [
        for (final m in (json['suggested_muscles'] as List? ?? const []))
          SuggestedMuscle.fromJson((m as Map).cast<String, dynamic>()),
      ],
    );
  }

  final Map<String, String> muscles;
  final Map<String, String> equipment;
  final Map<String, String> goals;
  final Map<String, String> experienceLevels;
  final Map<String, String> energyLevels;
  final int minMinutes;
  final int maxMinutes;
  final BuilderInputs lastInputs;
  final List<SuggestedMuscle> suggestedMuscles;
}

/// One exercise in a generated workout.
class GuidedExercise {
  const GuidedExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.instructions,
    this.equipment = const [],
    this.muscleGroup,
    this.difficulty,
    required this.targetSets,
    required this.targetReps,
    this.targetWeightKg,
    required this.restSeconds,
    this.suggestedWeightProgression,
    this.reason,
    required this.order,
    this.plateau = false,
  });

  factory GuidedExercise.fromJson(Map<String, dynamic> json) => GuidedExercise(
        id: _intOr(json['id'], 0),
        exerciseId: _intOr(json['exercise_id'], 0),
        name: json['name'] as String? ?? 'Exercise',
        instructions: json['instructions'] as String?,
        equipment: _stringList(json['equipment']),
        muscleGroup: json['muscle_group'] as String?,
        difficulty: json['difficulty'] as String?,
        targetSets: _intOr(json['target_sets'], 3),
        targetReps: _intOr(json['target_reps'], 10),
        targetWeightKg: _numOrNull(json['target_weight_kg']),
        restSeconds: _intOr(json['rest_seconds'], 90),
        suggestedWeightProgression: json['suggested_weight_progression'] as String?,
        reason: json['reason'] as String?,
        order: _intOr(json['order'], 0),
        plateau: json['plateau'] == true,
      );

  final int id;
  final int exerciseId;
  final String name;
  final String? instructions;
  final List<String> equipment;
  final String? muscleGroup;
  final String? difficulty;
  final int targetSets;
  final int targetReps;
  final num? targetWeightKg;
  final int restSeconds;
  final String? suggestedWeightProgression;
  final String? reason;
  final int order;
  final bool plateau;
}

/// `GET /member/guided-workout/{id}` and `POST …/generate`.
class GuidedWorkout {
  const GuidedWorkout({
    required this.id,
    this.explanation,
    this.estimatedDurationMinutes,
    this.status,
    this.templateName,
    this.sessionId,
    this.exercises = const [],
  });

  factory GuidedWorkout.fromJson(Map<String, dynamic> json) => GuidedWorkout(
        id: _intOr(json['id'], 0),
        explanation: json['explanation'] as String?,
        estimatedDurationMinutes: _numOrNull(json['estimated_duration_minutes'])?.round(),
        status: json['status'] as String?,
        templateName: json['template_name'] as String?,
        sessionId: _numOrNull(json['session_id'])?.round(),
        exercises: [
          for (final e in (json['exercises'] as List? ?? const []))
            GuidedExercise.fromJson((e as Map).cast<String, dynamic>()),
        ]..sort((a, b) => a.order.compareTo(b.order)),
      );

  final int id;
  final String? explanation;
  final int? estimatedDurationMinutes;
  final String? status;
  final String? templateName;
  final int? sessionId;
  final List<GuidedExercise> exercises;

  bool get started => status == 'in_progress' || status == 'completed';
}

class ExerciseAlternative {
  const ExerciseAlternative({
    required this.id,
    required this.name,
    this.difficulty,
    this.equipment = const [],
    this.muscleGroup,
  });

  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) => ExerciseAlternative(
        id: _intOr(json['id'], 0),
        name: json['name'] as String? ?? 'Exercise',
        difficulty: json['difficulty'] as String?,
        equipment: _stringList(json['equipment']),
        muscleGroup: json['muscle_group'] as String?,
      );

  final int id;
  final String name;
  final String? difficulty;
  final List<String> equipment;
  final String? muscleGroup;
}

/// `POST /member/guided-workout/interpret`.
class InterpretResult {
  const InterpretResult({required this.inputs, required this.confidence, this.message});

  factory InterpretResult.fromJson(Map<String, dynamic> json) => InterpretResult(
        inputs: BuilderInputs.fromServer((json['inputs'] as Map).cast<String, dynamic>()),
        confidence: (_numOrNull(json['confidence']) ?? 0.5).toDouble(),
        message: json['message'] as String?,
      );

  final BuilderInputs inputs;
  final double confidence;
  final String? message;
}
