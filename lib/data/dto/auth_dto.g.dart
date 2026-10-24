// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpRequestResult _$OtpRequestResultFromJson(Map<String, dynamic> json) =>
    _OtpRequestResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      debugCode: json['debug_code'] as String?,
    );

Map<String, dynamic> _$OtpRequestResultToJson(_OtpRequestResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'debug_code': instance.debugCode,
    };

_LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => _LoginResult(
  token: json['token'] as String,
  refreshToken: json['refresh_token'] as String?,
  member: MemberSummary.fromJson(json['member'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginResultToJson(_LoginResult instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'member': instance.member.toJson(),
    };
