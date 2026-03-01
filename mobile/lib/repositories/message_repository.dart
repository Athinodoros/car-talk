import '../config/api_endpoints.dart';
import '../models/inbox_message.dart';
import '../models/message_detail.dart';
import '../models/sent_message.dart';
import 'api_client.dart';

class MessageRepository {
  MessageRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendMessage({
    required String plateNumber,
    String? subject,
    required String body,
  }) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.messagesSend,
      data: {
        'plateNumber': plateNumber,
        'subject': ?subject,
        'body': body,
      },
    );
  }

  Future<({List<InboxMessage> messages, String? nextCursor})> getInbox({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.messagesInbox,
      queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
      },
    );

    final data = response.data!;
    final messagesJson = data['messages'] as List<dynamic>;
    final messages = messagesJson
        .map((json) => InboxMessage.fromJson(json as Map<String, dynamic>))
        .toList();
    final nextCursor = data['nextCursor'] as String?;

    return (messages: messages, nextCursor: nextCursor);
  }

  Future<({List<SentMessage> messages, String? nextCursor})> getSent({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.messagesSent,
      queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
      },
    );

    final data = response.data!;
    final messagesJson = data['messages'] as List<dynamic>;
    final messages = messagesJson
        .map((json) => SentMessage.fromJson(json as Map<String, dynamic>))
        .toList();
    final nextCursor = data['nextCursor'] as String?;

    return (messages: messages, nextCursor: nextCursor);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.messagesUnreadCount,
    );

    return response.data!['count'] as int;
  }

  Future<MessageDetail> getMessageDetail(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.messageDetail(id),
    );

    return MessageDetail.fromJson(response.data!);
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.dio.patch<Map<String, dynamic>>(
      ApiEndpoints.messageMarkRead(id),
    );
  }

  Future<Reply> addReply(String messageId, String body) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.messageAddReply(messageId),
      data: {'body': body},
    );

    return Reply.fromJson(response.data!);
  }
}
