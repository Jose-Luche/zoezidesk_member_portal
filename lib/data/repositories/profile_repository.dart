import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/clock.dart';
import '../api/profile_api.dart';
import '../db/encrypted_cache.dart';
import '../dto/profile_dto.dart';

/// Read-only and server-wins: every refresh replaces the cached profile.
class ProfileRepository {
  const ProfileRepository({
    required this._api,
    required this._cache,
    required this._clock,
  });

  static const profileKey = 'profile';

  final ProfileApi _api;
  final EncryptedCache _cache;
  final DateTime Function() _clock;

  Stream<Cached<ProfileDto>?> watchProfile() =>
      _cache.watch(profileKey).map((c) => c?.map(ProfileDto.fromJson));

  /// Throws [AppFailure]; the cache is left untouched on failure.
  Future<void> refresh() async {
    final json = await guardRequest(() async {
      final json = await _api.profile();
      ProfileDto.fromJson(json); // validate before caching
      return json;
    });
    await _cache.put(profileKey, json, _clock());
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    api: ref.watch(profileApiProvider),
    cache: ref.watch(encryptedCacheProvider),
    clock: ref.watch(clockProvider),
  ),
);
