// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardDto _$DashboardDtoFromJson(Map<String, dynamic> json) =>
    _DashboardDto(
      member: DashboardMember.fromJson(json['member'] as Map<String, dynamic>),
      membership: json['membership'] == null
          ? null
          : MembershipInfo.fromJson(json['membership'] as Map<String, dynamic>),
      recentPayments:
          (json['recent_payments'] as List<dynamic>?)
              ?.map((e) => RecentPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      attendanceMonth: (json['attendance_month'] as num?)?.toInt() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toInt(),
      generatedAt: json['generated_at'] as String?,
    );

Map<String, dynamic> _$DashboardDtoToJson(
  _DashboardDto instance,
) => <String, dynamic>{
  'member': instance.member.toJson(),
  'membership': instance.membership?.toJson(),
  'recent_payments': instance.recentPayments.map((e) => e.toJson()).toList(),
  'attendance_month': instance.attendanceMonth,
  'total_paid': instance.totalPaid,
  'generated_at': instance.generatedAt,
};

_DashboardMember _$DashboardMemberFromJson(Map<String, dynamic> json) =>
    _DashboardMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      memberNumber: json['member_number'] as String?,
      gymName: json['gym_name'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$DashboardMemberToJson(_DashboardMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'member_number': instance.memberNumber,
      'gym_name': instance.gymName,
      'status': instance.status,
    };

_MembershipInfo _$MembershipInfoFromJson(Map<String, dynamic> json) =>
    _MembershipInfo(
      planName: json['plan_name'] as String?,
      startsAt: json['starts_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      startsAtIso: json['starts_at_iso'] as String?,
      expiresAtIso: json['expires_at_iso'] as String?,
      daysLeft: json['days_left'] as num?,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      expiryPercent: (json['expiry_percent'] as num?)?.toInt(),
      state: json['state'] as String?,
    );

Map<String, dynamic> _$MembershipInfoToJson(_MembershipInfo instance) =>
    <String, dynamic>{
      'plan_name': instance.planName,
      'starts_at': instance.startsAt,
      'expires_at': instance.expiresAt,
      'starts_at_iso': instance.startsAtIso,
      'expires_at_iso': instance.expiresAtIso,
      'days_left': instance.daysLeft,
      'days_remaining': instance.daysRemaining,
      'expiry_percent': instance.expiryPercent,
      'state': instance.state,
    };

_RecentPayment _$RecentPaymentFromJson(Map<String, dynamic> json) =>
    _RecentPayment(
      id: (json['id'] as num).toInt(),
      amount: json['amount'] as num,
      method: json['method'] as String?,
      receipt: json['receipt'] as String?,
      date: json['date'] as String?,
      dateIso: json['date_iso'] as String?,
      plan: json['plan'] as String?,
    );

Map<String, dynamic> _$RecentPaymentToJson(_RecentPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'method': instance.method,
      'receipt': instance.receipt,
      'date': instance.date,
      'date_iso': instance.dateIso,
      'plan': instance.plan,
    };

_MemberCardDto _$MemberCardDtoFromJson(Map<String, dynamic> json) =>
    _MemberCardDto(
      qrCode: json['qr_code'] as String,
      memberNumber: json['member_number'] as String?,
      name: json['name'] as String?,
      gymName: json['gym_name'] as String?,
    );

Map<String, dynamic> _$MemberCardDtoToJson(_MemberCardDto instance) =>
    <String, dynamic>{
      'qr_code': instance.qrCode,
      'member_number': instance.memberNumber,
      'name': instance.name,
      'gym_name': instance.gymName,
    };
