import 'package:freezed_annotation/freezed_annotation.dart';

part 'sent_message.freezed.dart';
part 'sent_message.g.dart';

@freezed
sealed class SentMessage with _$SentMessage {
  const factory SentMessage({
    required String id,
    required String recipientPlateNumber,
    String? subject,
    required String body,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _SentMessage;

  factory SentMessage.fromJson(Map<String, dynamic> json) =>
      _$SentMessageFromJson(json);
}
