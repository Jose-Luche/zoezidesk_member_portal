// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'builder_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuilderInputs {

 String get energyLevel; int get timeMinutes; List<String> get focusMuscles; List<String> get excludedMuscles; List<String> get equipment; String get goal; String get experienceLevel;
/// Create a copy of BuilderInputs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuilderInputsCopyWith<BuilderInputs> get copyWith => _$BuilderInputsCopyWithImpl<BuilderInputs>(this as BuilderInputs, _$identity);

  /// Serializes this BuilderInputs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuilderInputs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuilderInputs&&(identical(other.energyLevel, _this.energyLevel) || other.energyLevel == _this.energyLevel)&&(identical(other.timeMinutes, _this.timeMinutes) || other.timeMinutes == _this.timeMinutes)&&const DeepCollectionEquality().equals(other.focusMuscles, _this.focusMuscles)&&const DeepCollectionEquality().equals(other.excludedMuscles, _this.excludedMuscles)&&const DeepCollectionEquality().equals(other.equipment, _this.equipment)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.experienceLevel, _this.experienceLevel) || other.experienceLevel == _this.experienceLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuilderInputs;
  return Object.hash(runtimeType,_this.energyLevel,_this.timeMinutes,const DeepCollectionEquality().hash(_this.focusMuscles),const DeepCollectionEquality().hash(_this.excludedMuscles),const DeepCollectionEquality().hash(_this.equipment),_this.goal,_this.experienceLevel);
}

@override
String toString() {
  final _this = this as BuilderInputs;
  return 'BuilderInputs(energyLevel: ${_this.energyLevel}, timeMinutes: ${_this.timeMinutes}, focusMuscles: ${_this.focusMuscles}, excludedMuscles: ${_this.excludedMuscles}, equipment: ${_this.equipment}, goal: ${_this.goal}, experienceLevel: ${_this.experienceLevel})';
}


}

