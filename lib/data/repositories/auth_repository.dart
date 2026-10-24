import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/storage/local_data_wiper.dart';
import '../../core/storage/session_storage.dart';
import '../api/auth_api.dart';
import '../dto/auth_dto.dart';
import '../dto/member_summary.dart';

class AuthRepository {
  const AuthRepository({
    required this._api,
    required this._storage,
    required this._wiper,
    this.deviceName = 'ZoeziDesk Android',
  });

  final AuthApi _api;
  final SessionStorage _storage;
  final LocalDataWiper _wiper;
  final String deviceName;

  /// Throws [AppFailure].
  Future<OtpRequestResult> requestOtp(String phone) =>
      guardRequest(() => _api.requestOtp(phone));

  /// Verifies the code and stores the session. Throws [AppFailure].
  Future<MemberSummary> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final result = await guardRequest(
      () => _api.verifyOtp(phone: phone, code: code, deviceName: deviceName),
    );
    await _storage.save(
      token: result.token,
      refreshToken: result.refreshToken,
      member: result.member,
    );
    return result.member;
  }

  /// The stored member, or null when signed out. A half-written or
  /// unreadable session is wiped rather than trusted.
  Future<MemberSummary?> restoreSession() async {
    try {
      final token = await _storage.readToken();
      if (token == null || token.isEmpty) return null;
      final member = await _storage.readMember();
      if (member != null) return member;
    } catch (_) {
      // Corrupt secure storage (e.g. after a device restore): start fresh.
    }
    await _wiper.wipeAll();
    return null;
  }

  /// Best-effort server revoke, then always wipe local data. Offline, the
  /// server session stays valid until its refresh token expires.
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      await _api.logout(refreshToken: refreshToken).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Logging out must work offline.
    }
    await _wiper.wipeAll();
  }

  /// Local wipe only, for when the server has already rejected the token.
  Future<void> discardSession() => _wiper.wipeAll();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(sessionStorageProvider),
    wiper: ref.watch(localDataWiperProvider),
  ),
);
