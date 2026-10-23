import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/dto/profile_dto.dart';
import '../../../data/repositories/profile_repository.dart';

final profileCacheProvider = StreamProvider.autoDispose<Cached<ProfileDto>?>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);

class ProfileRefreshController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).refresh();
      if (ref.mounted) state = const AsyncData(null);
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

final profileRefreshProvider =
    NotifierProvider.autoDispose<ProfileRefreshController, AsyncValue<void>>(
  ProfileRefreshController.new,
);
