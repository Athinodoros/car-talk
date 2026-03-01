import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';
import '../config/socket_events.dart';

class SocketService {
  io.Socket? _socket;

  final StreamController<Map<String, dynamic>> _newMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _newReplyController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _messageReadController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _unreadCountController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get newMessageStream =>
      _newMessageController.stream;

  Stream<Map<String, dynamic>> get newReplyStream =>
      _newReplyController.stream;

  Stream<Map<String, dynamic>> get messageReadStream =>
      _messageReadController.stream;

  Stream<Map<String, dynamic>> get unreadCountStream =>
      _unreadCountController.stream;

  void connect(String accessToken) {
    _socket = io.io(
      Env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    _socket!.on(SocketEvents.newMessage, (data) {
      if (data is Map<String, dynamic>) {
        _newMessageController.add(data);
      }
    });

    _socket!.on(SocketEvents.newReply, (data) {
      if (data is Map<String, dynamic>) {
        _newReplyController.add(data);
      }
    });

    _socket!.on(SocketEvents.messageRead, (data) {
      if (data is Map<String, dynamic>) {
        _messageReadController.add(data);
      }
    });

    _socket!.on(SocketEvents.unreadCount, (data) {
      if (data is Map<String, dynamic>) {
        _unreadCountController.add(data);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _newReplyController.close();
    _messageReadController.close();
    _unreadCountController.close();
  }
}
