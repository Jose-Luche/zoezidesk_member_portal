import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_dto.freezed.dart';
part 'dashboard_dto.g.dart';

/// `GET /member/dashboard`. Fields added on the `mobile-api` backend branch
/// are nullable so the app also works against a server without them.
@freezed
abstract class DashboardDto with _$DashboardDto {
  const factory DashboardDto({
    required DashboardMember member,
    MembershipInfo? membership,
    @Default([]) List<RecentPayment> recentPayments,
    @Default(0) int attendanceMonth,
    int? totalPaid,
    String? generatedAt,
  }) = _DashboardDto;

  factory DashboardDto.fromJson(Map<String, dynamic> json) =>
      _$DashboardDtoFromJson(json);
}

@freezed
abstract class DashboardMember with _$DashboardMember {
  const factory DashboardMember({
    required int id,
    required String name,
    String? memberNumber,
    String? gymName,
    String? status,
  }) = _DashboardMember;

  factory DashboardMember.fromJson(Map<String, dynamic> json) =>
      _$DashboardMemberFromJson(json);
}

@freezed
abstract class MembershipInfo with _$MembershipInfo {
  const factory MembershipInfo({
    String? planName,
    String? startsAt,
    String? expiresAt,
    String? startsAtIso,
    String? expiresAtIso,
    /// Fractional on the original API; prefer [daysRemaining].
    num? daysLeft,
    int? daysRemaining,
    int? expiryPercent,
    String? state,
  }) = _MembershipInfo;

  factory MembershipInfo.fromJson(Map<String, dynamic> json) =>
      _$MembershipInfoFromJson(json);
}

@freezed
abstract class RecentPayment with _$RecentPayment {
  const factory RecentPayment({
    required int id,
    required num amount,
    String? method,
    String? receipt,
    String? date,
    String? dateIso,
    String? plan,
  }) = _RecentPayment;

  factory RecentPayment.fromJson(Map<String, dynamic> json) =>
      _$RecentPaymentFromJson(json);
}

/// `GET /member/qr`. [qrCode] is the exact string the front-desk scanner
/// matches against.
@freezed
abstract class MemberCardDto with _$MemberCardDto {
  const factory MemberCardDto({
    required String qrCode,
    String? memberNumber,
    String? name,
    String? gymName,
  }) = _MemberCardDto;

  factory MemberCardDto.fromJson(Map<String, dynamic> json) =>
      _$MemberCardDtoFromJson(json);
}
