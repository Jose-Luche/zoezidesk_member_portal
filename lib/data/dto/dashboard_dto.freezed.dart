// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardDto {

 DashboardMember get member; MembershipInfo? get membership; List<RecentPayment> get recentPayments; int get attendanceMonth; int? get totalPaid; String? get generatedAt;
/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardDtoCopyWith<DashboardDto> get copyWith => _$DashboardDtoCopyWithImpl<DashboardDto>(this as DashboardDto, _$identity);

  /// Serializes this DashboardDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DashboardDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardDto&&(identical(other.member, _this.member) || other.member == _this.member)&&(identical(other.membership, _this.membership) || other.membership == _this.membership)&&const DeepCollectionEquality().equals(other.recentPayments, _this.recentPayments)&&(identical(other.attendanceMonth, _this.attendanceMonth) || other.attendanceMonth == _this.attendanceMonth)&&(identical(other.totalPaid, _this.totalPaid) || other.totalPaid == _this.totalPaid)&&(identical(other.generatedAt, _this.generatedAt) || other.generatedAt == _this.generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DashboardDto;
  return Object.hash(runtimeType,_this.member,_this.membership,const DeepCollectionEquality().hash(_this.recentPayments),_this.attendanceMonth,_this.totalPaid,_this.generatedAt);
}

@override
String toString() {
  final _this = this as DashboardDto;
  return 'DashboardDto(member: ${_this.member}, membership: ${_this.membership}, recentPayments: ${_this.recentPayments}, attendanceMonth: ${_this.attendanceMonth}, totalPaid: ${_this.totalPaid}, generatedAt: ${_this.generatedAt})';
}


}

