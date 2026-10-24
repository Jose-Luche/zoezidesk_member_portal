// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OtpRequestResult {

 bool get success; String? get message; String? get debugCode;
/// Create a copy of OtpRequestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpRequestResultCopyWith<OtpRequestResult> get copyWith => _$OtpRequestResultCopyWithImpl<OtpRequestResult>(this as OtpRequestResult, _$identity);

  /// Serializes this OtpRequestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OtpRequestResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpRequestResult&&(identical(other.success, _this.success) || other.success == _this.success)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.debugCode, _this.debugCode) || other.debugCode == _this.debugCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OtpRequestResult;
  return Object.hash(runtimeType,_this.success,_this.message,_this.debugCode);
}

@override
String toString() {
  final _this = this as OtpRequestResult;
  return 'OtpRequestResult(success: ${_this.success}, message: ${_this.message}, debugCode: ${_this.debugCode})';
}


}

/// @nodoc
abstract mixin class $OtpRequestResultCopyWith<$Res>  {
  factory $OtpRequestResultCopyWith(OtpRequestResult value, $Res Function(OtpRequestResult) _then) = _$OtpRequestResultCopyWithImpl;
@useResult
$Res call({
 bool success, String? message, String? debugCode
});




}
/// @nodoc
class _$OtpRequestResultCopyWithImpl<$Res>
    implements $OtpRequestResultCopyWith<$Res> {
  _$OtpRequestResultCopyWithImpl(this._self, this._then);

  final OtpRequestResult _self;
  final $Res Function(OtpRequestResult) _then;

/// Create a copy of OtpRequestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? message = freezed,Object? debugCode = freezed,}) {
  return _then(OtpRequestResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,debugCode: freezed == debugCode ? _self.debugCode : debugCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpRequestResult].
extension OtpRequestResultPatterns on OtpRequestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpRequestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpRequestResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpRequestResult value)  $default,){
final _that = this;
switch (_that) {
case _OtpRequestResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpRequestResult value)?  $default,){
final _that = this;
switch (_that) {
case _OtpRequestResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String? message,  String? debugCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpRequestResult() when $default != null:
return $default(_that.success,_that.message,_that.debugCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String? message,  String? debugCode)  $default,) {final _that = this;
switch (_that) {
case _OtpRequestResult():
return $default(_that.success,_that.message,_that.debugCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String? message,  String? debugCode)?  $default,) {final _that = this;
switch (_that) {
case _OtpRequestResult() when $default != null:
return $default(_that.success,_that.message,_that.debugCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OtpRequestResult implements OtpRequestResult {
  const _OtpRequestResult({this.success = false, this.message, this.debugCode});
  factory _OtpRequestResult.fromJson(Map<String, dynamic> json) => _$OtpRequestResultFromJson(json);

@override@JsonKey() final  bool success;
@override final  String? message;
@override final  String? debugCode;

/// Create a copy of OtpRequestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpRequestResultCopyWith<_OtpRequestResult> get copyWith => __$OtpRequestResultCopyWithImpl<_OtpRequestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OtpRequestResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpRequestResult&&(identical(other.success, success) || other.success == success)&&(identical(other.message, message) || other.message == message)&&(identical(other.debugCode, debugCode) || other.debugCode == debugCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,success,message,debugCode);
}

@override
String toString() {
    return 'OtpRequestResult(success: $success, message: $message, debugCode: $debugCode)';
}


}

/// @nodoc
abstract mixin class _$OtpRequestResultCopyWith<$Res> implements $OtpRequestResultCopyWith<$Res> {
  factory _$OtpRequestResultCopyWith(_OtpRequestResult value, $Res Function(_OtpRequestResult) _then) = __$OtpRequestResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, String? message, String? debugCode
});




}
/// @nodoc
class __$OtpRequestResultCopyWithImpl<$Res>
    implements _$OtpRequestResultCopyWith<$Res> {
  __$OtpRequestResultCopyWithImpl(this._self, this._then);

  final _OtpRequestResult _self;
  final $Res Function(_OtpRequestResult) _then;

/// Create a copy of OtpRequestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? message = freezed,Object? debugCode = freezed,}) {
  return _then(_OtpRequestResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,debugCode: freezed == debugCode ? _self.debugCode : debugCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LoginResult {

 String get token; String? get refreshToken; MemberSummary get member;
/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginResultCopyWith<LoginResult> get copyWith => _$LoginResultCopyWithImpl<LoginResult>(this as LoginResult, _$identity);

  /// Serializes this LoginResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LoginResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginResult&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.member, _this.member) || other.member == _this.member));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginResult;
  return Object.hash(runtimeType,_this.token,_this.refreshToken,_this.member);
}

@override
String toString() {
  final _this = this as LoginResult;
  return 'LoginResult(token: ${_this.token}, refreshToken: ${_this.refreshToken}, member: ${_this.member})';
}


}

/// @nodoc
abstract mixin class $LoginResultCopyWith<$Res>  {
  factory $LoginResultCopyWith(LoginResult value, $Res Function(LoginResult) _then) = _$LoginResultCopyWithImpl;
@useResult
$Res call({
 String token, String? refreshToken, MemberSummary member
});


$MemberSummaryCopyWith<$Res> get member;

}
/// @nodoc
class _$LoginResultCopyWithImpl<$Res>
    implements $LoginResultCopyWith<$Res> {
  _$LoginResultCopyWithImpl(this._self, this._then);

  final LoginResult _self;
  final $Res Function(LoginResult) _then;

/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? refreshToken = freezed,Object? member = null,}) {
  return _then(LoginResult(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as MemberSummary,
  ));
}
/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberSummaryCopyWith<$Res> get member {
  
  return $MemberSummaryCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}


/// Adds pattern-matching-related methods to [LoginResult].
extension LoginResultPatterns on LoginResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginResult value)  $default,){
final _that = this;
switch (_that) {
case _LoginResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginResult value)?  $default,){
final _that = this;
switch (_that) {
case _LoginResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String? refreshToken,  MemberSummary member)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginResult() when $default != null:
return $default(_that.token,_that.refreshToken,_that.member);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String? refreshToken,  MemberSummary member)  $default,) {final _that = this;
switch (_that) {
case _LoginResult():
return $default(_that.token,_that.refreshToken,_that.member);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String? refreshToken,  MemberSummary member)?  $default,) {final _that = this;
switch (_that) {
case _LoginResult() when $default != null:
return $default(_that.token,_that.refreshToken,_that.member);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginResult implements LoginResult {
  const _LoginResult({required this.token, this.refreshToken, required this.member});
  factory _LoginResult.fromJson(Map<String, dynamic> json) => _$LoginResultFromJson(json);

@override final  String token;
@override final  String? refreshToken;
@override final  MemberSummary member;

/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginResultCopyWith<_LoginResult> get copyWith => __$LoginResultCopyWithImpl<_LoginResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginResult&&(identical(other.token, token) || other.token == token)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.member, member) || other.member == member));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,token,refreshToken,member);
}

@override
String toString() {
    return 'LoginResult(token: $token, refreshToken: $refreshToken, member: $member)';
}


}

/// @nodoc
abstract mixin class _$LoginResultCopyWith<$Res> implements $LoginResultCopyWith<$Res> {
  factory _$LoginResultCopyWith(_LoginResult value, $Res Function(_LoginResult) _then) = __$LoginResultCopyWithImpl;
@override @useResult
$Res call({
 String token, String? refreshToken, MemberSummary member
});


@override $MemberSummaryCopyWith<$Res> get member;

}
/// @nodoc
class __$LoginResultCopyWithImpl<$Res>
    implements _$LoginResultCopyWith<$Res> {
  __$LoginResultCopyWithImpl(this._self, this._then);

  final _LoginResult _self;
  final $Res Function(_LoginResult) _then;

/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? refreshToken = freezed,Object? member = null,}) {
  return _then(_LoginResult(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as MemberSummary,
  ));
}

/// Create a copy of LoginResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberSummaryCopyWith<$Res> get member {
  
  return $MemberSummaryCopyWith<$Res>(_self.member, (value) {
    return _then(_self.copyWith(member: value));
  });
}
}

// dart format on
