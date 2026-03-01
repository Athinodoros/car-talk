import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/socket_service.dart';
import 'auth_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});

/// Listens to connectivity changes and reconnects the socket when the network
/// comes back online while the user is authenticated.
///
/// Watch this provider from the root widget to keep it alive.
final socketAutoReconnectProvider = Provider<void>((ref) {
  bool wasOnline = true; // assume online at start

  final subscription = Connectivity().onConnectivityChanged.listen((results) {
    final isNowOnline = results.any((r) => r != ConnectivityResult.none);

    if (!wasOnline && isNowOnline) {
      // Network just came back online -- reconnect if authenticated.
      final authState = ref.read(authProvider);
      final accessToken = authState.value?.tokens?.accessToken;
      final isAuthenticated =
          authState.value?.isAuthenticated ?? false;

      if (isAuthenticated && accessToken != null) {
        ref.read(socketServiceProvider).reconnect(accessToken);
      }
    }

    wasOnline = isNowOnline;
  });

  ref.onDispose(() => subscription.cancel());
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
