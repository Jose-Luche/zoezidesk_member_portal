import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

/// `GET /member/profile` (read-only; the web portal has no profile editing).
@freezed
abstract class ProfileDto with _$ProfileDto {
  const factory ProfileDto({
    required ProfileMember member,
    GymContact? gym,
    @Default([]) List<MembershipRecord> memberships,
    String? generatedAt,
  }) = _ProfileDto;

  factory ProfileDto.fromJson(Map<String, dynamic> json) => _$ProfileDtoFromJson(json);
}

@freezed
abstract class ProfileMember with _$ProfileMember {
  const factory ProfileMember({
    required int id,
    required String name,
    String? memberNumber,
    String? phone,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? photoUrl,
    String? status,
    String? memberSince,
    String? updatedAt,
  }) = _ProfileMember;

  factory ProfileMember.fromJson(Map<String, dynamic> json) =>
      _$ProfileMemberFromJson(json);
}

@freezed
abstract class GymContact with _$GymContact {
  const factory GymContact({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? town,
  }) = _GymContact;

  factory GymContact.fromJson(Map<String, dynamic> json) => _$GymContactFromJson(json);
}

@freezed
abstract class MembershipRecord with _$MembershipRecord {
  const factory MembershipRecord({
    required int id,
    String? planName,
    required String startsAtIso,
    required String expiresAtIso,
    String? status,
    @Default(false) bool lapsed,
  }) = _MembershipRecord;

  factory MembershipRecord.fromJson(Map<String, dynamic> json) =>
      _$MembershipRecordFromJson(json);
}
