// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InboxMessage {

 String get id; String get senderDisplayName; String? get subject; String get body; String get recipientPlateId; bool get isRead; DateTime get createdAt;
/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxMessageCopyWith<InboxMessage> get copyWith => _$InboxMessageCopyWithImpl<InboxMessage>(this as InboxMessage, _$identity);

  /// Serializes this InboxMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.body, body) || other.body == body)&&(identical(other.recipientPlateId, recipientPlateId) || other.recipientPlateId == recipientPlateId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderDisplayName,subject,body,recipientPlateId,isRead,createdAt);

@override
String toString() {
  return 'InboxMessage(id: $id, senderDisplayName: $senderDisplayName, subject: $subject, body: $body, recipientPlateId: $recipientPlateId, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InboxMessageCopyWith<$Res>  {
  factory $InboxMessageCopyWith(InboxMessage value, $Res Function(InboxMessage) _then) = _$InboxMessageCopyWithImpl;
@useResult
$Res call({
 String id, String senderDisplayName, String? subject, String body, String recipientPlateId, bool isRead, DateTime createdAt
});




}
/// @nodoc
class _$InboxMessageCopyWithImpl<$Res>
    implements $InboxMessageCopyWith<$Res> {
  _$InboxMessageCopyWithImpl(this._self, this._then);

  final InboxMessage _self;
  final $Res Function(InboxMessage) _then;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderDisplayName = null,Object? subject = freezed,Object? body = null,Object? recipientPlateId = null,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,recipientPlateId: null == recipientPlateId ? _self.recipientPlateId : recipientPlateId // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxMessage].
extension InboxMessagePatterns on InboxMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxMessage value)  $default,){
final _that = this;
switch (_that) {
case _InboxMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxMessage value)?  $default,){
final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderDisplayName,  String? subject,  String body,  String recipientPlateId,  bool isRead,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
return $default(_that.id,_that.senderDisplayName,_that.subject,_that.body,_that.recipientPlateId,_that.isRead,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderDisplayName,  String? subject,  String body,  String recipientPlateId,  bool isRead,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InboxMessage():
return $default(_that.id,_that.senderDisplayName,_that.subject,_that.body,_that.recipientPlateId,_that.isRead,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderDisplayName,  String? subject,  String body,  String recipientPlateId,  bool isRead,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InboxMessage() when $default != null:
return $default(_that.id,_that.senderDisplayName,_that.subject,_that.body,_that.recipientPlateId,_that.isRead,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxMessage implements InboxMessage {
  const _InboxMessage({required this.id, required this.senderDisplayName, this.subject, required this.body, required this.recipientPlateId, this.isRead = false, required this.createdAt});
  factory _InboxMessage.fromJson(Map<String, dynamic> json) => _$InboxMessageFromJson(json);

@override final  String id;
@override final  String senderDisplayName;
@override final  String? subject;
@override final  String body;
@override final  String recipientPlateId;
@override@JsonKey() final  bool isRead;
@override final  DateTime createdAt;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxMessageCopyWith<_InboxMessage> get copyWith => __$InboxMessageCopyWithImpl<_InboxMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.body, body) || other.body == body)&&(identical(other.recipientPlateId, recipientPlateId) || other.recipientPlateId == recipientPlateId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderDisplayName,subject,body,recipientPlateId,isRead,createdAt);

@override
String toString() {
  return 'InboxMessage(id: $id, senderDisplayName: $senderDisplayName, subject: $subject, body: $body, recipientPlateId: $recipientPlateId, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InboxMessageCopyWith<$Res> implements $InboxMessageCopyWith<$Res> {
  factory _$InboxMessageCopyWith(_InboxMessage value, $Res Function(_InboxMessage) _then) = __$InboxMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderDisplayName, String? subject, String body, String recipientPlateId, bool isRead, DateTime createdAt
});




}
/// @nodoc
class __$InboxMessageCopyWithImpl<$Res>
    implements _$InboxMessageCopyWith<$Res> {
  __$InboxMessageCopyWithImpl(this._self, this._then);

  final _InboxMessage _self;
  final $Res Function(_InboxMessage) _then;

/// Create a copy of InboxMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderDisplayName = null,Object? subject = freezed,Object? body = null,Object? recipientPlateId = null,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_InboxMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,recipientPlateId: null == recipientPlateId ? _self.recipientPlateId : recipientPlateId // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
