// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) => _ProfileDto(
  member: ProfileMember.fromJson(json['member'] as Map<String, dynamic>),
  gym: json['gym'] == null
      ? null
      : GymContact.fromJson(json['gym'] as Map<String, dynamic>),
  memberships:
      (json['memberships'] as List<dynamic>?)
          ?.map((e) => MembershipRecord.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  generatedAt: json['generated_at'] as String?,
);

Map<String, dynamic> _$ProfileDtoToJson(_ProfileDto instance) =>
    <String, dynamic>{
      'member': instance.member.toJson(),
      'gym': instance.gym?.toJson(),
      'memberships': instance.memberships.map((e) => e.toJson()).toList(),
      'generated_at': instance.generatedAt,
    };

_ProfileMember _$ProfileMemberFromJson(Map<String, dynamic> json) =>
    _ProfileMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      memberNumber: json['member_number'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String?,
      memberSince: json['member_since'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$ProfileMemberToJson(_ProfileMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'member_number': instance.memberNumber,
      'phone': instance.phone,
      'email': instance.email,
      'gender': instance.gender,
      'date_of_birth': instance.dateOfBirth,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
      'photo_url': instance.photoUrl,
      'status': instance.status,
      'member_since': instance.memberSince,
      'updated_at': instance.updatedAt,
    };

_GymContact _$GymContactFromJson(Map<String, dynamic> json) => _GymContact(
  name: json['name'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  address: json['address'] as String?,
  town: json['town'] as String?,
);

Map<String, dynamic> _$GymContactToJson(_GymContact instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'town': instance.town,
    };

_MembershipRecord _$MembershipRecordFromJson(Map<String, dynamic> json) =>
    _MembershipRecord(
      id: (json['id'] as num).toInt(),
      planName: json['plan_name'] as String?,
      startsAtIso: json['starts_at_iso'] as String,
      expiresAtIso: json['expires_at_iso'] as String,
      status: json['status'] as String?,
      lapsed: json['lapsed'] as bool? ?? false,
    );

Map<String, dynamic> _$MembershipRecordToJson(_MembershipRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_name': instance.planName,
      'starts_at_iso': instance.startsAtIso,
      'expires_at_iso': instance.expiresAtIso,
      'status': instance.status,
      'lapsed': instance.lapsed,
    };
