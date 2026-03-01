import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});

final newMessageStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(socketServiceProvider).newMessageStream;
});

final newReplyStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(socketServiceProvider).newReplyStream;
});

final messageReadStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(socketServiceProvider).messageReadStream;
});

final unreadCountStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(socketServiceProvider).unreadCountStream;
});
