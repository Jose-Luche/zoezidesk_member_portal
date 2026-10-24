import 'package:freezed_annotation/freezed_annotation.dart';

import 'member_summary.dart';

part 'auth_dto.freezed.dart';
part 'auth_dto.g.dart';

/// `POST /member/otp/request`. [debugCode] is only sent by a local backend.
@freezed
abstract class OtpRequestResult with _$OtpRequestResult {
  const factory OtpRequestResult({
    @Default(false) bool success,
    String? message,
    String? debugCode,
  }) = _OtpRequestResult;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestResultFromJson(json);
}

/// `POST /member/otp/verify`. [refreshToken] is missing from servers
/// without token expiry; the access token then never expires.
@freezed
abstract class LoginResult with _$LoginResult {
  const factory LoginResult({
    required String token,
    String? refreshToken,
    required MemberSummary member,
  }) = _LoginResult;

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);
}
