import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_summary.freezed.dart';
part 'member_summary.g.dart';

/// The member returned by `POST /member/otp/verify`.
@freezed
abstract class MemberSummary with _$MemberSummary {
  const factory MemberSummary({
    required int id,
    required String name,
    String? memberNumber,
    String? phone,
    String? email,
    String? gymName,
    String? status,
  }) = _MemberSummary;

  factory MemberSummary.fromJson(Map<String, dynamic> json) =>
      _$MemberSummaryFromJson(json);
}
