// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Plate {

 String get id; String? get userId; String get plateNumber; String? get stateOrRegion; DateTime? get claimedAt; bool get isActive; DateTime get createdAt;
/// Create a copy of Plate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlateCopyWith<Plate> get copyWith => _$PlateCopyWithImpl<Plate>(this as Plate, _$identity);

  /// Serializes this Plate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Plate&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.stateOrRegion, stateOrRegion) || other.stateOrRegion == stateOrRegion)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,plateNumber,stateOrRegion,claimedAt,isActive,createdAt);

@override
String toString() {
  return 'Plate(id: $id, userId: $userId, plateNumber: $plateNumber, stateOrRegion: $stateOrRegion, claimedAt: $claimedAt, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlateCopyWith<$Res>  {
  factory $PlateCopyWith(Plate value, $Res Function(Plate) _then) = _$PlateCopyWithImpl;
@useResult
$Res call({
 String id, String? userId, String plateNumber, String? stateOrRegion, DateTime? claimedAt, bool isActive, DateTime createdAt
});




}
/// @nodoc
class _$PlateCopyWithImpl<$Res>
    implements $PlateCopyWith<$Res> {
  _$PlateCopyWithImpl(this._self, this._then);

  final Plate _self;
  final $Res Function(Plate) _then;

/// Create a copy of Plate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? plateNumber = null,Object? stateOrRegion = freezed,Object? claimedAt = freezed,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,stateOrRegion: freezed == stateOrRegion ? _self.stateOrRegion : stateOrRegion // ignore: cast_nullable_to_non_nullable
as String?,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Plate].
extension PlatePatterns on Plate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Plate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Plate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Plate value)  $default,){
final _that = this;
switch (_that) {
case _Plate():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Plate value)?  $default,){
final _that = this;
switch (_that) {
case _Plate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? userId,  String plateNumber,  String? stateOrRegion,  DateTime? claimedAt,  bool isActive,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Plate() when $default != null:
return $default(_that.id,_that.userId,_that.plateNumber,_that.stateOrRegion,_that.claimedAt,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? userId,  String plateNumber,  String? stateOrRegion,  DateTime? claimedAt,  bool isActive,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Plate():
return $default(_that.id,_that.userId,_that.plateNumber,_that.stateOrRegion,_that.claimedAt,_that.isActive,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? userId,  String plateNumber,  String? stateOrRegion,  DateTime? claimedAt,  bool isActive,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Plate() when $default != null:
return $default(_that.id,_that.userId,_that.plateNumber,_that.stateOrRegion,_that.claimedAt,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Plate implements Plate {
  const _Plate({required this.id, this.userId, required this.plateNumber, this.stateOrRegion, this.claimedAt, this.isActive = true, required this.createdAt});
  factory _Plate.fromJson(Map<String, dynamic> json) => _$PlateFromJson(json);

@override final  String id;
@override final  String? userId;
@override final  String plateNumber;
@override final  String? stateOrRegion;
@override final  DateTime? claimedAt;
@override@JsonKey() final  bool isActive;
@override final  DateTime createdAt;

/// Create a copy of Plate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlateCopyWith<_Plate> get copyWith => __$PlateCopyWithImpl<_Plate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Plate&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.stateOrRegion, stateOrRegion) || other.stateOrRegion == stateOrRegion)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,plateNumber,stateOrRegion,claimedAt,isActive,createdAt);

@override
String toString() {
  return 'Plate(id: $id, userId: $userId, plateNumber: $plateNumber, stateOrRegion: $stateOrRegion, claimedAt: $claimedAt, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlateCopyWith<$Res> implements $PlateCopyWith<$Res> {
  factory _$PlateCopyWith(_Plate value, $Res Function(_Plate) _then) = __$PlateCopyWithImpl;
@override @useResult
$Res call({
 String id, String? userId, String plateNumber, String? stateOrRegion, DateTime? claimedAt, bool isActive, DateTime createdAt
});




}
/// @nodoc
class __$PlateCopyWithImpl<$Res>
    implements _$PlateCopyWith<$Res> {
  __$PlateCopyWithImpl(this._self, this._then);

  final _Plate _self;
  final $Res Function(_Plate) _then;

/// Create a copy of Plate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? plateNumber = null,Object? stateOrRegion = freezed,Object? claimedAt = freezed,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_Plate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,stateOrRegion: freezed == stateOrRegion ? _self.stateOrRegion : stateOrRegion // ignore: cast_nullable_to_non_nullable
as String?,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
