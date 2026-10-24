import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/sync/sync.dart';

final foodCatalogueProvider = StreamProvider.autoDispose<List<FoodItem>>(
  (ref) => ref.watch(nutritionRepositoryProvider).watchFoods(),
);

final diaryDayProvider = StreamProvider.autoDispose.family<List<DiaryEntry>, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).watchDay(day),
);

final diaryDayFetchedAtProvider = StreamProvider.autoDispose.family<DateTime?, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).watchDayFetchedAt(day),
);

final nutritionGoalProvider = StreamProvider.autoDispose<Cached<GoalSettings>?>(
  (ref) => ref.watch(nutritionRepositoryProvider).watchGoal(),
);

class DiaryState {
  const DiaryState({required this.day, this.refresh = const AsyncData(null)});

  final DateTime day;
  final AsyncValue<void> refresh;

  DiaryState copyWith({DateTime? day, AsyncValue<void>? refresh}) =>
      DiaryState(day: day ?? this.day, refresh: refresh ?? this.refresh);
}

/// The day being viewed (today or earlier, as on the web) and its refresh.
/// A refresh fetches the week up to that day, so recent days read offline.
class DiaryController extends Notifier<DiaryState> {
  @override
  DiaryState build() {
    final now = ref.read(clockProvider)();
    return DiaryState(day: DateTime(now.year, now.month, now.day));
  }

  DateTime get _today {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  bool get canGoForward => state.day.isBefore(_today);

  void previousDay() => _go(DateTime(state.day.year, state.day.month, state.day.day - 1));

  void nextDay() {
    if (canGoForward) _go(DateTime(state.day.year, state.day.month, state.day.day + 1));
  }

  void _go(DateTime day) {
    state = DiaryState(day: day);
    refresh();
  }

  Future<void> refresh() async {
    if (state.refresh.isLoading) return;
    final repo = ref.read(nutritionRepositoryProvider);
    final day = state.day;
    state = state.copyWith(refresh: const AsyncLoading());
    try {
      await repo.refreshDays(DateTime(day.year, day.month, day.day - 6), day);
      if (ref.mounted && state.day == day) state = state.copyWith(refresh: const AsyncData(null));
      await repo.refreshFoods();
    } on AppFailure catch (e, st) {
      if (ref.mounted && state.day == day) state = state.copyWith(refresh: AsyncError(e, st));
    }
  }
}

final diaryControllerProvider = NotifierProvider.autoDispose<DiaryController, DiaryState>(DiaryController.new);

/// Saving the goal (online only) and refreshing it.
class GoalController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh() async {
    final repo = ref.read(nutritionRepositoryProvider);
    try {
      await repo.refreshGoal();
    } on AppFailure {
      // The cached goal stays; the screen says it may be out of date.
    }
  }

  /// Returns true when saved.
  Future<bool> save(NutritionGoalInfo goal) async {
    if (state.isLoading) return false;
    final repo = ref.read(nutritionRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.setGoal(goal);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
  }
}

final goalControllerProvider = NotifierProvider.autoDispose<GoalController, AsyncValue<void>>(GoalController.new);
