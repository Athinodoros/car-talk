// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SentMessage _$SentMessageFromJson(Map<String, dynamic> json) => _SentMessage(
  id: json['id'] as String,
  recipientPlateNumber: json['recipientPlateNumber'] as String,
  subject: json['subject'] as String?,
  body: json['body'] as String,
  isRead: json['isRead'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SentMessageToJson(_SentMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipientPlateNumber': instance.recipientPlateNumber,
      'subject': instance.subject,
      'body': instance.body,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };
