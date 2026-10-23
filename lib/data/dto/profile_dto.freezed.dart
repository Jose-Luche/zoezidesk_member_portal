// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileDto {

 ProfileMember get member; GymContact? get gym; List<MembershipRecord> get memberships; String? get generatedAt;
/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileDtoCopyWith<ProfileDto> get copyWith => _$ProfileDtoCopyWithImpl<ProfileDto>(this as ProfileDto, _$identity);

  /// Serializes this ProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProfileDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileDto&&(identical(other.member, _this.member) || other.member == _this.member)&&(identical(other.gym, _this.gym) || other.gym == _this.gym)&&const DeepCollectionEquality().equals(other.memberships, _this.memberships)&&(identical(other.generatedAt, _this.generatedAt) || other.generatedAt == _this.generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProfileDto;
  return Object.hash(runtimeType,_this.member,_this.gym,const DeepCollectionEquality().hash(_this.memberships),_this.generatedAt);
}

@override
String toString() {
  final _this = this as ProfileDto;
  return 'ProfileDto(member: ${_this.member}, gym: ${_this.gym}, memberships: ${_this.memberships}, generatedAt: ${_this.generatedAt})';
}


}

/// @nodoc
abstract mixin class $ProfileDtoCopyWith<$Res>  {
  factory $ProfileDtoCopyWith(ProfileDto value, $Res Function(ProfileDto) _then) = _$ProfileDtoCopyWithImpl;
@useResult
$Res call({
 ProfileMember member, GymContact? gym, List<MembershipRecord> memberships, String? generatedAt
});


$ProfileMemberCopyWith<$Res> get member;$GymContactCopyWith<$Res>? get gym;

}
/// @nodoc
class _$ProfileDtoCopyWithImpl<$Res>
    implements $ProfileDtoCopyWith<$Res> {
  _$ProfileDtoCopyWithImpl(this._self, this._then);

  final ProfileDto _self;
  final $Res Function(ProfileDto) _then;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? member = null,Object? gym = freezed,Object? memberships = null,Object? generatedAt = freezed,}) {
  return _then(ProfileDto(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as ProfileMember,gym: freezed == gym ? _self.gym : gym // ignore: cast_nullable_to_non_nullable
as GymContact?,memberships: null == memberships ? _self.memberships : memberships // ignore: cast_nullable_to_non_nullable
as List<MembershipRecord>,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileMemberCopyWith<$Res> get member {
  
  return $ProfileMemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GymContactCopyWith<$Res>? get gym {
    if (_self.gym == null) {
    return null;
  }

  return $GymContactCopyWith<$Res>(_self.gym!, (value) {
    return _then(_self.copyWith(gym: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfileDto].
extension ProfileDtoPatterns on ProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _ProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProfileMember member,  GymContact? gym,  List<MembershipRecord> memberships,  String? generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
return $default(_that.member,_that.gym,_that.memberships,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProfileMember member,  GymContact? gym,  List<MembershipRecord> memberships,  String? generatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileDto():
return $default(_that.member,_that.gym,_that.memberships,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProfileMember member,  GymContact? gym,  List<MembershipRecord> memberships,  String? generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileDto() when $default != null:
return $default(_that.member,_that.gym,_that.memberships,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileDto implements ProfileDto {
  const _ProfileDto({required this.member, this.gym,  List<MembershipRecord> memberships = const [], this.generatedAt}): _memberships = memberships;
  factory _ProfileDto.fromJson(Map<String, dynamic> json) => _$ProfileDtoFromJson(json);

@override final  ProfileMember member;
@override final  GymContact? gym;
 final  List<MembershipRecord> _memberships;
@override@JsonKey() List<MembershipRecord> get memberships {
  if (_memberships is EqualUnmodifiableListView) return _memberships;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberships);
}

@override final  String? generatedAt;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileDtoCopyWith<_ProfileDto> get copyWith => __$ProfileDtoCopyWithImpl<_ProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileDto&&(identical(other.member, member) || other.member == member)&&(identical(other.gym, gym) || other.gym == gym)&&const DeepCollectionEquality().equals(other.memberships, _memberships)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,member,gym,const DeepCollectionEquality().hash(_memberships),generatedAt);
}

@override
String toString() {
    return 'ProfileDto(member: $member, gym: $gym, memberships: $memberships, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileDtoCopyWith<$Res> implements $ProfileDtoCopyWith<$Res> {
  factory _$ProfileDtoCopyWith(_ProfileDto value, $Res Function(_ProfileDto) _then) = __$ProfileDtoCopyWithImpl;
@override @useResult
$Res call({
 ProfileMember member, GymContact? gym, List<MembershipRecord> memberships, String? generatedAt
});


@override $ProfileMemberCopyWith<$Res> get member;@override $GymContactCopyWith<$Res>? get gym;

}
/// @nodoc
class __$ProfileDtoCopyWithImpl<$Res>
    implements _$ProfileDtoCopyWith<$Res> {
  __$ProfileDtoCopyWithImpl(this._self, this._then);

  final _ProfileDto _self;
  final $Res Function(_ProfileDto) _then;

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? member = null,Object? gym = freezed,Object? memberships = null,Object? generatedAt = freezed,}) {
  return _then(_ProfileDto(
member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as ProfileMember,gym: freezed == gym ? _self.gym : gym // ignore: cast_nullable_to_non_nullable
as GymContact?,memberships: null == memberships ? _self._memberships : memberships // ignore: cast_nullable_to_non_nullable
as List<MembershipRecord>,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileMemberCopyWith<$Res> get member {
  
  return $ProfileMemberCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}/// Create a copy of ProfileDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GymContactCopyWith<$Res>? get gym {
    if (_self.gym == null) {
    return null;
  }

  return $GymContactCopyWith<$Res>(_self.gym!, (value) {
    return _then(_self.copyWith(gym: value));
  });
}
}


/// @nodoc
mixin _$ProfileMember {

 int get id; String get name; String? get memberNumber; String? get phone; String? get email; String? get gender; String? get dateOfBirth; String? get emergencyContactName; String? get emergencyContactPhone; String? get photoUrl; String? get status; String? get memberSince; String? get updatedAt;
/// Create a copy of ProfileMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileMemberCopyWith<ProfileMember> get copyWith => _$ProfileMemberCopyWithImpl<ProfileMember>(this as ProfileMember, _$identity);

  /// Serializes this ProfileMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProfileMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileMember&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.memberNumber, _this.memberNumber) || other.memberNumber == _this.memberNumber)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&(identical(other.dateOfBirth, _this.dateOfBirth) || other.dateOfBirth == _this.dateOfBirth)&&(identical(other.emergencyContactName, _this.emergencyContactName) || other.emergencyContactName == _this.emergencyContactName)&&(identical(other.emergencyContactPhone, _this.emergencyContactPhone) || other.emergencyContactPhone == _this.emergencyContactPhone)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.memberSince, _this.memberSince) || other.memberSince == _this.memberSince)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProfileMember;
  return Object.hash(runtimeType,_this.id,_this.name,_this.memberNumber,_this.phone,_this.email,_this.gender,_this.dateOfBirth,_this.emergencyContactName,_this.emergencyContactPhone,_this.photoUrl,_this.status,_this.memberSince,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ProfileMember;
  return 'ProfileMember(id: ${_this.id}, name: ${_this.name}, memberNumber: ${_this.memberNumber}, phone: ${_this.phone}, email: ${_this.email}, gender: ${_this.gender}, dateOfBirth: ${_this.dateOfBirth}, emergencyContactName: ${_this.emergencyContactName}, emergencyContactPhone: ${_this.emergencyContactPhone}, photoUrl: ${_this.photoUrl}, status: ${_this.status}, memberSince: ${_this.memberSince}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ProfileMemberCopyWith<$Res>  {
  factory $ProfileMemberCopyWith(ProfileMember value, $Res Function(ProfileMember) _then) = _$ProfileMemberCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? memberNumber, String? phone, String? email, String? gender, String? dateOfBirth, String? emergencyContactName, String? emergencyContactPhone, String? photoUrl, String? status, String? memberSince, String? updatedAt
});




}
/// @nodoc
class _$ProfileMemberCopyWithImpl<$Res>
    implements $ProfileMemberCopyWith<$Res> {
  _$ProfileMemberCopyWithImpl(this._self, this._then);

  final ProfileMember _self;
  final $Res Function(ProfileMember) _then;

/// Create a copy of ProfileMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? phone = freezed,Object? email = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? photoUrl = freezed,Object? status = freezed,Object? memberSince = freezed,Object? updatedAt = freezed,}) {
  return _then(ProfileMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,memberSince: freezed == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileMember].
extension ProfileMemberPatterns on ProfileMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileMember value)  $default,){
final _that = this;
switch (_that) {
case _ProfileMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileMember value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gender,  String? dateOfBirth,  String? emergencyContactName,  String? emergencyContactPhone,  String? photoUrl,  String? status,  String? memberSince,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileMember() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gender,_that.dateOfBirth,_that.emergencyContactName,_that.emergencyContactPhone,_that.photoUrl,_that.status,_that.memberSince,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gender,  String? dateOfBirth,  String? emergencyContactName,  String? emergencyContactPhone,  String? photoUrl,  String? status,  String? memberSince,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileMember():
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gender,_that.dateOfBirth,_that.emergencyContactName,_that.emergencyContactPhone,_that.photoUrl,_that.status,_that.memberSince,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gender,  String? dateOfBirth,  String? emergencyContactName,  String? emergencyContactPhone,  String? photoUrl,  String? status,  String? memberSince,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileMember() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gender,_that.dateOfBirth,_that.emergencyContactName,_that.emergencyContactPhone,_that.photoUrl,_that.status,_that.memberSince,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileMember implements ProfileMember {
  const _ProfileMember({required this.id, required this.name, this.memberNumber, this.phone, this.email, this.gender, this.dateOfBirth, this.emergencyContactName, this.emergencyContactPhone, this.photoUrl, this.status, this.memberSince, this.updatedAt});
  factory _ProfileMember.fromJson(Map<String, dynamic> json) => _$ProfileMemberFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? memberNumber;
@override final  String? phone;
@override final  String? email;
@override final  String? gender;
@override final  String? dateOfBirth;
@override final  String? emergencyContactName;
@override final  String? emergencyContactPhone;
@override final  String? photoUrl;
@override final  String? status;
@override final  String? memberSince;
@override final  String? updatedAt;

/// Create a copy of ProfileMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileMemberCopyWith<_ProfileMember> get copyWith => __$ProfileMemberCopyWithImpl<_ProfileMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,memberNumber,phone,email,gender,dateOfBirth,emergencyContactName,emergencyContactPhone,photoUrl,status,memberSince,updatedAt);
}

@override
String toString() {
    return 'ProfileMember(id: $id, name: $name, memberNumber: $memberNumber, phone: $phone, email: $email, gender: $gender, dateOfBirth: $dateOfBirth, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, photoUrl: $photoUrl, status: $status, memberSince: $memberSince, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileMemberCopyWith<$Res> implements $ProfileMemberCopyWith<$Res> {
  factory _$ProfileMemberCopyWith(_ProfileMember value, $Res Function(_ProfileMember) _then) = __$ProfileMemberCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? memberNumber, String? phone, String? email, String? gender, String? dateOfBirth, String? emergencyContactName, String? emergencyContactPhone, String? photoUrl, String? status, String? memberSince, String? updatedAt
});




}
/// @nodoc
class __$ProfileMemberCopyWithImpl<$Res>
    implements _$ProfileMemberCopyWith<$Res> {
  __$ProfileMemberCopyWithImpl(this._self, this._then);

  final _ProfileMember _self;
  final $Res Function(_ProfileMember) _then;

/// Create a copy of ProfileMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? phone = freezed,Object? email = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? photoUrl = freezed,Object? status = freezed,Object? memberSince = freezed,Object? updatedAt = freezed,}) {
  return _then(_ProfileMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,memberSince: freezed == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GymContact {

 String get name; String? get phone; String? get email; String? get address; String? get town;
/// Create a copy of GymContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GymContactCopyWith<GymContact> get copyWith => _$GymContactCopyWithImpl<GymContact>(this as GymContact, _$identity);

  /// Serializes this GymContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GymContact;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GymContact&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.town, _this.town) || other.town == _this.town));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GymContact;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.email,_this.address,_this.town);
}

@override
String toString() {
  final _this = this as GymContact;
  return 'GymContact(name: ${_this.name}, phone: ${_this.phone}, email: ${_this.email}, address: ${_this.address}, town: ${_this.town})';
}


}

/// @nodoc
abstract mixin class $GymContactCopyWith<$Res>  {
  factory $GymContactCopyWith(GymContact value, $Res Function(GymContact) _then) = _$GymContactCopyWithImpl;
@useResult
$Res call({
 String name, String? phone, String? email, String? address, String? town
});




}
/// @nodoc
class _$GymContactCopyWithImpl<$Res>
    implements $GymContactCopyWith<$Res> {
  _$GymContactCopyWithImpl(this._self, this._then);

  final GymContact _self;
  final $Res Function(GymContact) _then;

/// Create a copy of GymContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? town = freezed,}) {
  return _then(GymContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,town: freezed == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GymContact].
extension GymContactPatterns on GymContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GymContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GymContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GymContact value)  $default,){
final _that = this;
switch (_that) {
case _GymContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GymContact value)?  $default,){
final _that = this;
switch (_that) {
case _GymContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? phone,  String? email,  String? address,  String? town)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GymContact() when $default != null:
return $default(_that.name,_that.phone,_that.email,_that.address,_that.town);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? phone,  String? email,  String? address,  String? town)  $default,) {final _that = this;
switch (_that) {
case _GymContact():
return $default(_that.name,_that.phone,_that.email,_that.address,_that.town);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? phone,  String? email,  String? address,  String? town)?  $default,) {final _that = this;
switch (_that) {
case _GymContact() when $default != null:
return $default(_that.name,_that.phone,_that.email,_that.address,_that.town);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GymContact implements GymContact {
  const _GymContact({required this.name, this.phone, this.email, this.address, this.town});
  factory _GymContact.fromJson(Map<String, dynamic> json) => _$GymContactFromJson(json);

@override final  String name;
@override final  String? phone;
@override final  String? email;
@override final  String? address;
@override final  String? town;

/// Create a copy of GymContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GymContactCopyWith<_GymContact> get copyWith => __$GymContactCopyWithImpl<_GymContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GymContactToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GymContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.town, town) || other.town == town));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,email,address,town);
}

@override
String toString() {
    return 'GymContact(name: $name, phone: $phone, email: $email, address: $address, town: $town)';
}


}

/// @nodoc
abstract mixin class _$GymContactCopyWith<$Res> implements $GymContactCopyWith<$Res> {
  factory _$GymContactCopyWith(_GymContact value, $Res Function(_GymContact) _then) = __$GymContactCopyWithImpl;
@override @useResult
$Res call({
 String name, String? phone, String? email, String? address, String? town
});




}
/// @nodoc
class __$GymContactCopyWithImpl<$Res>
    implements _$GymContactCopyWith<$Res> {
  __$GymContactCopyWithImpl(this._self, this._then);

  final _GymContact _self;
  final $Res Function(_GymContact) _then;

/// Create a copy of GymContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? town = freezed,}) {
  return _then(_GymContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,town: freezed == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MembershipRecord {

 int get id; String? get planName; String get startsAtIso; String get expiresAtIso; String? get status; bool get lapsed;
/// Create a copy of MembershipRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRecordCopyWith<MembershipRecord> get copyWith => _$MembershipRecordCopyWithImpl<MembershipRecord>(this as MembershipRecord, _$identity);

  /// Serializes this MembershipRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MembershipRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRecord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.planName, _this.planName) || other.planName == _this.planName)&&(identical(other.startsAtIso, _this.startsAtIso) || other.startsAtIso == _this.startsAtIso)&&(identical(other.expiresAtIso, _this.expiresAtIso) || other.expiresAtIso == _this.expiresAtIso)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.lapsed, _this.lapsed) || other.lapsed == _this.lapsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MembershipRecord;
  return Object.hash(runtimeType,_this.id,_this.planName,_this.startsAtIso,_this.expiresAtIso,_this.status,_this.lapsed);
}

@override
String toString() {
  final _this = this as MembershipRecord;
  return 'MembershipRecord(id: ${_this.id}, planName: ${_this.planName}, startsAtIso: ${_this.startsAtIso}, expiresAtIso: ${_this.expiresAtIso}, status: ${_this.status}, lapsed: ${_this.lapsed})';
}


}

/// @nodoc
abstract mixin class $MembershipRecordCopyWith<$Res>  {
  factory $MembershipRecordCopyWith(MembershipRecord value, $Res Function(MembershipRecord) _then) = _$MembershipRecordCopyWithImpl;
@useResult
$Res call({
 int id, String? planName, String startsAtIso, String expiresAtIso, String? status, bool lapsed
});




}
/// @nodoc
class _$MembershipRecordCopyWithImpl<$Res>
    implements $MembershipRecordCopyWith<$Res> {
  _$MembershipRecordCopyWithImpl(this._self, this._then);

  final MembershipRecord _self;
  final $Res Function(MembershipRecord) _then;

/// Create a copy of MembershipRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planName = freezed,Object? startsAtIso = null,Object? expiresAtIso = null,Object? status = freezed,Object? lapsed = null,}) {
  return _then(MembershipRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,startsAtIso: null == startsAtIso ? _self.startsAtIso : startsAtIso // ignore: cast_nullable_to_non_nullable
as String,expiresAtIso: null == expiresAtIso ? _self.expiresAtIso : expiresAtIso // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,lapsed: null == lapsed ? _self.lapsed : lapsed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipRecord].
extension MembershipRecordPatterns on MembershipRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipRecord value)  $default,){
final _that = this;
switch (_that) {
case _MembershipRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipRecord value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? planName,  String startsAtIso,  String expiresAtIso,  String? status,  bool lapsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipRecord() when $default != null:
return $default(_that.id,_that.planName,_that.startsAtIso,_that.expiresAtIso,_that.status,_that.lapsed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? planName,  String startsAtIso,  String expiresAtIso,  String? status,  bool lapsed)  $default,) {final _that = this;
switch (_that) {
case _MembershipRecord():
return $default(_that.id,_that.planName,_that.startsAtIso,_that.expiresAtIso,_that.status,_that.lapsed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? planName,  String startsAtIso,  String expiresAtIso,  String? status,  bool lapsed)?  $default,) {final _that = this;
switch (_that) {
case _MembershipRecord() when $default != null:
return $default(_that.id,_that.planName,_that.startsAtIso,_that.expiresAtIso,_that.status,_that.lapsed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipRecord implements MembershipRecord {
  const _MembershipRecord({required this.id, this.planName, required this.startsAtIso, required this.expiresAtIso, this.status, this.lapsed = false});
  factory _MembershipRecord.fromJson(Map<String, dynamic> json) => _$MembershipRecordFromJson(json);

@override final  int id;
@override final  String? planName;
@override final  String startsAtIso;
@override final  String expiresAtIso;
@override final  String? status;
@override@JsonKey() final  bool lapsed;

/// Create a copy of MembershipRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipRecordCopyWith<_MembershipRecord> get copyWith => __$MembershipRecordCopyWithImpl<_MembershipRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipRecordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.startsAtIso, startsAtIso) || other.startsAtIso == startsAtIso)&&(identical(other.expiresAtIso, expiresAtIso) || other.expiresAtIso == expiresAtIso)&&(identical(other.status, status) || other.status == status)&&(identical(other.lapsed, lapsed) || other.lapsed == lapsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,planName,startsAtIso,expiresAtIso,status,lapsed);
}

@override
String toString() {
    return 'MembershipRecord(id: $id, planName: $planName, startsAtIso: $startsAtIso, expiresAtIso: $expiresAtIso, status: $status, lapsed: $lapsed)';
}


}

/// @nodoc
abstract mixin class _$MembershipRecordCopyWith<$Res> implements $MembershipRecordCopyWith<$Res> {
  factory _$MembershipRecordCopyWith(_MembershipRecord value, $Res Function(_MembershipRecord) _then) = __$MembershipRecordCopyWithImpl;
@override @useResult
$Res call({
 int id, String? planName, String startsAtIso, String expiresAtIso, String? status, bool lapsed
});




}
/// @nodoc
class __$MembershipRecordCopyWithImpl<$Res>
    implements _$MembershipRecordCopyWith<$Res> {
  __$MembershipRecordCopyWithImpl(this._self, this._then);

  final _MembershipRecord _self;
  final $Res Function(_MembershipRecord) _then;

/// Create a copy of MembershipRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planName = freezed,Object? startsAtIso = null,Object? expiresAtIso = null,Object? status = freezed,Object? lapsed = null,}) {
  return _then(_MembershipRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,startsAtIso: null == startsAtIso ? _self.startsAtIso : startsAtIso // ignore: cast_nullable_to_non_nullable
as String,expiresAtIso: null == expiresAtIso ? _self.expiresAtIso : expiresAtIso // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,lapsed: null == lapsed ? _self.lapsed : lapsed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
