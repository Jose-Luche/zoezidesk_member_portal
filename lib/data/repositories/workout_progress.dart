/// Progress numbers from GET /workouts/progress and
/// /workouts/progress/{muscle}, the same as the web Analytics pages.
library;

double? _d(Object? v) => (v as num?)?.toDouble();
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
List<double?> _series(Object? v) => [for (final x in _list(v)) _d(x)];

/// A JSON list; PHP sends an object when a collection kept its keys.
List<Object?> _list(Object? v) => switch (v) {
      List() => v,
      Map() => v.values.toList(),
      _ => const [],
    };

class PeriodTotals {
  const PeriodTotals({this.sessions = 0, this.sets = 0, this.volume = 0, this.prs = 0});

  factory PeriodTotals.fromJson(Map<String, dynamic>? j) => j == null
      ? const PeriodTotals()
      : PeriodTotals(sessions: _i(j['sessions']), sets: _i(j['sets']), volume: _i(j['volume']), prs: _i(j['prs']));

  final int sessions;
  final int sets;

  /// Weight × reps, in kg.
  final int volume;
  final int prs;
}

class TopExercise {
  const TopExercise({required this.name, required this.volume, required this.sets, this.muscleGroup});

  final String name;
  final String? muscleGroup;
  final int volume;
  final int sets;
}

/// One muscle in the balance overview.
class MuscleStatus {
  const MuscleStatus({
    required this.key,
    required this.label,
    required this.status,
    required this.statusLabel,
    required this.setsThisWeek,
    required this.volumeStatus,
    required this.weeklySets,
    this.strengthChange,
    this.lastTrained,
    this.daysSince,
  });

  factory MuscleStatus.fromJson(Map<String, dynamic> j) => MuscleStatus(
        key: '${j['key']}',
        label: '${j['label']}',
        status: '${j['status']}',
        statusLabel: '${j['status_label']}',
        strengthChange: _d(j['strength_change']),
        setsThisWeek: _i(j['sets_this_week']),
        volumeStatus: '${j['volume_status']}',
        weeklySets: _series(j['weekly_sets']),
        lastTrained: DateTime.tryParse('${j['last_trained']}'),
        daysSince: (j['days_since'] as num?)?.toInt(),
      );

  final String key;
  final String label;

  /// progressing, plateau, declining, neglected, building or no_data
  final String status;
  final String statusLabel;

  /// Estimated-strength change, in percent, over recent weeks.
  final double? strengthChange;
  final int setsThisWeek;

  /// below, within or above the weekly set target for the member's goal
  final String volumeStatus;
  final List<double?> weeklySets;
  final DateTime? lastTrained;
  final int? daysSince;
}

class ProgressSummary {
  const ProgressSummary({
    required this.allTime,
    required this.thisMonth,
    required this.streak,
    required this.volumePerSession,
    required this.setsPerSession,
    required this.topExercises,
    required this.muscles,
    required this.targetSets,
    required this.weekLabels,
    required this.hasMuscleData,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) {
    final m = (j['muscles'] as Map?)?.cast<String, dynamic>() ?? const {};
    final avg = (j['averages'] as Map?)?.cast<String, dynamic>() ?? const {};
    final target = (m['target_sets'] as List?) ?? const [0, 0];
    return ProgressSummary(
      allTime: PeriodTotals.fromJson((j['all_time'] as Map?)?.cast<String, dynamic>()),
      thisMonth: PeriodTotals.fromJson((j['this_month'] as Map?)?.cast<String, dynamic>()),
      streak: _i(j['streak']),
      volumePerSession: _i(avg['volume_per_session']),
      setsPerSession: _d(avg['sets_per_session']) ?? 0,
      topExercises: [
        for (final e in _list(j['top_exercises']))
          TopExercise(
            name: '${(e as Map)['name']}',
            muscleGroup: e['muscle_group'] as String?,
            volume: _i(e['volume']),
            sets: _i(e['sets']),
          ),
      ],
      muscles: [
        for (final x in _list(m['items'])) MuscleStatus.fromJson((x as Map).cast<String, dynamic>()),
      ],
      targetSets: (_i(target.first), _i(target.last)),
      weekLabels: [for (final l in (m['week_labels'] as List? ?? const [])) '$l'],
      hasMuscleData: m['has_data'] == true,
    );
  }

  final PeriodTotals allTime;
  final PeriodTotals thisMonth;

  /// Consecutive days with a finished workout, ending today or yesterday.
  final int streak;
  final int volumePerSession;
  final double setsPerSession;
  final List<TopExercise> topExercises;
  final List<MuscleStatus> muscles;

  /// Weekly working-set range for the member's goal.
  final (int, int) targetSets;
  final List<String> weekLabels;
  final bool hasMuscleData;
}

class MuscleExercise {
  const MuscleExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.sessions,
    required this.bestSet,
    required this.usesWeight,
    required this.weeklyBest,
    this.bestE1rm,
    this.change,
    this.lastDate,
  });

  factory MuscleExercise.fromJson(Map<String, dynamic> j) => MuscleExercise(
        id: _i(j['id']),
        name: '${j['name']}',
        sets: _i(j['sets']),
        sessions: _i(j['sessions']),
        lastDate: DateTime.tryParse('${j['last_date']}'),
        bestSet: '${j['best_set'] ?? '—'}',
        bestE1rm: _d(j['best_e1rm']),
        usesWeight: j['uses_weight'] == true,
        change: _d(j['change']),
        weeklyBest: _series(j['weekly_best']),
      );

  final int id;
  final String name;
  final int sets;
  final int sessions;
  final DateTime? lastDate;
  final String bestSet;
  final double? bestE1rm;
  final bool usesWeight;

  /// Strength change, in percent.
  final double? change;

  /// Best estimated 1RM (or reps, for bodyweight) per week; null = not done.
  final List<double?> weeklyBest;
}

class MuscleDetail {
  const MuscleDetail({
    required this.muscle,
    required this.targetSets,
    required this.weekLabels,
    required this.weeklyVolume,
    required this.exercises,
    required this.prs,
  });

  factory MuscleDetail.fromJson(Map<String, dynamic> j) {
    final target = (j['target_sets'] as List?) ?? const [0, 0];
    return MuscleDetail(
      muscle: MuscleStatus.fromJson((j['muscle'] as Map).cast<String, dynamic>()),
      targetSets: (_i(target.first), _i(target.last)),
      weekLabels: [for (final l in (j['week_labels'] as List? ?? const [])) '$l'],
      weeklyVolume: _series(j['weekly_volume']),
      exercises: [
        for (final e in _list(j['exercises'])) MuscleExercise.fromJson((e as Map).cast<String, dynamic>()),
      ],
      prs: [
        for (final p in _list(j['prs']))
          (
            exercise: '${(p as Map)['exercise']}',
            description: '${p['description']}',
            date: DateTime.tryParse('${p['date'] ?? p['logged_at']}'),
          ),
      ],
    );
  }

  final MuscleStatus muscle;
  final (int, int) targetSets;
  final List<String> weekLabels;
  final List<double?> weeklyVolume;
  final List<MuscleExercise> exercises;
  final List<({String exercise, String description, DateTime? date})> prs;
}
