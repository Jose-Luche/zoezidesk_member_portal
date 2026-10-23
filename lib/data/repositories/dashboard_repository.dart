import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/clock.dart';
import '../api/dashboard_api.dart';
import '../db/encrypted_cache.dart';
import '../dto/dashboard_dto.dart';

/// Offline-first: screens read from the local cache; [refresh] updates it
/// from the API. The membership card (QR) is cached separately because the
/// profile and check-in screens show it too.
class DashboardRepository {
  const DashboardRepository({
    required this._api,
    required this._cache,
    required this._clock,
  });

  static const dashboardKey = 'dashboard';
  static const memberCardKey = 'member_card';

  final DashboardApi _api;
  final EncryptedCache _cache;
  final DateTime Function() _clock;

  Stream<Cached<DashboardDto>?> watchDashboard() => _cache
      .watch(dashboardKey)
      .map((c) => c?.map(DashboardDto.fromJson));

  Stream<Cached<MemberCardDto>?> watchMemberCard() => _cache
      .watch(memberCardKey)
      .map((c) => c?.map(MemberCardDto.fromJson));

  /// Fetches both, validates them, then stores them. Throws [AppFailure];
  /// the cache is left untouched on failure.
  Future<void> refresh() async {
    final (dashboard, card) = await guardRequest(() async {
      final results = await Future.wait([_api.dashboard(), _api.memberCard()]);
      // Parse before caching so a malformed response never replaces good data.
      DashboardDto.fromJson(results[0]);
      MemberCardDto.fromJson(results[1]);
      return (results[0], results[1]);
    });
    final now = _clock();
    await _cache.put(dashboardKey, dashboard, now);
    await _cache.put(memberCardKey, card, now);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    api: ref.watch(dashboardApiProvider),
    cache: ref.watch(encryptedCacheProvider),
    clock: ref.watch(clockProvider),
  ),
);
