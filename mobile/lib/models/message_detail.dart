import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_detail.freezed.dart';
part 'message_detail.g.dart';

@freezed
sealed class MessageSender with _$MessageSender {
  const factory MessageSender({
    required String id,
    required String displayName,
  }) = _MessageSender;

  factory MessageSender.fromJson(Map<String, dynamic> json) =>
      _$MessageSenderFromJson(json);
}

@freezed
sealed class MessageRecipientPlate with _$MessageRecipientPlate {
  const factory MessageRecipientPlate({
    required String id,
    required String plateNumber,
  }) = _MessageRecipientPlate;

  factory MessageRecipientPlate.fromJson(Map<String, dynamic> json) =>
      _$MessageRecipientPlateFromJson(json);
}

@freezed
sealed class Reply with _$Reply {
  const factory Reply({
    required String id,
    required String senderId,
    required String senderDisplayName,
    required String body,
    required DateTime createdAt,
  }) = _Reply;

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
}

@freezed
sealed class MessageDetail with _$MessageDetail {
  const factory MessageDetail({
    required String id,
    required MessageSender sender,
    required MessageRecipientPlate recipientPlate,
    String? subject,
    required String body,
    required bool isRead,
    @Default([]) List<Reply> replies,
    required DateTime createdAt,
  }) = _MessageDetail;

  factory MessageDetail.fromJson(Map<String, dynamic> json) =>
      _$MessageDetailFromJson(json);
}
