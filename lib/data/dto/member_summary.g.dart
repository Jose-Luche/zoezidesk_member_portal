// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberSummary _$MemberSummaryFromJson(Map<String, dynamic> json) =>
    _MemberSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      memberNumber: json['member_number'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gymName: json['gym_name'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$MemberSummaryToJson(_MemberSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'member_number': instance.memberNumber,
      'phone': instance.phone,
      'email': instance.email,
      'gym_name': instance.gymName,
      'status': instance.status,
    };
