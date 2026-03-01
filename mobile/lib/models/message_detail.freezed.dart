// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageSender {

 String get id; String get displayName;
/// Create a copy of MessageSender
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageSenderCopyWith<MessageSender> get copyWith => _$MessageSenderCopyWithImpl<MessageSender>(this as MessageSender, _$identity);

  /// Serializes this MessageSender to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageSender&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'MessageSender(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $MessageSenderCopyWith<$Res>  {
  factory $MessageSenderCopyWith(MessageSender value, $Res Function(MessageSender) _then) = _$MessageSenderCopyWithImpl;
@useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class _$MessageSenderCopyWithImpl<$Res>
    implements $MessageSenderCopyWith<$Res> {
  _$MessageSenderCopyWithImpl(this._self, this._then);

  final MessageSender _self;
  final $Res Function(MessageSender) _then;

/// Create a copy of MessageSender
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageSender].
extension MessageSenderPatterns on MessageSender {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageSender value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageSender() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageSender value)  $default,){
final _that = this;
switch (_that) {
case _MessageSender():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageSender value)?  $default,){
final _that = this;
switch (_that) {
case _MessageSender() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageSender() when $default != null:
return $default(_that.id,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _MessageSender():
return $default(_that.id,_that.displayName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _MessageSender() when $default != null:
return $default(_that.id,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageSender implements MessageSender {
  const _MessageSender({required this.id, required this.displayName});
  factory _MessageSender.fromJson(Map<String, dynamic> json) => _$MessageSenderFromJson(json);

@override final  String id;
@override final  String displayName;

/// Create a copy of MessageSender
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageSenderCopyWith<_MessageSender> get copyWith => __$MessageSenderCopyWithImpl<_MessageSender>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageSenderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageSender&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'MessageSender(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$MessageSenderCopyWith<$Res> implements $MessageSenderCopyWith<$Res> {
  factory _$MessageSenderCopyWith(_MessageSender value, $Res Function(_MessageSender) _then) = __$MessageSenderCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class __$MessageSenderCopyWithImpl<$Res>
    implements _$MessageSenderCopyWith<$Res> {
  __$MessageSenderCopyWithImpl(this._self, this._then);

  final _MessageSender _self;
  final $Res Function(_MessageSender) _then;

/// Create a copy of MessageSender
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_MessageSender(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MessageRecipientPlate {

 String get id; String get plateNumber;
/// Create a copy of MessageRecipientPlate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageRecipientPlateCopyWith<MessageRecipientPlate> get copyWith => _$MessageRecipientPlateCopyWithImpl<MessageRecipientPlate>(this as MessageRecipientPlate, _$identity);

  /// Serializes this MessageRecipientPlate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageRecipientPlate&&(identical(other.id, id) || other.id == id)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plateNumber);

@override
String toString() {
  return 'MessageRecipientPlate(id: $id, plateNumber: $plateNumber)';
}


}

/// @nodoc
abstract mixin class $MessageRecipientPlateCopyWith<$Res>  {
  factory $MessageRecipientPlateCopyWith(MessageRecipientPlate value, $Res Function(MessageRecipientPlate) _then) = _$MessageRecipientPlateCopyWithImpl;
@useResult
$Res call({
 String id, String plateNumber
});




}
/// @nodoc
class _$MessageRecipientPlateCopyWithImpl<$Res>
    implements $MessageRecipientPlateCopyWith<$Res> {
  _$MessageRecipientPlateCopyWithImpl(this._self, this._then);

  final MessageRecipientPlate _self;
  final $Res Function(MessageRecipientPlate) _then;

/// Create a copy of MessageRecipientPlate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? plateNumber = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageRecipientPlate].
extension MessageRecipientPlatePatterns on MessageRecipientPlate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageRecipientPlate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageRecipientPlate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageRecipientPlate value)  $default,){
final _that = this;
switch (_that) {
case _MessageRecipientPlate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageRecipientPlate value)?  $default,){
final _that = this;
switch (_that) {
case _MessageRecipientPlate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String plateNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageRecipientPlate() when $default != null:
return $default(_that.id,_that.plateNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String plateNumber)  $default,) {final _that = this;
switch (_that) {
case _MessageRecipientPlate():
return $default(_that.id,_that.plateNumber);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String plateNumber)?  $default,) {final _that = this;
switch (_that) {
case _MessageRecipientPlate() when $default != null:
return $default(_that.id,_that.plateNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageRecipientPlate implements MessageRecipientPlate {
  const _MessageRecipientPlate({required this.id, required this.plateNumber});
  factory _MessageRecipientPlate.fromJson(Map<String, dynamic> json) => _$MessageRecipientPlateFromJson(json);

@override final  String id;
@override final  String plateNumber;

/// Create a copy of MessageRecipientPlate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageRecipientPlateCopyWith<_MessageRecipientPlate> get copyWith => __$MessageRecipientPlateCopyWithImpl<_MessageRecipientPlate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageRecipientPlateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageRecipientPlate&&(identical(other.id, id) || other.id == id)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plateNumber);

@override
String toString() {
  return 'MessageRecipientPlate(id: $id, plateNumber: $plateNumber)';
}


}

/// @nodoc
abstract mixin class _$MessageRecipientPlateCopyWith<$Res> implements $MessageRecipientPlateCopyWith<$Res> {
  factory _$MessageRecipientPlateCopyWith(_MessageRecipientPlate value, $Res Function(_MessageRecipientPlate) _then) = __$MessageRecipientPlateCopyWithImpl;
@override @useResult
$Res call({
 String id, String plateNumber
});




}
/// @nodoc
class __$MessageRecipientPlateCopyWithImpl<$Res>
    implements _$MessageRecipientPlateCopyWith<$Res> {
  __$MessageRecipientPlateCopyWithImpl(this._self, this._then);

  final _MessageRecipientPlate _self;
  final $Res Function(_MessageRecipientPlate) _then;

/// Create a copy of MessageRecipientPlate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? plateNumber = null,}) {
  return _then(_MessageRecipientPlate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Reply {

 String get id; String get senderId; String get senderDisplayName; String get body; DateTime get createdAt;
/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplyCopyWith<Reply> get copyWith => _$ReplyCopyWithImpl<Reply>(this as Reply, _$identity);

  /// Serializes this Reply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reply&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,senderDisplayName,body,createdAt);

@override
String toString() {
  return 'Reply(id: $id, senderId: $senderId, senderDisplayName: $senderDisplayName, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ReplyCopyWith<$Res>  {
  factory $ReplyCopyWith(Reply value, $Res Function(Reply) _then) = _$ReplyCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String senderDisplayName, String body, DateTime createdAt
});




}
/// @nodoc
class _$ReplyCopyWithImpl<$Res>
    implements $ReplyCopyWith<$Res> {
  _$ReplyCopyWithImpl(this._self, this._then);

  final Reply _self;
  final $Res Function(Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? senderDisplayName = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Reply].
extension ReplyPatterns on Reply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reply value)  $default,){
final _that = this;
switch (_that) {
case _Reply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reply value)?  $default,){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String senderDisplayName,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.id,_that.senderId,_that.senderDisplayName,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String senderDisplayName,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Reply():
return $default(_that.id,_that.senderId,_that.senderDisplayName,_that.body,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String senderDisplayName,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.id,_that.senderId,_that.senderDisplayName,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reply implements Reply {
  const _Reply({required this.id, required this.senderId, required this.senderDisplayName, required this.body, required this.createdAt});
  factory _Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);

@override final  String id;
@override final  String senderId;
@override final  String senderDisplayName;
@override final  String body;
@override final  DateTime createdAt;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReplyCopyWith<_Reply> get copyWith => __$ReplyCopyWithImpl<_Reply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reply&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderDisplayName, senderDisplayName) || other.senderDisplayName == senderDisplayName)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,senderDisplayName,body,createdAt);

@override
String toString() {
  return 'Reply(id: $id, senderId: $senderId, senderDisplayName: $senderDisplayName, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReplyCopyWith<$Res> implements $ReplyCopyWith<$Res> {
  factory _$ReplyCopyWith(_Reply value, $Res Function(_Reply) _then) = __$ReplyCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String senderDisplayName, String body, DateTime createdAt
});




}
/// @nodoc
class __$ReplyCopyWithImpl<$Res>
    implements _$ReplyCopyWith<$Res> {
  __$ReplyCopyWithImpl(this._self, this._then);

  final _Reply _self;
  final $Res Function(_Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? senderDisplayName = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_Reply(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderDisplayName: null == senderDisplayName ? _self.senderDisplayName : senderDisplayName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MessageDetail {

 String get id; MessageSender get sender; MessageRecipientPlate get recipientPlate; String? get subject; String get body; bool get isRead; List<Reply> get replies; DateTime get createdAt;
/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageDetailCopyWith<MessageDetail> get copyWith => _$MessageDetailCopyWithImpl<MessageDetail>(this as MessageDetail, _$identity);

  /// Serializes this MessageDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.recipientPlate, recipientPlate) || other.recipientPlate == recipientPlate)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&const DeepCollectionEquality().equals(other.replies, replies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sender,recipientPlate,subject,body,isRead,const DeepCollectionEquality().hash(replies),createdAt);

@override
String toString() {
  return 'MessageDetail(id: $id, sender: $sender, recipientPlate: $recipientPlate, subject: $subject, body: $body, isRead: $isRead, replies: $replies, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MessageDetailCopyWith<$Res>  {
  factory $MessageDetailCopyWith(MessageDetail value, $Res Function(MessageDetail) _then) = _$MessageDetailCopyWithImpl;
@useResult
$Res call({
 String id, MessageSender sender, MessageRecipientPlate recipientPlate, String? subject, String body, bool isRead, List<Reply> replies, DateTime createdAt
});


$MessageSenderCopyWith<$Res> get sender;$MessageRecipientPlateCopyWith<$Res> get recipientPlate;

}
/// @nodoc
class _$MessageDetailCopyWithImpl<$Res>
    implements $MessageDetailCopyWith<$Res> {
  _$MessageDetailCopyWithImpl(this._self, this._then);

  final MessageDetail _self;
  final $Res Function(MessageDetail) _then;

/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sender = null,Object? recipientPlate = null,Object? subject = freezed,Object? body = null,Object? isRead = null,Object? replies = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSender,recipientPlate: null == recipientPlate ? _self.recipientPlate : recipientPlate // ignore: cast_nullable_to_non_nullable
as MessageRecipientPlate,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<Reply>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderCopyWith<$Res> get sender {
  
  return $MessageSenderCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageRecipientPlateCopyWith<$Res> get recipientPlate {
  
  return $MessageRecipientPlateCopyWith<$Res>(_self.recipientPlate, (value) {
    return _then(_self.copyWith(recipientPlate: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageDetail].
extension MessageDetailPatterns on MessageDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageDetail value)  $default,){
final _that = this;
switch (_that) {
case _MessageDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageDetail value)?  $default,){
final _that = this;
switch (_that) {
case _MessageDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MessageSender sender,  MessageRecipientPlate recipientPlate,  String? subject,  String body,  bool isRead,  List<Reply> replies,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageDetail() when $default != null:
return $default(_that.id,_that.sender,_that.recipientPlate,_that.subject,_that.body,_that.isRead,_that.replies,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MessageSender sender,  MessageRecipientPlate recipientPlate,  String? subject,  String body,  bool isRead,  List<Reply> replies,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MessageDetail():
return $default(_that.id,_that.sender,_that.recipientPlate,_that.subject,_that.body,_that.isRead,_that.replies,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MessageSender sender,  MessageRecipientPlate recipientPlate,  String? subject,  String body,  bool isRead,  List<Reply> replies,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageDetail() when $default != null:
return $default(_that.id,_that.sender,_that.recipientPlate,_that.subject,_that.body,_that.isRead,_that.replies,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageDetail implements MessageDetail {
  const _MessageDetail({required this.id, required this.sender, required this.recipientPlate, this.subject, required this.body, required this.isRead, final  List<Reply> replies = const [], required this.createdAt}): _replies = replies;
  factory _MessageDetail.fromJson(Map<String, dynamic> json) => _$MessageDetailFromJson(json);

@override final  String id;
@override final  MessageSender sender;
@override final  MessageRecipientPlate recipientPlate;
@override final  String? subject;
@override final  String body;
@override final  bool isRead;
 final  List<Reply> _replies;
@override@JsonKey() List<Reply> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}

@override final  DateTime createdAt;

/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageDetailCopyWith<_MessageDetail> get copyWith => __$MessageDetailCopyWithImpl<_MessageDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.recipientPlate, recipientPlate) || other.recipientPlate == recipientPlate)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&const DeepCollectionEquality().equals(other._replies, _replies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sender,recipientPlate,subject,body,isRead,const DeepCollectionEquality().hash(_replies),createdAt);

@override
String toString() {
  return 'MessageDetail(id: $id, sender: $sender, recipientPlate: $recipientPlate, subject: $subject, body: $body, isRead: $isRead, replies: $replies, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MessageDetailCopyWith<$Res> implements $MessageDetailCopyWith<$Res> {
  factory _$MessageDetailCopyWith(_MessageDetail value, $Res Function(_MessageDetail) _then) = __$MessageDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, MessageSender sender, MessageRecipientPlate recipientPlate, String? subject, String body, bool isRead, List<Reply> replies, DateTime createdAt
});


@override $MessageSenderCopyWith<$Res> get sender;@override $MessageRecipientPlateCopyWith<$Res> get recipientPlate;

}
/// @nodoc
class __$MessageDetailCopyWithImpl<$Res>
    implements _$MessageDetailCopyWith<$Res> {
  __$MessageDetailCopyWithImpl(this._self, this._then);

  final _MessageDetail _self;
  final $Res Function(_MessageDetail) _then;

/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sender = null,Object? recipientPlate = null,Object? subject = freezed,Object? body = null,Object? isRead = null,Object? replies = null,Object? createdAt = null,}) {
  return _then(_MessageDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as MessageSender,recipientPlate: null == recipientPlate ? _self.recipientPlate : recipientPlate // ignore: cast_nullable_to_non_nullable
as MessageRecipientPlate,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<Reply>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageSenderCopyWith<$Res> get sender {
  
  return $MessageSenderCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of MessageDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageRecipientPlateCopyWith<$Res> get recipientPlate {
  
  return $MessageRecipientPlateCopyWith<$Res>(_self.recipientPlate, (value) {
    return _then(_self.copyWith(recipientPlate: value));
  });
}
}

// dart format on
