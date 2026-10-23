import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/attendance_repository.dart';

final attendanceProvider = StreamProvider.autoDispose<List<Attendance>>(
  (ref) => ref.watch(attendanceRepositoryProvider).watchAll(),
);

final attendanceSummaryProvider =
    StreamProvider.autoDispose<AttendanceSummary?>(
      (ref) => ref.watch(attendanceRepositoryProvider).watchSummary(),
    );

final attendanceFetchedAtProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(attendanceRepositoryProvider).watchFetchedAt(),
);

/// How often the open check-in screen looks for a new scan, and for how
/// long. Overridable in tests.
final checkInPollingProvider = Provider<({Duration every, Duration upTo})>(
  (_) => (every: const Duration(seconds: 8), upTo: const Duration(minutes: 5)),
);

class CheckInState {
  const CheckInState({
    this.refresh = const AsyncData(null),
    this.hasMore = false,
    this.loadingMore = false,
    this.nextPage = 2,
    this.confirmedAt,
  });

  final AsyncValue<void> refresh;
  final bool hasMore;
  final bool loadingMore;
  final int nextPage;

  /// Set when a new check-in appears while the screen is open.
  final DateTime? confirmedAt;

  CheckInState copyWith({
    AsyncValue<void>? refresh,
    bool? hasMore,
    bool? loadingMore,
    int? nextPage,
    DateTime? confirmedAt,
  }) => CheckInState(
    refresh: refresh ?? this.refresh,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    nextPage: nextPage ?? this.nextPage,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
}

/// Loads the history and, while the screen is open, watches for the front
/// desk's scan so the member gets a confirmation on the spot.
class CheckInController extends Notifier<CheckInState> {
  Timer? _poll;
  DateTime? _openedAt;
  DateTime? _baseline;

  @override
  CheckInState build() {
    ref.onDispose(() => _poll?.cancel());
    return const CheckInState();
  }

  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);

  /// Called when the screen opens: refresh, then poll for a new scan.
  Future<void> start() async {
    _openedAt = ref.read(clockProvider)();
    _baseline = (await _repo.latest())?.checkedInAt;
    await refresh();
    final polling = ref.read(checkInPollingProvider);
    _poll?.cancel();
    _poll = Timer.periodic(polling.every, (t) {
      final elapsed = ref.read(clockProvider)().difference(_openedAt!);
      if (!ref.mounted || state.confirmedAt != null || elapsed > polling.upTo) {
        t.cancel();
        return;
      }
      refresh(quiet: true);
    });
  }

  void stop() => _poll?.cancel();

  /// [quiet] refreshes (polling) do not show a loading state or errors.
  Future<void> refresh({bool quiet = false}) async {
    if (state.refresh.isLoading) return;
    if (!quiet) state = state.copyWith(refresh: const AsyncLoading());
    try {
      final page = await _repo.refresh();
      if (!ref.mounted) return;
      state = state.copyWith(
        refresh: const AsyncData(null),
        hasMore: page.hasMore,
        nextPage: 2,
      );
      await _detectCheckIn();
    } on AppFailure catch (e, st) {
      if (ref.mounted && !quiet) {
        state = state.copyWith(refresh: AsyncError(e, st));
      }
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.loadPage(state.nextPage);
      if (ref.mounted) {
        state = state.copyWith(
          loadingMore: false,
          hasMore: page.hasMore,
          nextPage: page.page + 1,
        );
      }
    } on AppFailure {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
    }
  }

  /// A check-in newer than any known before the screen opened, made after
  /// it opened (with a minute's grace for clock drift), is this visit's.
  Future<void> _detectCheckIn() async {
    if (state.confirmedAt != null || _openedAt == null) return;
    final latest = (await _repo.latest())?.checkedInAt;
    if (latest == null) return;
    final isNew = _baseline == null || latest.isAfter(_baseline!);
    final thisVisit = latest.isAfter(
      _openedAt!.subtract(const Duration(minutes: 1)),
    );
    if (isNew && thisVisit && ref.mounted) {
      state = state.copyWith(confirmedAt: latest);
      _poll?.cancel();
    }
  }
}

final checkInControllerProvider =
    NotifierProvider.autoDispose<CheckInController, CheckInState>(
      CheckInController.new,
    );
