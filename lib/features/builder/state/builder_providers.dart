import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../data/repositories/builder_repository.dart';

final builderOptionsProvider = StreamProvider.autoDispose<Cached<BuilderOptions>?>(
  (ref) => ref.watch(builderRepositoryProvider).watchOptions(),
);

/// The most recently generated workout, kept for offline viewing.
final builderWorkoutProvider = StreamProvider.autoDispose<Cached<GuidedWorkout>?>(
  (ref) => ref.watch(builderRepositoryProvider).watchWorkout(),
);

/// Same steps as the web GuidedWorkoutFlow.
enum BuilderStep { energy, time, focus, exclude, equipment, goal, experience }

class BuilderFormState {
  const BuilderFormState({
    this.step = BuilderStep.energy,
    this.inputs = const BuilderInputs(),
    this.seeded = false,
    this.reviewNotice,
  });

  final BuilderStep step;
  final BuilderInputs inputs;

  /// Defaults from the member's last answers have been applied.
  final bool seeded;

  /// Shown after a low-confidence description filled in the answers.
  final String? reviewNotice;

  bool get isLast => step == BuilderStep.experience;
  int get number => step.index + 1;
  static int get count => BuilderStep.values.length;

  /// Mirrors GuidedWorkoutFlow::validateCurrentStep.
  bool get canAdvance => switch (step) {
        BuilderStep.time => inputs.timeMinutes >= 10 && inputs.timeMinutes <= 180,
        BuilderStep.focus => inputs.focusMuscles.isNotEmpty,
        _ => true,
      };

  BuilderFormState copyWith({
    BuilderStep? step,
    BuilderInputs? inputs,
    bool? seeded,
    String? reviewNotice,
    bool clearNotice = false,
  }) =>
      BuilderFormState(
        step: step ?? this.step,
        inputs: inputs ?? this.inputs,
        seeded: seeded ?? this.seeded,
        reviewNotice: clearNotice ? null : reviewNotice ?? this.reviewNotice,
      );
}

List<String> _toggle(List<String> list, String value) =>
    list.contains(value) ? [...list.where((v) => v != value)] : [...list, value];

/// Normalises answers the way GuidedWorkoutFlow::applyInputs does: Full
/// Body is dropped when specific muscles are also chosen.
BuilderInputs normaliseInputs(BuilderInputs i) => i.focusMuscles.length > 1
    ? i.copyWith(focusMuscles: [...i.focusMuscles.where((m) => m != 'full_body')])
    : i;

class BuilderFormController extends Notifier<BuilderFormState> {
  @override
  BuilderFormState build() => const BuilderFormState();

  /// Apply the member's last answers once, when options first load.
  void seed(BuilderInputs defaults) {
    if (state.seeded) return;
    state = state.copyWith(inputs: normaliseInputs(defaults), seeded: true);
  }

  void _set(BuilderInputs inputs) => state = state.copyWith(inputs: inputs, clearNotice: true);

  void setEnergy(String v) => _set(state.inputs.copyWith(energyLevel: v));
  void setTime(int minutes) => _set(state.inputs.copyWith(timeMinutes: minutes.clamp(10, 180)));
  void setGoal(String v) => _set(state.inputs.copyWith(goal: v));
  void setExperience(String v) => _set(state.inputs.copyWith(experienceLevel: v));

  /// Full Body is exclusive of specific muscle groups (web rule).
  void toggleFocus(String muscle) {
    final current = state.inputs.focusMuscles;
    final base = muscle == 'full_body'
        ? current.where((m) => m == 'full_body').toList()
        : current.where((m) => m != 'full_body').toList();
    _set(state.inputs.copyWith(focusMuscles: _toggle(base, muscle)));
  }

  void toggleExcluded(String muscle) =>
      _set(state.inputs.copyWith(excludedMuscles: _toggle(state.inputs.excludedMuscles, muscle)));

  void toggleEquipment(String item) =>
      _set(state.inputs.copyWith(equipment: _toggle(state.inputs.equipment, item)));

  void next() {
    if (!state.canAdvance || state.isLast) return;
    state = state.copyWith(step: BuilderStep.values[state.step.index + 1]);
  }

  void back() {
    if (state.step.index == 0) return;
    state = state.copyWith(step: BuilderStep.values[state.step.index - 1]);
  }