/// @nodoc
abstract mixin class $BuilderInputsCopyWith<$Res>  {
  factory $BuilderInputsCopyWith(BuilderInputs value, $Res Function(BuilderInputs) _then) = _$BuilderInputsCopyWithImpl;
@useResult
$Res call({
 String energyLevel, int timeMinutes, List<String> focusMuscles, List<String> excludedMuscles, List<String> equipment, String goal, String experienceLevel
});




}
/// @nodoc
class _$BuilderInputsCopyWithImpl<$Res>
    implements $BuilderInputsCopyWith<$Res> {
  _$BuilderInputsCopyWithImpl(this._self, this._then);

  final BuilderInputs _self;
  final $Res Function(BuilderInputs) _then;

/// Create a copy of BuilderInputs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? energyLevel = null,Object? timeMinutes = null,Object? focusMuscles = null,Object? excludedMuscles = null,Object? equipment = null,Object? goal = null,Object? experienceLevel = null,}) {
  return _then(BuilderInputs(
energyLevel: null == energyLevel ? _self.energyLevel : energyLevel // ignore: cast_nullable_to_non_nullable
as String,timeMinutes: null == timeMinutes ? _self.timeMinutes : timeMinutes // ignore: cast_nullable_to_non_nullable
as int,focusMuscles: null == focusMuscles ? _self.focusMuscles : focusMuscles // ignore: cast_nullable_to_non_nullable
as List<String>,excludedMuscles: null == excludedMuscles ? _self.excludedMuscles : excludedMuscles // ignore: cast_nullable_to_non_nullable
as List<String>,equipment: null == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<String>,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuilderInputs].
extension BuilderInputsPatterns on BuilderInputs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuilderInputs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuilderInputs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuilderInputs value)  $default,){
final _that = this;
switch (_that) {
case _BuilderInputs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuilderInputs value)?  $default,){
final _that = this;
switch (_that) {
case _BuilderInputs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String energyLevel,  int timeMinutes,  List<String> focusMuscles,  List<String> excludedMuscles,  List<String> equipment,  String goal,  String experienceLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuilderInputs() when $default != null:
return $default(_that.energyLevel,_that.timeMinutes,_that.focusMuscles,_that.excludedMuscles,_that.equipment,_that.goal,_that.experienceLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String energyLevel,  int timeMinutes,  List<String> focusMuscles,  List<String> excludedMuscles,  List<String> equipment,  String goal,  String experienceLevel)  $default,) {final _that = this;
switch (_that) {
case _BuilderInputs():
return $default(_that.energyLevel,_that.timeMinutes,_that.focusMuscles,_that.excludedMuscles,_that.equipment,_that.goal,_that.experienceLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String energyLevel,  int timeMinutes,  List<String> focusMuscles,  List<String> excludedMuscles,  List<String> equipment,  String goal,  String experienceLevel)?  $default,) {final _that = this;
switch (_that) {
case _BuilderInputs() when $default != null:
return $default(_that.energyLevel,_that.timeMinutes,_that.focusMuscles,_that.excludedMuscles,_that.equipment,_that.goal,_that.experienceLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuilderInputs implements BuilderInputs {
  const _BuilderInputs({this.energyLevel = 'medium', this.timeMinutes = 45,  List<String> focusMuscles = const [],  List<String> excludedMuscles = const [],  List<String> equipment = const [], this.goal = 'stay_active', this.experienceLevel = 'beginner'}): _focusMuscles = focusMuscles,_excludedMuscles = excludedMuscles,_equipment = equipment;
  factory _BuilderInputs.fromJson(Map<String, dynamic> json) => _$BuilderInputsFromJson(json);

@override@JsonKey() final  String energyLevel;
@override@JsonKey() final  int timeMinutes;
 final  List<String> _focusMuscles;
@override@JsonKey() List<String> get focusMuscles {
  if (_focusMuscles is EqualUnmodifiableListView) return _focusMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_focusMuscles);
}

 final  List<String> _excludedMuscles;
@override@JsonKey() List<String> get excludedMuscles {
  if (_excludedMuscles is EqualUnmodifiableListView) return _excludedMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludedMuscles);
}

 final  List<String> _equipment;
@override@JsonKey() List<String> get equipment {
  if (_equipment is EqualUnmodifiableListView) return _equipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equipment);
}

@override@JsonKey() final  String goal;
@override@JsonKey() final  String experienceLevel;

/// Create a copy of BuilderInputs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuilderInputsCopyWith<_BuilderInputs> get copyWith => __$BuilderInputsCopyWithImpl<_BuilderInputs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuilderInputsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuilderInputs&&(identical(other.energyLevel, energyLevel) || other.energyLevel == energyLevel)&&(identical(other.timeMinutes, timeMinutes) || other.timeMinutes == timeMinutes)&&const DeepCollectionEquality().equals(other.focusMuscles, _focusMuscles)&&const DeepCollectionEquality().equals(other.excludedMuscles, _excludedMuscles)&&const DeepCollectionEquality().equals(other.equipment, _equipment)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.experienceLevel, experienceLevel) || other.experienceLevel == experienceLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,energyLevel,timeMinutes,const DeepCollectionEquality().hash(_focusMuscles),const DeepCollectionEquality().hash(_excludedMuscles),const DeepCollectionEquality().hash(_equipment),goal,experienceLevel);
}

@override
String toString() {
    return 'BuilderInputs(energyLevel: $energyLevel, timeMinutes: $timeMinutes, focusMuscles: $focusMuscles, excludedMuscles: $excludedMuscles, equipment: $equipment, goal: $goal, experienceLevel: $experienceLevel)';
}


}

/// @nodoc
abstract mixin class _$BuilderInputsCopyWith<$Res> implements $BuilderInputsCopyWith<$Res> {
  factory _$BuilderInputsCopyWith(_BuilderInputs value, $Res Function(_BuilderInputs) _then) = __$BuilderInputsCopyWithImpl;
@override @useResult
$Res call({
 String energyLevel, int timeMinutes, List<String> focusMuscles, List<String> excludedMuscles, List<String> equipment, String goal, String experienceLevel
});




}
/// @nodoc
class __$BuilderInputsCopyWithImpl<$Res>
    implements _$BuilderInputsCopyWith<$Res> {
  __$BuilderInputsCopyWithImpl(this._self, this._then);

  final _BuilderInputs _self;
  final $Res Function(_BuilderInputs) _then;

/// Create a copy of BuilderInputs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? energyLevel = null,Object? timeMinutes = null,Object? focusMuscles = null,Object? excludedMuscles = null,Object? equipment = null,Object? goal = null,Object? experienceLevel = null,}) {
  return _then(_BuilderInputs(
energyLevel: null == energyLevel ? _self.energyLevel : energyLevel // ignore: cast_nullable_to_non_nullable
as String,timeMinutes: null == timeMinutes ? _self.timeMinutes : timeMinutes // ignore: cast_nullable_to_non_nullable
as int,focusMuscles: null == focusMuscles ? _self._focusMuscles : focusMuscles // ignore: cast_nullable_to_non_nullable
as List<String>,excludedMuscles: null == excludedMuscles ? _self._excludedMuscles : excludedMuscles // ignore: cast_nullable_to_non_nullable
as List<String>,equipment: null == equipment ? _self._equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<String>,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as String,experienceLevel: null == experienceLevel ? _self.experienceLevel : experienceLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SuggestedMuscle {

 String get key; String get label; String? get reason;
/// Create a copy of SuggestedMuscle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuggestedMuscleCopyWith<SuggestedMuscle> get copyWith => _$SuggestedMuscleCopyWithImpl<SuggestedMuscle>(this as SuggestedMuscle, _$identity);

  /// Serializes this SuggestedMuscle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SuggestedMuscle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuggestedMuscle&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SuggestedMuscle;
  return Object.hash(runtimeType,_this.key,_this.label,_this.reason);
}

@override
String toString() {
  final _this = this as SuggestedMuscle;
  return 'SuggestedMuscle(key: ${_this.key}, label: ${_this.label}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $SuggestedMuscleCopyWith<$Res>  {
  factory $SuggestedMuscleCopyWith(SuggestedMuscle value, $Res Function(SuggestedMuscle) _then) = _$SuggestedMuscleCopyWithImpl;
@useResult
$Res call({
 String key, String label, String? reason
});




}
/// @nodoc
class _$SuggestedMuscleCopyWithImpl<$Res>
    implements $SuggestedMuscleCopyWith<$Res> {
  _$SuggestedMuscleCopyWithImpl(this._self, this._then);

  final SuggestedMuscle _self;
  final $Res Function(SuggestedMuscle) _then;

/// Create a copy of SuggestedMuscle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? reason = freezed,}) {
  return _then(SuggestedMuscle(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SuggestedMuscle].
extension SuggestedMusclePatterns on SuggestedMuscle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuggestedMuscle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuggestedMuscle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuggestedMuscle value)  $default,){
final _that = this;
switch (_that) {
case _SuggestedMuscle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuggestedMuscle value)?  $default,){
final _that = this;
switch (_that) {
case _SuggestedMuscle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuggestedMuscle() when $default != null:
return $default(_that.key,_that.label,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _SuggestedMuscle():
return $default(_that.key,_that.label,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _SuggestedMuscle() when $default != null:
return $default(_that.key,_that.label,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SuggestedMuscle implements SuggestedMuscle {
  const _SuggestedMuscle({required this.key, required this.label, this.reason});
  factory _SuggestedMuscle.fromJson(Map<String, dynamic> json) => _$SuggestedMuscleFromJson(json);

@override final  String key;
@override final  String label;
@override final  String? reason;

/// Create a copy of SuggestedMuscle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuggestedMuscleCopyWith<_SuggestedMuscle> get copyWith => __$SuggestedMuscleCopyWithImpl<_SuggestedMuscle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuggestedMuscleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuggestedMuscle&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,label,reason);
}

@override
String toString() {
    return 'SuggestedMuscle(key: $key, label: $label, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$SuggestedMuscleCopyWith<$Res> implements $SuggestedMuscleCopyWith<$Res> {
  factory _$SuggestedMuscleCopyWith(_SuggestedMuscle value, $Res Function(_SuggestedMuscle) _then) = __$SuggestedMuscleCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, String? reason
});




}
/// @nodoc
class __$SuggestedMuscleCopyWithImpl<$Res>
    implements _$SuggestedMuscleCopyWith<$Res> {
  __$SuggestedMuscleCopyWithImpl(this._self, this._then);

  final _SuggestedMuscle _self;
  final $Res Function(_SuggestedMuscle) _then;

/// Create a copy of SuggestedMuscle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? reason = freezed,}) {
  return _then(_SuggestedMuscle(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
