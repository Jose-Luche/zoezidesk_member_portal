import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/dto/auth_dto.dart';
import '../../../data/repositories/auth_repository.dart';
import 'session_controller.dart';

/// Accepts what the web portal accepts: 07…, 01…, 7…, 1…, 254…, +254…
bool isPlausiblePhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 9 && digits.length <= 12;
}

/// Step 1: send a code to the phone.
class OtpRequestController extends Notifier<AsyncValue<OtpRequestResult?>> {
  @override
  AsyncValue<OtpRequestResult?> build() => const AsyncData(null);

  /// Returns true when a code was sent.
  Future<bool> submit(String phone) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final result = await ref.read(authRepositoryProvider).requestOtp(phone.trim());
      state = AsyncData(result);
      return true;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final otpRequestControllerProvider = NotifierProvider.autoDispose<
    OtpRequestController, AsyncValue<OtpRequestResult?>>(OtpRequestController.new);

/// Step 2: verify the code, or ask for a new one.
class OtpVerifyController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> verify({required String phone, required String code}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final member = await ref
          .read(authRepositoryProvider)
          .verifyOtp(phone: phone.trim(), code: code);
      if (!ref.mounted) return;
      state = const AsyncData(null);
      ref.read(sessionControllerProvider.notifier).signedIn(member);
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }

  /// Returns the new request result, or null if it failed (state holds why).
  Future<OtpRequestResult?> resend(String phone) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final result = await ref.read(authRepositoryProvider).requestOtp(phone.trim());
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return null;
    }
  }
}

final otpVerifyControllerProvider =
    NotifierProvider.autoDispose<OtpVerifyController, AsyncValue<void>>(
  OtpVerifyController.new,
);
