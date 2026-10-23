import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/payments_repository.dart';

/// How often to ask whether M-Pesa confirmed, and for how long. The prompt
/// on the phone lapses after about a minute. Overridable in tests.
final checkoutPollingProvider = Provider<({Duration every, Duration upTo})>(
  (_) => (every: const Duration(seconds: 5), upTo: const Duration(minutes: 2)),
);

enum CheckoutPhase { choosing, sending, waiting, completed, failed, timedOut }

class CheckoutState {
  const CheckoutState({
    this.options = const AsyncLoading(),
    this.planId,
    this.phone = '',
    this.phase = CheckoutPhase.choosing,
    this.paymentId,
    this.result,
    this.error,
    this.phoneError,
    this.checking = false,
  });

  final AsyncValue<CheckoutOptions> options;
  final int? planId;

  /// The M-Pesa number as typed.
  final String phone;
  final CheckoutPhase phase;
  final int? paymentId;

  /// Last status from the server while waiting, or the final one.
  final CheckoutStatus? result;

  /// Why the request could not be sent, shown on the choosing step.
  final String? error;
  final String? phoneError;

  /// A manual "Check again" is running.
  final bool checking;

  PlanOption? get plan => options.value?.plans.where((p) => p.id == planId).firstOrNull;

  CheckoutState copyWith({
    AsyncValue<CheckoutOptions>? options,
    int? planId,
    String? phone,
    CheckoutPhase? phase,
    int? paymentId,
    CheckoutStatus? result,
    String? Function()? error,
    String? Function()? phoneError,
    bool? checking,
  }) => CheckoutState(
    options: options ?? this.options,
    planId: planId ?? this.planId,
    phone: phone ?? this.phone,
    phase: phase ?? this.phase,
    paymentId: paymentId ?? this.paymentId,
    result: result ?? this.result,
    error: error != null ? error() : this.error,
    phoneError: phoneError != null ? phoneError() : this.phoneError,
    checking: checking ?? this.checking,
  );
}

/// Pay for a plan: pick it, send the M-Pesa prompt, then watch for the
/// confirmation that the server gets from Safaricom's callback.
class CheckoutController extends Notifier<CheckoutState> {
  Timer? _poll;
  DateTime? _sentAt;

  /// One key per attempt, so a retried send after a dropped connection is
  /// answered with the first push instead of a second one.
  String? _key;

  @override
  CheckoutState build() {
    ref.onDispose(() => _poll?.cancel());
    return const CheckoutState();
  }

  CheckoutRepository get _repo => ref.read(checkoutRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(options: const AsyncLoading());
    try {
      final options = await _repo.options();
      if (!ref.mounted) return;
      final ids = options.plans.map((p) => p.id);
      final planId = ids.contains(options.currentPlanId)
          ? options.currentPlanId
          : ids.firstOrNull;
      state = state.copyWith(
        options: AsyncData(options),
        planId: planId,
        phone: state.phone.isEmpty ? formatLocalPhone(options.phone) : null,
      );
      // A prompt was already sent (e.g. the screen was closed): keep
      // watching it rather than offering to send another.
      if (options.pendingPaymentId != null) _watch(options.pendingPaymentId!);
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = state.copyWith(options: AsyncError(e, st));
    }
  }

  void selectPlan(int id) {
    if (id != state.planId) _key = null;
    state = state.copyWith(planId: id, error: () => null);
  }

  void setPhone(String phone) {
    if (normalizeKenyanPhone(phone) != normalizeKenyanPhone(state.phone)) _key = null;
    state = state.copyWith(phone: phone, phoneError: () => null, error: () => null);
  }

  Future<void> pay() async {
    final plan = state.plan;
    if (plan == null || state.phase == CheckoutPhase.sending) return;
    if (!isMpesaPhone(state.phone)) {
      state = state.copyWith(phoneError: () => 'Enter a Safaricom number, like 0712 345 678.');
      return;
    }
    state = state.copyWith(phase: CheckoutPhase.sending, error: () => null);
    _key ??= const Uuid().v4();
    try {
      final id = await _repo.stkPush(
        planId: plan.id,
        phone: normalizeKenyanPhone(state.phone),
        idempotencyKey: _key!,
      );
      if (ref.mounted) _watch(id);
    } on AppFailure catch (e) {
      if (!ref.mounted) return;
      // Offline or timed out: keep the key, the push may have gone out.
      // A definite answer from the server starts a fresh attempt next time.
      if (e is! NetworkFailure && e is! TimeoutFailure) _key = null;
      state = state.copyWith(
        phase: CheckoutPhase.choosing,
        error: () => switch (e) {
          NetworkFailure() => 'You are offline. Connect to the internet to pay.',
          ValidationFailure(:final fieldErrors) when fieldErrors.containsKey('phone') => null,
          _ => e.message,
        },
        phoneError: () => e is ValidationFailure ? e.fieldErrors['phone'] : null,
      );
    }
  }

  /// Back to the plan list after a failed or lapsed payment.
  void startOver() {
    _poll?.cancel();
    _key = null;
    state = CheckoutState(
      options: state.options,
      planId: state.planId,
      phone: state.phone,
    );
  }

  /// "Check again" after the waiting time ran out.
  Future<void> checkAgain() async {
    if (state.paymentId == null || state.checking) return;
    state = state.copyWith(checking: true);
    await _check();
    if (ref.mounted) state = state.copyWith(checking: false);
  }

  void _watch(int paymentId) {
    _sentAt = ref.read(clockProvider)();
    state = state.copyWith(phase: CheckoutPhase.waiting, paymentId: paymentId, error: () => null);
    final polling = ref.read(checkoutPollingProvider);
    _poll?.cancel();
    _poll = Timer.periodic(polling.every, (t) async {
      if (!ref.mounted || state.phase != CheckoutPhase.waiting) {
        t.cancel();
        return;
      }
      await _check();
      if (!ref.mounted || state.phase != CheckoutPhase.waiting) return;
      if (ref.read(clockProvider)().difference(_sentAt!) >= polling.upTo) {
        t.cancel();
        state = state.copyWith(phase: CheckoutPhase.timedOut);
      }
    });
  }

  Future<void> _check() async {
    try {
      final status = await _repo.status(state.paymentId!);
      if (!ref.mounted) return;
      if (status.isCompleted) {
        _poll?.cancel();
        state = state.copyWith(phase: CheckoutPhase.completed, result: status);
        unawaited(_refreshAfterPayment());
      } else if (status.isFailed) {
        _poll?.cancel();
        _key = null;
        state = state.copyWith(phase: CheckoutPhase.failed, result: status);
      } else {
        state = state.copyWith(result: status);
      }
    } on AppFailure {
      // A missed check is fine; the next one, or "Check again", follows.
    }
  }

  /// The new membership and receipt show on the dashboard and history.
  Future<void> _refreshAfterPayment() async {
    for (final refresh in [
      ref.read(dashboardRepositoryProvider).refresh,
      ref.read(paymentsRepositoryProvider).refresh,
    ]) {
      try {
        await refresh();
      } on AppFailure {
        // Picked up on the next normal refresh.
      }
    }
  }
}

final checkoutControllerProvider =
    NotifierProvider.autoDispose<CheckoutController, CheckoutState>(CheckoutController.new);