  /// A low-confidence description: fill the answers and land on the last
  /// step so the member reviews them (web behaviour).
  void review(BuilderInputs interpreted) => state = state.copyWith(
        inputs: normaliseInputs(interpreted),
        step: BuilderStep.experience,
        reviewNotice: 'We filled in your answers from the description. Check them, then build.',
      );
}

final builderFormProvider =
    NotifierProvider.autoDispose<BuilderFormController, BuilderFormState>(BuilderFormController.new);

/// Outcome of building from a description.
sealed class DescribeOutcome {
  const DescribeOutcome();
}

class Built extends DescribeOutcome {
  const Built(this.workout);
  final GuidedWorkout workout;
}

class NeedsReview extends DescribeOutcome {
  const NeedsReview(this.inputs);
  final BuilderInputs inputs;
}

/// Server calls for building. Generation runs on the server: online only.
class BuilderActions extends Notifier<AsyncValue<void>> {
  static const autoBuildConfidence = 0.85;
  static const minPromptLength = 10;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final result = await action();
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return null;
    }
  }

  /// Refreshes the form options. On failure, cached options (if any) keep
  /// the form usable and the error tells the member building needs a
  /// connection.
  Future<void> loadOptions() async {
    try {
      await ref.read(builderRepositoryProvider).refreshOptions();
      if (ref.mounted && !state.isLoading) state = const AsyncData(null);
    } on AppFailure catch (e, st) {
      if (ref.mounted && !state.isLoading) state = AsyncError(e, st);
    }
  }

  Future<GuidedWorkout?> generate(BuilderInputs inputs) =>
      _run(() => ref.read(builderRepositoryProvider).generate(normaliseInputs(inputs)));

  /// Interprets a free-text description. High confidence builds straight
  /// away; otherwise the answers go back to the form for review.
  Future<DescribeOutcome?> describe(String prompt) {
    final text = prompt.trim();
    if (text.length < minPromptLength) {
      state = AsyncError(
        const ValidationFailure('Describe your workout in a bit more detail.'),
        StackTrace.current,
      );
      return Future.value();
    }
    return _run(() async {
      final repo = ref.read(builderRepositoryProvider);
      final InterpretResult result;
      try {
        result = await repo.interpret(text);
      } on ServerFailure {
        throw const ServerFailure(
          'Could not understand that description. Try the step-by-step form.',
        );
      }
      if (result.confidence >= autoBuildConfidence) {
        return Built(await repo.generate(normaliseInputs(result.inputs)));
      }
      return NeedsReview(result.inputs);
    });
  }
}

final builderActionsProvider =
    NotifierProvider.autoDispose<BuilderActions, AsyncValue<void>>(BuilderActions.new);

/// Edits to a generated workout. Online only; each edit re-reads the
/// workout from the server.
class WorkoutEditor extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> _run(Future<void> Function(BuilderRepository repo) action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await action(ref.read(builderRepositoryProvider));
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> swap(GuidedWorkout w, GuidedExercise e, ExerciseAlternative to) =>
      _run((r) => r.swap(w.id, e.id, to.id));

  Future<bool> remove(GuidedWorkout w, GuidedExercise e) => _run((r) => r.remove(w.id, e.id));

  /// Moves the exercise at [index] by [delta] (-1 up, +1 down).
  Future<bool> move(GuidedWorkout w, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= w.exercises.length) return Future.value(false);
    final ids = [for (final e in w.exercises) e.id];
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    return _run((r) => r.reorder(w.id, ids));
  }

  Future<bool> saveTemplate(GuidedWorkout w, String name) =>
      _run((r) => r.saveTemplate(w.id, name.trim()));

  Future<bool> start(GuidedWorkout w) {
    if (w.exercises.isEmpty) {
      state = AsyncError(
        const ValidationFailure('Add at least one exercise before starting.'),
        StackTrace.current,
      );
      return Future.value(false);
    }
    return _run((r) => r.startSession(w.id));
  }
}

final workoutEditorProvider =
    NotifierProvider.autoDispose<WorkoutEditor, AsyncValue<void>>(WorkoutEditor.new);

/// Swap candidates for one exercise, loaded when the swap sheet opens.
final alternativesProvider = FutureProvider.autoDispose
    .family<List<ExerciseAlternative>, (int workoutId, int guidedExerciseId)>(
  (ref, key) => ref.watch(builderRepositoryProvider).alternatives(key.$1, key.$2),
);
