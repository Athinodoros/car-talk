import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_detail.dart';
import 'repository_providers.dart';

final threadProvider = FutureProvider.autoDispose.family<MessageDetail, String>(
  (ref, messageId) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    return messageRepo.getMessageDetail(messageId);
  },
);

Future<void> sendReply(WidgetRef ref, String messageId, String body) async {
  final messageRepo = ref.read(messageRepositoryProvider);
  await messageRepo.addReply(messageId, body);
  ref.invalidate(threadProvider(messageId));
}

Future<void> markThreadAsRead(WidgetRef ref, String messageId) async {
  final messageRepo = ref.read(messageRepositoryProvider);
  await messageRepo.markAsRead(messageId);
  ref.invalidate(threadProvider(messageId));
}
