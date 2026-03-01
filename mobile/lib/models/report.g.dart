// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Report _$ReportFromJson(Map<String, dynamic> json) => _Report(
  id: json['id'] as String,
  reporterId: json['reporterId'] as String,
  messageId: json['messageId'] as String?,
  reason: json['reason'] as String,
  status: json['status'] as String? ?? 'pending',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReportToJson(_Report instance) => <String, dynamic>{
  'id': instance.id,
  'reporterId': instance.reporterId,
  'messageId': instance.messageId,
  'reason': instance.reason,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
};
