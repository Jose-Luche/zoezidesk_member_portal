// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberSummary {

 int get id; String get name; String? get memberNumber; String? get phone; String? get email; String? get gymName; String? get status;
/// Create a copy of MemberSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberSummaryCopyWith<MemberSummary> get copyWith => _$MemberSummaryCopyWithImpl<MemberSummary>(this as MemberSummary, _$identity);

  /// Serializes this MemberSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.memberNumber, _this.memberNumber) || other.memberNumber == _this.memberNumber)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.gymName, _this.gymName) || other.gymName == _this.gymName)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.memberNumber,_this.phone,_this.email,_this.gymName,_this.status);
}

@override
String toString() {
  final _this = this as MemberSummary;
  return 'MemberSummary(id: ${_this.id}, name: ${_this.name}, memberNumber: ${_this.memberNumber}, phone: ${_this.phone}, email: ${_this.email}, gymName: ${_this.gymName}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $MemberSummaryCopyWith<$Res>  {
  factory $MemberSummaryCopyWith(MemberSummary value, $Res Function(MemberSummary) _then) = _$MemberSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? memberNumber, String? phone, String? email, String? gymName, String? status
});




}
/// @nodoc
class _$MemberSummaryCopyWithImpl<$Res>
    implements $MemberSummaryCopyWith<$Res> {
  _$MemberSummaryCopyWithImpl(this._self, this._then);

  final MemberSummary _self;
  final $Res Function(MemberSummary) _then;

/// Create a copy of MemberSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? phone = freezed,Object? email = freezed,Object? gymName = freezed,Object? status = freezed,}) {
  return _then(MemberSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberSummary].
extension MemberSummaryPatterns on MemberSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberSummary value)  $default,){
final _that = this;
switch (_that) {
case _MemberSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MemberSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gymName,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberSummary() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gymName,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gymName,  String? status)  $default,) {final _that = this;
switch (_that) {
case _MemberSummary():
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gymName,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? memberNumber,  String? phone,  String? email,  String? gymName,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _MemberSummary() when $default != null:
return $default(_that.id,_that.name,_that.memberNumber,_that.phone,_that.email,_that.gymName,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberSummary implements MemberSummary {
  const _MemberSummary({required this.id, required this.name, this.memberNumber, this.phone, this.email, this.gymName, this.status});
  factory _MemberSummary.fromJson(Map<String, dynamic> json) => _$MemberSummaryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? memberNumber;
@override final  String? phone;
@override final  String? email;
@override final  String? gymName;
@override final  String? status;

/// Create a copy of MemberSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberSummaryCopyWith<_MemberSummary> get copyWith => __$MemberSummaryCopyWithImpl<_MemberSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.gymName, gymName) || other.gymName == gymName)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,memberNumber,phone,email,gymName,status);
}

@override
String toString() {
    return 'MemberSummary(id: $id, name: $name, memberNumber: $memberNumber, phone: $phone, email: $email, gymName: $gymName, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MemberSummaryCopyWith<$Res> implements $MemberSummaryCopyWith<$Res> {
  factory _$MemberSummaryCopyWith(_MemberSummary value, $Res Function(_MemberSummary) _then) = __$MemberSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? memberNumber, String? phone, String? email, String? gymName, String? status
});




}
/// @nodoc
class __$MemberSummaryCopyWithImpl<$Res>
    implements _$MemberSummaryCopyWith<$Res> {
  __$MemberSummaryCopyWithImpl(this._self, this._then);

  final _MemberSummary _self;
  final $Res Function(_MemberSummary) _then;

/// Create a copy of MemberSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberNumber = freezed,Object? phone = freezed,Object? email = freezed,Object? gymName = freezed,Object? status = freezed,}) {
  return _then(_MemberSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,gymName: freezed == gymName ? _self.gymName : gymName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
