import 'package:intl/intl.dart';

import '../../data/repositories/workouts_repository.dart';

/// Muscle groups a workout can focus on, in the web's order. Values are the
/// backend's.
const muscleGroups = <(String, String)>[
  ('chest', 'Chest'),
  ('back_lats', 'Lats & upper back'),
  ('back_lower', 'Lower back'),
  ('shoulders', 'Shoulders'),
  ('biceps', 'Biceps'),
  ('triceps', 'Triceps'),
  ('forearms', 'Forearms'),
  ('legs', 'Legs'),
  ('quads', 'Quads'),
  ('hamstrings', 'Hamstrings'),
  ('glutes', 'Glutes'),
  ('calves', 'Calves'),
  ('core', 'Core'),
  ('cardio', 'Cardio'),
  ('full_body', 'Full body'),
];

String muscleLabel(String? value) =>
    muscleGroups.where((m) => m.$1 == value).map((m) => m.$2).firstOrNull ?? 'Workout';

/// "Legs" is a session focus only; exercises are tagged with the parts.
Set<String> exerciseGroupsFor(String muscleGroup) => muscleGroup == 'legs'
    ? const {'quads', 'hamstrings', 'glutes', 'calves'}
    : {muscleGroup};

bool isCardio(String? muscleGroup) => muscleGroup == 'cardio';

final _kg = NumberFormat('#,##0.##', 'en_KE');

String formatKg(double kg) => '${_kg.format(kg)} kg';

/// "60 kg × 8", "12 reps", "30 min · 5 km", with " · RPE 8" when given.
String formatSet(SetValues v) {
  final parts = <String>[
    if (v.weight != null && v.reps != null)
      '${formatKg(v.weight!)} × ${v.reps}'
    else if (v.reps != null)
      '${v.reps} reps'
    else if (v.weight != null)
      formatKg(v.weight!),
    if (v.durationMinutes != null) '${v.durationMinutes} min',
    if (v.distanceKm != null) '${_kg.format(v.distanceKm)} km',
    if (v.rpe != null) 'RPE ${v.rpe}',
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// "1 set", "3 sets".
String plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

String formatDuration(int minutes) =>
    minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${minutes % 60} min';

String ratingLabel(String? rating) => switch (rating) {
      'great' => 'Great',
      'good' => 'Good',
      'okay' => 'Okay',
      'tough' => 'Tough',
      _ => '',
    };

/// "Estimated 1RM 78.75 kg", "Heaviest for 5 reps: 70 kg".
String recordLabel(String metricType, double value, int? reps) => switch (metricType) {
      'max_weight_1rm' => 'Estimated 1RM ${formatKg(value)}',
      'max_weight_at_reps' => 'Heaviest for ${reps ?? '?'} reps: ${formatKg(value)}',
      'max_reps_at_weight' => 'Most reps at ${formatKg(value)}: ${reps ?? '?'}',
      'max_distance' => 'Longest distance: ${_kg.format(value)} km',
      'max_duration' => 'Longest time: ${value.round()} min',
      _ => formatKg(value),
    };
