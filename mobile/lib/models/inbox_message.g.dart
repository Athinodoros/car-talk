// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InboxMessage _$InboxMessageFromJson(Map<String, dynamic> json) =>
    _InboxMessage(
      id: json['id'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      recipientPlateId: json['recipientPlateId'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$InboxMessageToJson(_InboxMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderDisplayName': instance.senderDisplayName,
      'subject': instance.subject,
      'body': instance.body,
      'recipientPlateId': instance.recipientPlateId,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };
