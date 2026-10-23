import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/dto/dashboard_dto.dart';
import '../../../data/repositories/dashboard_repository.dart';

/// Cached dashboard; null until the first successful refresh.
final dashboardCacheProvider = StreamProvider.autoDispose<Cached<DashboardDto>?>(
  (ref) => ref.watch(dashboardRepositoryProvider).watchDashboard(),
);

/// Cached membership card with the QR payload. Shared with profile and
/// check-in, so it is not auto-disposed.
final memberCardProvider = StreamProvider<Cached<MemberCardDto>?>(
  (ref) => ref.watch(dashboardRepositoryProvider).watchMemberCard(),
);

/// Background refresh status. Data itself always comes from the cache.
class DashboardRefreshController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(dashboardRepositoryProvider).refresh();
      if (ref.mounted) state = const AsyncData(null);
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

final dashboardRefreshProvider =
    NotifierProvider.autoDispose<DashboardRefreshController, AsyncValue<void>>(
  DashboardRefreshController.new,
);
