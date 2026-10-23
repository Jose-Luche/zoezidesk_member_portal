// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuilderInputs _$BuilderInputsFromJson(Map<String, dynamic> json) =>
    _BuilderInputs(
      energyLevel: json['energy_level'] as String? ?? 'medium',
      timeMinutes: (json['time_minutes'] as num?)?.toInt() ?? 45,
      focusMuscles:
          (json['focus_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      excludedMuscles:
          (json['excluded_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      goal: json['goal'] as String? ?? 'stay_active',
      experienceLevel: json['experience_level'] as String? ?? 'beginner',
    );

Map<String, dynamic> _$BuilderInputsToJson(_BuilderInputs instance) =>
    <String, dynamic>{
      'energy_level': instance.energyLevel,
      'time_minutes': instance.timeMinutes,
      'focus_muscles': instance.focusMuscles,
      'excluded_muscles': instance.excludedMuscles,
      'equipment': instance.equipment,
      'goal': instance.goal,
      'experience_level': instance.experienceLevel,
    };

_SuggestedMuscle _$SuggestedMuscleFromJson(Map<String, dynamic> json) =>
    _SuggestedMuscle(
      key: json['key'] as String,
      label: json['label'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$SuggestedMuscleToJson(_SuggestedMuscle instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'reason': instance.reason,
    };
