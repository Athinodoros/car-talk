// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageSender _$MessageSenderFromJson(Map<String, dynamic> json) =>
    _MessageSender(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
    );

Map<String, dynamic> _$MessageSenderToJson(_MessageSender instance) =>
    <String, dynamic>{'id': instance.id, 'displayName': instance.displayName};

_MessageRecipientPlate _$MessageRecipientPlateFromJson(
  Map<String, dynamic> json,
) => _MessageRecipientPlate(
  id: json['id'] as String,
  plateNumber: json['plateNumber'] as String,
);

Map<String, dynamic> _$MessageRecipientPlateToJson(
  _MessageRecipientPlate instance,
) => <String, dynamic>{'id': instance.id, 'plateNumber': instance.plateNumber};

_Reply _$ReplyFromJson(Map<String, dynamic> json) => _Reply(
  id: json['id'] as String,
  senderId: json['senderId'] as String,
  senderDisplayName: json['senderDisplayName'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReplyToJson(_Reply instance) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'senderDisplayName': instance.senderDisplayName,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
};

_MessageDetail _$MessageDetailFromJson(Map<String, dynamic> json) =>
    _MessageDetail(
      id: json['id'] as String,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      recipientPlate: MessageRecipientPlate.fromJson(
        json['recipientPlate'] as Map<String, dynamic>,
      ),
      subject: json['subject'] as String?,
      body: json['body'] as String,
      isRead: json['isRead'] as bool,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => Reply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MessageDetailToJson(_MessageDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender': instance.sender,
      'recipientPlate': instance.recipientPlate,
      'subject': instance.subject,
      'body': instance.body,
      'isRead': instance.isRead,
      'replies': instance.replies,
      'createdAt': instance.createdAt.toIso8601String(),
    };
