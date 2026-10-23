import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/classes_repository.dart';
import '../../../data/sync/sync.dart';

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Upcoming classes from the local table, including ones that started but
/// have not ended yet.
final classesProvider = StreamProvider.autoDispose<List<ClassSession>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref.watch(classesRepositoryProvider).watchFrom(startOfDay(now));
});

final classesFetchedAtProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(classesRepositoryProvider).watchFetchedAt(),
);

final pendingSyncCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(outboxServiceProvider).watchPendingCount(),
);

class ClassesRefreshController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(classesRepositoryProvider).refresh(ref.read(clockProvider)());
      if (ref.mounted) state = const AsyncData(null);
      // Back online: send anything queued.
      ref.read(outboxServiceProvider).drain();
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

final classesRefreshProvider =
    NotifierProvider.autoDispose<ClassesRefreshController, AsyncValue<void>>(
  ClassesRefreshController.new,
);

/// What the member sees for one class, combining the server's view with
/// any change still waiting in the outbox.
enum BookingView { open, full, started, booked, bookPending, cancelPending, bookFailed, cancelFailed }

BookingView bookingView(ClassSession c, DateTime now) => switch (c.localState) {
      LocalBookingState.bookPending => BookingView.bookPending,
      LocalBookingState.cancelPending => BookingView.cancelPending,
      LocalBookingState.bookFailed => BookingView.bookFailed,
      LocalBookingState.cancelFailed => BookingView.cancelFailed,
      _ when c.booked => BookingView.booked,
      _ when !c.startsAt.isAfter(now) => BookingView.started,
      _ when c.isFull => BookingView.full,
      _ => BookingView.open,
    };

/// Counts as booked for the "My bookings" filter: confirmed or on its way.
bool countsAsMine(ClassSession c) =>
    c.localState == LocalBookingState.bookPending ||
    c.localState == LocalBookingState.cancelPending ||
    c.localState == LocalBookingState.cancelFailed ||
    (c.booked && c.localState == LocalBookingState.none);
