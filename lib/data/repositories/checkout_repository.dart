import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../api/checkout_api.dart';

class PlanOption {
  const PlanOption({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.durationLabel,
    this.description,
  });

  factory PlanOption.fromJson(Map<String, dynamic> json) => PlanOption(
        id: (json['id'] as num).toInt(),
        name: '${json['name']}',
        price: (json['price'] as num).toInt(),
        durationDays: (json['duration_days'] as num).toInt(),
        durationLabel: '${json['duration_label'] ?? '${json['duration_days']} days'}',
        description: json['description'] as String?,
      );

  final int id;
  final String name;

  /// Whole shillings.
  final int price;
  final int durationDays;
  final String durationLabel;
  final String? description;
}

class CheckoutOptions {
  const CheckoutOptions({
    required this.mpesaEnabled,
    required this.phone,
    required this.plans,
    this.currentPlanId,
    this.currentPlanName,
    this.currentExpiresAt,
    this.pendingPaymentId,
  });

  factory CheckoutOptions.fromJson(Map<String, dynamic> json) {
    final current = (json['current'] as Map?)?.cast<String, dynamic>();
    return CheckoutOptions(
      mpesaEnabled: json['mpesa_enabled'] == true,
      phone: '${json['phone'] ?? ''}',
      plans: [
        for (final p in (json['plans'] as List? ?? const []))
          PlanOption.fromJson((p as Map).cast<String, dynamic>()),
      ],
      currentPlanId: (current?['plan_id'] as num?)?.toInt(),
      currentPlanName: current?['plan_name'] as String?,
      currentExpiresAt: DateTime.tryParse('${current?['expires_at']}'),
      pendingPaymentId: (json['pending_payment_id'] as num?)?.toInt(),
    );
  }

  final bool mpesaEnabled;

  /// The member's registered phone, the default M-Pesa number.
  final String phone;
  final List<PlanOption> plans;
  final int? currentPlanId;
  final String? currentPlanName;

  /// Last day of the active membership, if any.
  final DateTime? currentExpiresAt;

  /// A prompt sent in the last two minutes that is still unanswered.
  final int? pendingPaymentId;
}

/// Where one STK payment stands on the server.
class CheckoutStatus {
  const CheckoutStatus({
    required this.id,
    required this.status,
    this.amount,
    this.plan,
    this.receipt,
    this.failureReason,
    this.membershipStartsAt,
    this.membershipExpiresAt,
  });

  factory CheckoutStatus.fromJson(Map<String, dynamic> json) {
    final m = (json['membership'] as Map?)?.cast<String, dynamic>();
    return CheckoutStatus(
      id: (json['id'] as num).toInt(),
      status: '${json['status']}',
      amount: (json['amount'] as num?)?.toInt(),
      plan: json['plan'] as String?,
      receipt: json['receipt'] as String?,
      failureReason: json['failure_reason'] as String?,
      membershipStartsAt: DateTime.tryParse('${m?['starts_at']}'),
      membershipExpiresAt: DateTime.tryParse('${m?['expires_at']}'),
    );
  }

  final int id;

  /// pending, completed or failed
  final String status;
  final int? amount;
  final String? plan;
  final String? receipt;
  final String? failureReason;
  final DateTime? membershipStartsAt;
  final DateTime? membershipExpiresAt;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

/// Paying for a plan by M-Pesa STK push. Online only: nothing is cached or
/// queued, because a payment must never be sent late or twice.
class CheckoutRepository {
  const CheckoutRepository(this._api);

  final CheckoutApi _api;

  /// Throws [AppFailure].
  Future<CheckoutOptions> options() =>
      guardRequest(() async => CheckoutOptions.fromJson(await _api.plans()));

  /// Sends the prompt and returns the payment to watch. A prompt already
  /// pending returns that payment instead of sending another.
  /// Throws [AppFailure].
  Future<int> stkPush({
    required int planId,
    required String phone,
    required String idempotencyKey,
  }) async {
    return guardRequest(() async {
      try {
        final json = await _api.stkPush(planId: planId, phone: phone, idempotencyKey: idempotencyKey);
        return (json['payment_id'] as num).toInt();
      } on DioException catch (e) {
        final data = e.response?.data;
        if (e.response?.statusCode == 409 && data is Map && data['payment_id'] is num) {
          return (data['payment_id'] as num).toInt();
        }
        rethrow;
      }
    });
  }

  /// Throws [AppFailure].
  Future<CheckoutStatus> status(int paymentId) =>
      guardRequest(() async => CheckoutStatus.fromJson(await _api.status(paymentId)));
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(ref.watch(checkoutApiProvider)),
);
