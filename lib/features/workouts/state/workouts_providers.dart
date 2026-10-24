import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../data/sync/sync.dart';

final exerciseLibraryProvider = StreamProvider.autoDispose<List<LibraryExercise>>(
  (ref) => ref.watch(workoutsRepositoryProvider).watchLibrary(),
);

final activeWorkoutProvider = StreamProvider.autoDispose<WorkoutSessionRow?>(
  (ref) => ref.watch(workoutsRepositoryProvider).watchActive(),
);

final workoutHistoryProvider = StreamProvider.autoDispose<List<WorkoutSessionRow>>(
  (ref) => ref.watch(workoutsRepositoryProvider).watchHistory(),
);

final workoutHistoryFetchedAtProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(workoutsRepositoryProvider).watchHistoryFetchedAt(),
);

final workoutSessionProvider = StreamProvider.autoDispose.family<SessionDetail?, String>(
  (ref, clientId) => ref.watch(workoutsRepositoryProvider).watchSession(clientId),
);

final personalRecordsProvider = StreamProvider.autoDispose<Cached<PersonalRecords>?>(
  (ref) => ref.watch(workoutsRepositoryProvider).watchRecords(),
);

/// Records the server finds as logged sets reach it.
final newPrProvider = StreamProvider.autoDispose<NewPr>(
  (ref) => ref.watch(workoutsRepositoryProvider).newPrs,
);

/// Refreshing a cached list, and paging through history.
class WorkoutListState {
  const WorkoutListState({
    this.refresh = const AsyncData(null),
    this.hasMore = false,
    this.loadingMore = false,
    this.nextPage = 2,
  });

  final AsyncValue<void> refresh;
  final bool hasMore;
  final bool loadingMore;
  final int nextPage;

  WorkoutListState copyWith({AsyncValue<void>? refresh, bool? hasMore, bool? loadingMore, int? nextPage}) =>
      WorkoutListState(
        refresh: refresh ?? this.refresh,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        nextPage: nextPage ?? this.nextPage,
      );
}

/// History (with paging) and, alongside it, the exercise library, so the
/// picker works offline after the first visit.
class WorkoutHistoryController extends Notifier<WorkoutListState> {
  @override
  WorkoutListState build() => const WorkoutListState();

  WorkoutsRepository get _repo => ref.read(workoutsRepositoryProvider);

  Future<void> refresh() async {
    if (state.refresh.isLoading) return;
    state = state.copyWith(refresh: const AsyncLoading());
    final repo = _repo;
    try {
      final page = await repo.refreshHistory();
      if (ref.mounted) state = state.copyWith(refresh: const AsyncData(null), hasMore: page.hasMore, nextPage: 2);
      await repo.refreshLibrary();
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = state.copyWith(refresh: AsyncError(e, st));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.loadHistoryPage(state.nextPage);
      if (ref.mounted) state = state.copyWith(loadingMore: false, hasMore: page.hasMore, nextPage: page.page + 1);
    } on AppFailure {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
    }
  }
}

final workoutHistoryControllerProvider =
    NotifierProvider.autoDispose<WorkoutHistoryController, WorkoutListState>(WorkoutHistoryController.new);

/// Background refresh of something cached; data comes from the cache.
class RefreshController extends Notifier<AsyncValue<void>> {
  RefreshController(this._run);

  final Future<void> Function(WorkoutsRepository) _run;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final repo = ref.read(workoutsRepositoryProvider);
    try {
      await _run(repo);
      if (ref.mounted) state = const AsyncData(null);
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

final recordsRefreshProvider = NotifierProvider.autoDispose<RefreshController, AsyncValue<void>>(
  () => RefreshController((r) => r.refreshRecords()),
);

final libraryRefreshProvider = NotifierProvider.autoDispose<RefreshController, AsyncValue<void>>(
  () => RefreshController((r) => r.refreshLibrary()),
);

/// Loads a past session's exercises and sets when it is opened.
final sessionDetailRefreshProvider =
    NotifierProvider.autoDispose.family<RefreshController, AsyncValue<void>, String>(
  (clientId) => RefreshController((r) => r.loadDetail(clientId)),
);
