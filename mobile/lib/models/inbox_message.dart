import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_message.freezed.dart';
part 'inbox_message.g.dart';

@freezed
sealed class InboxMessage with _$InboxMessage {
  const factory InboxMessage({
    required String id,
    required String senderDisplayName,
    String? subject,
    required String body,
    required String recipientPlateId,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _InboxMessage;

  factory InboxMessage.fromJson(Map<String, dynamic> json) =>
      _$InboxMessageFromJson(json);
}