/// @nodoc
abstract mixin class $DashboardDtoCopyWith<$Res>  {
  factory $DashboardDtoCopyWith(DashboardDto value, $Res Function(DashboardDto) _then) = _$DashboardDtoCopyWithImpl;
@useResult
$Res call({
 DashboardMember member, MembershipInfo? membership, List<RecentPayment> recentPayments, int attendanceMonth, int? totalPaid, String? generatedAt
});


$DashboardMemberCopyWith<$Res> get member;$MembershipInfoCopyWith<$Res>? get membership;

}
/// @nodoc
class _$DashboardDtoCopyWithImpl<$Res>
    implements $DashboardDtoCopyWith<$Res> {
  _$DashboardDtoCopyWithImpl(this._self, this._then);

  final DashboardDto _self;
  final $Res Function(DashboardDto) _then;

/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? member = null,Object? membership = freezed,Object? recentPayments = null,Object? attendanceMonth = null,Object? totalPaid = freezed,Object? generatedAt = freezed,}) {
  return _then(DashboardDto(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as DashboardMember,membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as MembershipInfo?,recentPayments: null == recentPayments ? _self.recentPayments : recentPayments // ignore: cast_nullable_to_non_nullable
as List<RecentPayment>,attendanceMonth: null == attendanceMonth ? _self.attendanceMonth : attendanceMonth // ignore: cast_nullable_to_non_nullable
as int,totalPaid: freezed == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as int?,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardMemberCopyWith<$Res> get member {
  
  return $DashboardMemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipInfoCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $MembershipInfoCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardDto].
extension DashboardDtoPatterns on DashboardDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardDto value)  $default,){
final _that = this;
switch (_that) {
case _DashboardDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardDto value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DashboardMember member,  MembershipInfo? membership,  List<RecentPayment> recentPayments,  int attendanceMonth,  int? totalPaid,  String? generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardDto() when $default != null:
return $default(_that.member,_that.membership,_that.recentPayments,_that.attendanceMonth,_that.totalPaid,_that.generatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DashboardMember member,  MembershipInfo? membership,  List<RecentPayment> recentPayments,  int attendanceMonth,  int? totalPaid,  String? generatedAt)  $default,) {final _that = this;
switch (_that) {
case _DashboardDto():
return $default(_that.member,_that.membership,_that.recentPayments,_that.attendanceMonth,_that.totalPaid,_that.generatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DashboardMember member,  MembershipInfo? membership,  List<RecentPayment> recentPayments,  int attendanceMonth,  int? totalPaid,  String? generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DashboardDto() when $default != null:
return $default(_that.member,_that.membership,_that.recentPayments,_that.attendanceMonth,_that.totalPaid,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardDto implements DashboardDto {
  const _DashboardDto({required this.member, this.membership,  List<RecentPayment> recentPayments = const [], this.attendanceMonth = 0, this.totalPaid, this.generatedAt}): _recentPayments = recentPayments;
  factory _DashboardDto.fromJson(Map<String, dynamic> json) => _$DashboardDtoFromJson(json);

@override final  DashboardMember member;
@override final  MembershipInfo? membership;
 final  List<RecentPayment> _recentPayments;
@override@JsonKey() List<RecentPayment> get recentPayments {
  if (_recentPayments is EqualUnmodifiableListView) return _recentPayments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentPayments);
}

@override@JsonKey() final  int attendanceMonth;
@override final  int? totalPaid;
@override final  String? generatedAt;

/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardDtoCopyWith<_DashboardDto> get copyWith => __$DashboardDtoCopyWithImpl<_DashboardDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardDto&&(identical(other.member, member) || other.member == member)&&(identical(other.membership, membership) || other.membership == membership)&&const DeepCollectionEquality().equals(other.recentPayments, _recentPayments)&&(identical(other.attendanceMonth, attendanceMonth) || other.attendanceMonth == attendanceMonth)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,member,membership,const DeepCollectionEquality().hash(_recentPayments),attendanceMonth,totalPaid,generatedAt);
}

@override
String toString() {
    return 'DashboardDto(member: $member, membership: $membership, recentPayments: $recentPayments, attendanceMonth: $attendanceMonth, totalPaid: $totalPaid, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$DashboardDtoCopyWith<$Res> implements $DashboardDtoCopyWith<$Res> {
  factory _$DashboardDtoCopyWith(_DashboardDto value, $Res Function(_DashboardDto) _then) = __$DashboardDtoCopyWithImpl;
@override @useResult
$Res call({
 DashboardMember member, MembershipInfo? membership, List<RecentPayment> recentPayments, int attendanceMonth, int? totalPaid, String? generatedAt
});


@override $DashboardMemberCopyWith<$Res> get member;@override $MembershipInfoCopyWith<$Res>? get membership;

}
/// @nodoc
class __$DashboardDtoCopyWithImpl<$Res>
    implements _$DashboardDtoCopyWith<$Res> {
  __$DashboardDtoCopyWithImpl(this._self, this._then);

  final _DashboardDto _self;
  final $Res Function(_DashboardDto) _then;

/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? member = null,Object? membership = freezed,Object? recentPayments = null,Object? attendanceMonth = null,Object? totalPaid = freezed,Object? generatedAt = freezed,}) {
  return _then(_DashboardDto(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as DashboardMember,membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as MembershipInfo?,recentPayments: null == recentPayments ? _self._recentPayments : recentPayments // ignore: cast_nullable_to_non_nullable
as List<RecentPayment>,attendanceMonth: null == attendanceMonth ? _self.attendanceMonth : attendanceMonth // ignore: cast_nullable_to_non_nullable
as int,totalPaid: freezed == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as int?,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardMemberCopyWith<$Res> get member {
  
  return $DashboardMemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of DashboardDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipInfoCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $MembershipInfoCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}


/// @nodoc
mixin _$DashboardMember {

 int get id; String get name; String? get memberNumber; String? get gymName; String? get status;
/// Create a copy of DashboardMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardMemberCopyWith<DashboardMember> get copyWith => _$DashboardMemberCopyWithImpl<DashboardMember>(this as DashboardMember, _$identity);

  /// Serializes this DashboardMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DashboardMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardMember&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.memberNumber, _this.memberNumber) || other.memberNumber == _this.memberNumber)&&(identical(other.gymName, _this.gymName) || other.gymName == _this.gymName)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DashboardMember;
  return Object.hash(runtimeType,_this.id,_this.name,_this.memberNumber,_this.gymName,_this.status);
}

@override
String toString() {
  final _this = this as DashboardMember;
  return 'DashboardMember(id: ${_this.id}, name: ${_this.name}, memberNumber: ${_this.memberNumber}, gymName: ${_this.gymName}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $DashboardMemberCopyWith<$Res>  {
  factory $DashboardMemberCopyWith(DashboardMember value, $Res Function(DashboardMember) _then) = _$DashboardMemberCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? memberNumber, String? gymName, String? status
});




}
/// @nodoc
class _$DashboardMemberCopyWithImpl<$Res>
    implements $DashboardMemberCopyWith<$Res> {
  _$DashboardMemberCopyWithImpl(this._self, this._then);

  final DashboardMember _self;
  final $Res Function(DashboardMember) _then;

/// Create a copy of DashboardMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? gymName = freezed,Object? status = freezed,}) {
  return _then(DashboardMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardMember].
extension DashboardMemberPatterns on DashboardMember {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardMember() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardMember value)  $default,){
final _that = this;
switch (_that) {
case _DashboardMember():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardMember value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardMember() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? gymName,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardMember() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.gymName,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? gymName,  String? status)  $default,) {final _that = this;
switch (_that) {
case _DashboardMember():
return $default(_that.id,_that.name,_that.memberNumber,_that.gymName,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? memberNumber,  String? gymName,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _DashboardMember() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.gymName,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardMember implements DashboardMember {
  const _DashboardMember({required this.id, required this.name, this.memberNumber, this.gymName, this.status});
  factory _DashboardMember.fromJson(Map<String, dynamic> json) => _$DashboardMemberFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? memberNumber;
@override final  String? gymName;
@override final  String? status;

/// Create a copy of DashboardMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardMemberCopyWith<_DashboardMember> get copyWith => __$DashboardMemberCopyWithImpl<_DashboardMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.gymName, gymName) || other.gymName == gymName)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,memberNumber,gymName,status);
}

@override
String toString() {
    return 'DashboardMember(id: $id, name: $name, memberNumber: $memberNumber, gymName: $gymName, status: $status)';
}


}

/// @nodoc
abstract mixin class _$DashboardMemberCopyWith<$Res> implements $DashboardMemberCopyWith<$Res> {
  factory _$DashboardMemberCopyWith(_DashboardMember value, $Res Function(_DashboardMember) _then) = __$DashboardMemberCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? memberNumber, String? gymName, String? status
});




}
/// @nodoc
class __$DashboardMemberCopyWithImpl<$Res>
    implements _$DashboardMemberCopyWith<$Res> {
  __$DashboardMemberCopyWithImpl(this._self, this._then);

  final _DashboardMember _self;
  final $Res Function(_DashboardMember) _then;

/// Create a copy of DashboardMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? gymName = freezed,Object? status = freezed,}) {
  return _then(_DashboardMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MembershipInfo {

 String? get planName; String? get startsAt; String? get expiresAt; String? get startsAtIso; String? get expiresAtIso;/// Fractional on the original API; prefer [daysRemaining].
 num? get daysLeft; int? get daysRemaining; int? get expiryPercent; String? get state;
/// Create a copy of MembershipInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipInfoCopyWith<MembershipInfo> get copyWith => _$MembershipInfoCopyWithImpl<MembershipInfo>(this as MembershipInfo, _$identity);

  /// Serializes this MembershipInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MembershipInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipInfo&&(identical(other.planName, _this.planName) || other.planName == _this.planName)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.startsAtIso, _this.startsAtIso) || other.startsAtIso == _this.startsAtIso)&&(identical(other.expiresAtIso, _this.expiresAtIso) || other.expiresAtIso == _this.expiresAtIso)&&(identical(other.daysLeft, _this.daysLeft) || other.daysLeft == _this.daysLeft)&&(identical(other.daysRemaining, _this.daysRemaining) || other.daysRemaining == _this.daysRemaining)&&(identical(other.expiryPercent, _this.expiryPercent) || other.expiryPercent == _this.expiryPercent)&&(identical(other.state, _this.state) || other.state == _this.state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MembershipInfo;
  return Object.hash(runtimeType,_this.planName,_this.startsAt,_this.expiresAt,_this.startsAtIso,_this.expiresAtIso,_this.daysLeft,_this.daysRemaining,_this.expiryPercent,_this.state);
}

@override
String toString() {
  final _this = this as MembershipInfo;
  return 'MembershipInfo(planName: ${_this.planName}, startsAt: ${_this.startsAt}, expiresAt: ${_this.expiresAt}, startsAtIso: ${_this.startsAtIso}, expiresAtIso: ${_this.expiresAtIso}, daysLeft: ${_this.daysLeft}, daysRemaining: ${_this.daysRemaining}, expiryPercent: ${_this.expiryPercent}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $MembershipInfoCopyWith<$Res>  {
  factory $MembershipInfoCopyWith(MembershipInfo value, $Res Function(MembershipInfo) _then) = _$MembershipInfoCopyWithImpl;
@useResult
$Res call({
 String? planName, String? startsAt, String? expiresAt, String? startsAtIso, String? expiresAtIso, num? daysLeft, int? daysRemaining, int? expiryPercent, String? state
});




}
/// @nodoc
class _$MembershipInfoCopyWithImpl<$Res>
    implements $MembershipInfoCopyWith<$Res> {
  _$MembershipInfoCopyWithImpl(this._self, this._then);

  final MembershipInfo _self;
  final $Res Function(MembershipInfo) _then;

/// Create a copy of MembershipInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planName = freezed,Object? startsAt = freezed,Object? expiresAt = freezed,Object? startsAtIso = freezed,Object? expiresAtIso = freezed,Object? daysLeft = freezed,Object? daysRemaining = freezed,Object? expiryPercent = freezed,Object? state = freezed,}) {
  return _then(MembershipInfo(
planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,startsAtIso: freezed == startsAtIso ? _self.startsAtIso : startsAtIso // ignore: cast_nullable_to_non_nullable
as String?,expiresAtIso: freezed == expiresAtIso ? _self.expiresAtIso : expiresAtIso // ignore: cast_nullable_to_non_nullable
as String?,daysLeft: freezed == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as num?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,expiryPercent: freezed == expiryPercent ? _self.expiryPercent : expiryPercent // ignore: cast_nullable_to_non_nullable
as int?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipInfo].
extension MembershipInfoPatterns on MembershipInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipInfo value)  $default,){
final _that = this;
switch (_that) {
case _MembershipInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipInfo value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? planName,  String? startsAt,  String? expiresAt,  String? startsAtIso,  String? expiresAtIso,  num? daysLeft,  int? daysRemaining,  int? expiryPercent,  String? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipInfo() when $default != null:
return $default(_that.planName,_that.startsAt,_that.expiresAt,_that.startsAtIso,_that.expiresAtIso,_that.daysLeft,_that.daysRemaining,_that.expiryPercent,_that.state);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? planName,  String? startsAt,  String? expiresAt,  String? startsAtIso,  String? expiresAtIso,  num? daysLeft,  int? daysRemaining,  int? expiryPercent,  String? state)  $default,) {final _that = this;
switch (_that) {
case _MembershipInfo():
return $default(_that.planName,_that.startsAt,_that.expiresAt,_that.startsAtIso,_that.expiresAtIso,_that.daysLeft,_that.daysRemaining,_that.expiryPercent,_that.state);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? planName,  String? startsAt,  String? expiresAt,  String? startsAtIso,  String? expiresAtIso,  num? daysLeft,  int? daysRemaining,  int? expiryPercent,  String? state)?  $default,) {final _that = this;
switch (_that) {
case _MembershipInfo() when $default != null:
return $default(_that.planName,_that.startsAt,_that.expiresAt,_that.startsAtIso,_that.expiresAtIso,_that.daysLeft,_that.daysRemaining,_that.expiryPercent,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipInfo implements MembershipInfo {
  const _MembershipInfo({this.planName, this.startsAt, this.expiresAt, this.startsAtIso, this.expiresAtIso, this.daysLeft, this.daysRemaining, this.expiryPercent, this.state});
  factory _MembershipInfo.fromJson(Map<String, dynamic> json) => _$MembershipInfoFromJson(json);

@override final  String? planName;
@override final  String? startsAt;
@override final  String? expiresAt;
@override final  String? startsAtIso;
@override final  String? expiresAtIso;
/// Fractional on the original API; prefer [daysRemaining].
@override final  num? daysLeft;
@override final  int? daysRemaining;
@override final  int? expiryPercent;
@override final  String? state;

/// Create a copy of MembershipInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipInfoCopyWith<_MembershipInfo> get copyWith => __$MembershipInfoCopyWithImpl<_MembershipInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipInfo&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.startsAtIso, startsAtIso) || other.startsAtIso == startsAtIso)&&(identical(other.expiresAtIso, expiresAtIso) || other.expiresAtIso == expiresAtIso)&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.expiryPercent, expiryPercent) || other.expiryPercent == expiryPercent)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,planName,startsAt,expiresAt,startsAtIso,expiresAtIso,daysLeft,daysRemaining,expiryPercent,state);
}

@override
String toString() {
    return 'MembershipInfo(planName: $planName, startsAt: $startsAt, expiresAt: $expiresAt, startsAtIso: $startsAtIso, expiresAtIso: $expiresAtIso, daysLeft: $daysLeft, daysRemaining: $daysRemaining, expiryPercent: $expiryPercent, state: $state)';
}


}

/// @nodoc
abstract mixin class _$MembershipInfoCopyWith<$Res> implements $MembershipInfoCopyWith<$Res> {
  factory _$MembershipInfoCopyWith(_MembershipInfo value, $Res Function(_MembershipInfo) _then) = __$MembershipInfoCopyWithImpl;
@override @useResult
$Res call({
 String? planName, String? startsAt, String? expiresAt, String? startsAtIso, String? expiresAtIso, num? daysLeft, int? daysRemaining, int? expiryPercent, String? state
});




}
/// @nodoc
class __$MembershipInfoCopyWithImpl<$Res>
    implements _$MembershipInfoCopyWith<$Res> {
  __$MembershipInfoCopyWithImpl(this._self, this._then);

  final _MembershipInfo _self;
  final $Res Function(_MembershipInfo) _then;

/// Create a copy of MembershipInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planName = freezed,Object? startsAt = freezed,Object? expiresAt = freezed,Object? startsAtIso = freezed,Object? expiresAtIso = freezed,Object? daysLeft = freezed,Object? daysRemaining = freezed,Object? expiryPercent = freezed,Object? state = freezed,}) {
  return _then(_MembershipInfo(
planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,startsAtIso: freezed == startsAtIso ? _self.startsAtIso : startsAtIso // ignore: cast_nullable_to_non_nullable
as String?,expiresAtIso: freezed == expiresAtIso ? _self.expiresAtIso : expiresAtIso // ignore: cast_nullable_to_non_nullable
as String?,daysLeft: freezed == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as num?,daysRemaining: freezed == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int?,expiryPercent: freezed == expiryPercent ? _self.expiryPercent : expiryPercent // ignore: cast_nullable_to_non_nullable
as int?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RecentPayment {

 int get id; num get amount; String? get method; String? get receipt; String? get date; String? get dateIso; String? get plan;
/// Create a copy of RecentPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentPaymentCopyWith<RecentPayment> get copyWith => _$RecentPaymentCopyWithImpl<RecentPayment>(this as RecentPayment, _$identity);

  /// Serializes this RecentPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecentPayment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentPayment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.receipt, _this.receipt) || other.receipt == _this.receipt)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.dateIso, _this.dateIso) || other.dateIso == _this.dateIso)&&(identical(other.plan, _this.plan) || other.plan == _this.plan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecentPayment;
  return Object.hash(runtimeType,_this.id,_this.amount,_this.method,_this.receipt,_this.date,_this.dateIso,_this.plan);
}

@override
String toString() {
  final _this = this as RecentPayment;
  return 'RecentPayment(id: ${_this.id}, amount: ${_this.amount}, method: ${_this.method}, receipt: ${_this.receipt}, date: ${_this.date}, dateIso: ${_this.dateIso}, plan: ${_this.plan})';
}


}

/// @nodoc
abstract mixin class $RecentPaymentCopyWith<$Res>  {
  factory $RecentPaymentCopyWith(RecentPayment value, $Res Function(RecentPayment) _then) = _$RecentPaymentCopyWithImpl;
@useResult
$Res call({
 int id, num amount, String? method, String? receipt, String? date, String? dateIso, String? plan
});




}
/// @nodoc
class _$RecentPaymentCopyWithImpl<$Res>
    implements $RecentPaymentCopyWith<$Res> {
  _$RecentPaymentCopyWithImpl(this._self, this._then);

  final RecentPayment _self;
  final $Res Function(RecentPayment) _then;

/// Create a copy of RecentPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? method = freezed,Object? receipt = freezed,Object? date = freezed,Object? dateIso = freezed,Object? plan = freezed,}) {
  return _then(RecentPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,receipt: freezed == receipt ? _self.receipt : receipt // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,dateIso: freezed == dateIso ? _self.dateIso : dateIso // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentPayment].
extension RecentPaymentPatterns on RecentPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentPayment value)  $default,){
final _that = this;
switch (_that) {
case _RecentPayment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentPayment value)?  $default,){
final _that = this;
switch (_that) {
case _RecentPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  num amount,  String? method,  String? receipt,  String? date,  String? dateIso,  String? plan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentPayment() when $default != null:
return $default(_that.id,_that.amount,_that.method,_that.receipt,_that.date,_that.dateIso,_that.plan);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  num amount,  String? method,  String? receipt,  String? date,  String? dateIso,  String? plan)  $default,) {final _that = this;
switch (_that) {
case _RecentPayment():
return $default(_that.id,_that.amount,_that.method,_that.receipt,_that.date,_that.dateIso,_that.plan);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  num amount,  String? method,  String? receipt,  String? date,  String? dateIso,  String? plan)?  $default,) {final _that = this;
switch (_that) {
case _RecentPayment() when $default != null:
return $default(_that.id,_that.amount,_that.method,_that.receipt,_that.date,_that.dateIso,_that.plan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentPayment implements RecentPayment {
  const _RecentPayment({required this.id, required this.amount, this.method, this.receipt, this.date, this.dateIso, this.plan});
  factory _RecentPayment.fromJson(Map<String, dynamic> json) => _$RecentPaymentFromJson(json);

@override final  int id;
@override final  num amount;
@override final  String? method;
@override final  String? receipt;
@override final  String? date;
@override final  String? dateIso;
@override final  String? plan;

/// Create a copy of RecentPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentPaymentCopyWith<_RecentPayment> get copyWith => __$RecentPaymentCopyWithImpl<_RecentPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.receipt, receipt) || other.receipt == receipt)&&(identical(other.date, date) || other.date == date)&&(identical(other.dateIso, dateIso) || other.dateIso == dateIso)&&(identical(other.plan, plan) || other.plan == plan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,amount,method,receipt,date,dateIso,plan);
}

@override
String toString() {
    return 'RecentPayment(id: $id, amount: $amount, method: $method, receipt: $receipt, date: $date, dateIso: $dateIso, plan: $plan)';
}


}

/// @nodoc
abstract mixin class _$RecentPaymentCopyWith<$Res> implements $RecentPaymentCopyWith<$Res> {
  factory _$RecentPaymentCopyWith(_RecentPayment value, $Res Function(_RecentPayment) _then) = __$RecentPaymentCopyWithImpl;
@override @useResult
$Res call({
 int id, num amount, String? method, String? receipt, String? date, String? dateIso, String? plan
});




}
/// @nodoc
class __$RecentPaymentCopyWithImpl<$Res>
    implements _$RecentPaymentCopyWith<$Res> {
  __$RecentPaymentCopyWithImpl(this._self, this._then);

  final _RecentPayment _self;
  final $Res Function(_RecentPayment) _then;

/// Create a copy of RecentPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? method = freezed,Object? receipt = freezed,Object? date = freezed,Object? dateIso = freezed,Object? plan = freezed,}) {
  return _then(_RecentPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,receipt: freezed == receipt ? _self.receipt : receipt // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,dateIso: freezed == dateIso ? _self.dateIso : dateIso // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MemberCardDto {

 String get qrCode; String? get memberNumber; String? get name; String? get gymName;
/// Create a copy of MemberCardDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCardDtoCopyWith<MemberCardDto> get copyWith => _$MemberCardDtoCopyWithImpl<MemberCardDto>(this as MemberCardDto, _$identity);

  /// Serializes this MemberCardDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberCardDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberCardDto&&(identical(other.qrCode, _this.qrCode) || other.qrCode == _this.qrCode)&&(identical(other.memberNumber, _this.memberNumber) || other.memberNumber == _this.memberNumber)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.gymName, _this.gymName) || other.gymName == _this.gymName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberCardDto;
  return Object.hash(runtimeType,_this.qrCode,_this.memberNumber,_this.name,_this.gymName);
}

@override
String toString() {
  final _this = this as MemberCardDto;
  return 'MemberCardDto(qrCode: ${_this.qrCode}, memberNumber: ${_this.memberNumber}, name: ${_this.name}, gymName: ${_this.gymName})';
}


}

/// @nodoc
abstract mixin class $MemberCardDtoCopyWith<$Res>  {
  factory $MemberCardDtoCopyWith(MemberCardDto value, $Res Function(MemberCardDto) _then) = _$MemberCardDtoCopyWithImpl;
@useResult
$Res call({
 String qrCode, String? memberNumber, String? name, String? gymName
});




}
/// @nodoc
class _$MemberCardDtoCopyWithImpl<$Res>
    implements $MemberCardDtoCopyWith<$Res> {
  _$MemberCardDtoCopyWithImpl(this._self, this._then);

  final MemberCardDto _self;
  final $Res Function(MemberCardDto) _then;

/// Create a copy of MemberCardDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? qrCode = null,Object? memberNumber = freezed,Object? name = freezed,Object? gymName = freezed,}) {
  return _then(MemberCardDto(
qrCode: null == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberCardDto].
extension MemberCardDtoPatterns on MemberCardDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberCardDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberCardDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberCardDto value)  $default,){
final _that = this;
switch (_that) {
case _MemberCardDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberCardDto value)?  $default,){
final _that = this;
switch (_that) {
case _MemberCardDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String qrCode,  String? memberNumber,  String? name,  String? gymName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberCardDto() when $default != null:
return $default(_that.qrCode,_that.memberNumber,_that.name,_that.gymName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String qrCode,  String? memberNumber,  String? name,  String? gymName)  $default,) {final _that = this;
switch (_that) {
case _MemberCardDto():
return $default(_that.qrCode,_that.memberNumber,_that.name,_that.gymName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String qrCode,  String? memberNumber,  String? name,  String? gymName)?  $default,) {final _that = this;
switch (_that) {
case _MemberCardDto() when $default != null:
return $default(_that.qrCode,_that.memberNumber,_that.name,_that.gymName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberCardDto implements MemberCardDto {
  const _MemberCardDto({required this.qrCode, this.memberNumber, this.name, this.gymName});
  factory _MemberCardDto.fromJson(Map<String, dynamic> json) => _$MemberCardDtoFromJson(json);

@override final  String qrCode;
@override final  String? memberNumber;
@override final  String? name;
@override final  String? gymName;

/// Create a copy of MemberCardDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCardDtoCopyWith<_MemberCardDto> get copyWith => __$MemberCardDtoCopyWithImpl<_MemberCardDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberCardDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberCardDto&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.name, name) || other.name == name)&&(identical(other.gymName, gymName) || other.gymName == gymName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,qrCode,memberNumber,name,gymName);
}

@override
String toString() {
    return 'MemberCardDto(qrCode: $qrCode, memberNumber: $memberNumber, name: $name, gymName: $gymName)';
}


}

/// @nodoc
abstract mixin class _$MemberCardDtoCopyWith<$Res> implements $MemberCardDtoCopyWith<$Res> {
  factory _$MemberCardDtoCopyWith(_MemberCardDto value, $Res Function(_MemberCardDto) _then) = __$MemberCardDtoCopyWithImpl;
@override @useResult
$Res call({
 String qrCode, String? memberNumber, String? name, String? gymName
});




}
/// @nodoc
class __$MemberCardDtoCopyWithImpl<$Res>
    implements _$MemberCardDtoCopyWith<$Res> {
  __$MemberCardDtoCopyWithImpl(this._self, this._then);

  final _MemberCardDto _self;
  final $Res Function(_MemberCardDto) _then;

/// Create a copy of MemberCardDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? qrCode = null,Object? memberNumber = freezed,Object? name = freezed,Object? gymName = freezed,}) {
  return _then(_MemberCardDto(
qrCode: null == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
