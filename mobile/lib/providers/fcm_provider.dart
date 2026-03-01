import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../config/storage_keys.dart';
import '../router/app_router.dart';
import '../router/route_paths.dart';
import '../widgets/in_app_notification.dart';
import 'repository_providers.dart';
import 'storage_provider.dart';

/// Provides the [FcmService] singleton, disposed when the provider is torn down.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Listens to foreground FCM messages and shows an in-app [MaterialBanner].
///
/// Watch this provider from the root widget ([CarPostAllApp]) to keep it alive
/// for the entire app lifetime.
final fcmForegroundListenerProvider = Provider<void>((ref) {
  StreamSubscription<RemoteMessage>? subscription;

  try {
    subscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        final title = message.notification?.title;
        final body = message.notification?.body;
        final messageId = message.data['messageId'] as String?;

        final scaffoldMessengerKey =
            ref.read(scaffoldMessengerKeyProvider);
        final router = ref.read(goRouterProvider);

        showInAppNotification(
          scaffoldMessengerKey: scaffoldMessengerKey,
          router: router,
          title: title,
          body: body,
          messageId: messageId,
        );
      } catch (e) {
        debugPrint(
          'FCM: failed to show foreground notification: $e',
        );
      }
    });
  } catch (e) {
    debugPrint(
      'FCM: failed to subscribe to foreground messages: $e',
    );
  }

  ref.onDispose(() => subscription?.cancel());
});

/// Manages Firebase Cloud Messaging: permission, token registration,
/// token refresh, and deep-link handling when a notification is tapped.
///
/// Every public method is wrapped in try/catch so the app continues to
/// function even when Firebase is not configured (no google-services.json).
class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  // ---- public API ----

  /// Call once after the user is authenticated.
  /// Requests permission, grabs the FCM token, registers it with the backend,
  /// and starts listening for token refreshes and notification taps.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS will show the system dialog; Android is
      // granted by default on API < 33 and needs runtime permission on 33+).
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get the current token and register it.
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Listen for token refreshes (e.g. app data cleared, OS rotated token).
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _registerToken(newToken);
        } catch (e) {
          debugPrint('FCM: failed to register refreshed token: $e');
        }
      });

      // Handle notification taps when the app is in background (but alive).
      _onMessageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification taps when the app was terminated (cold start).
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      // Firebase not configured or unavailable -- push notifications disabled.
      debugPrint('FCM: initialization failed (push notifications disabled): $e');
    }
  }

  /// Remove the FCM token from the backend and local storage.
  /// Call on logout so the device stops receiving pushes for this user.
  Future<void> removeToken() async {
    try {
      final storage = _ref.read(storageProvider);
      final storedToken = await storage.read(key: StorageKeys.fcmToken);
      if (storedToken != null) {
        final deviceRepo = _ref.read(deviceRepositoryProvider);
        await deviceRepo.removeDevice(storedToken);
        await storage.delete(key: StorageKeys.fcmToken);
      }
    } catch (e) {
      debugPrint('FCM: failed to remove device token: $e');
    }
  }

  /// Cancel all subscriptions. Called automatically by Riverpod on dispose.
  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageOpenedSub?.cancel();
  }

  // ---- private helpers ----

  /// Register [token] with the backend and persist it locally.
  Future<void> _registerToken(String token) async {
    try {
      final deviceRepo = _ref.read(deviceRepositoryProvider);
      await deviceRepo.registerDevice(token);

      // Store the token so we can unregister it on logout.
      final storage = _ref.read(storageProvider);
      await storage.write(key: StorageKeys.fcmToken, value: token);
    } catch (e) {
      debugPrint('FCM: failed to register device token: $e');
    }
  }

  /// Navigate to the message detail screen when the user taps a notification.
  /// Expects the notification data payload to contain a `messageId` field.
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final messageId = message.data['messageId'] as String?;
      if (messageId == null || messageId.isEmpty) return;

      final router = _ref.read(goRouterProvider);
      // Navigate to inbox detail: /inbox/<messageId>
      router.go('${RoutePaths.inbox}/$messageId');
    } catch (e) {
      debugPrint('FCM: failed to handle notification tap: $e');
    }
  }
}
