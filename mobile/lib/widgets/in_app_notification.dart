import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/route_paths.dart';

/// Shows an in-app [MaterialBanner] for a foreground push notification.
///
/// The banner displays the notification [title] and [body], with "View" and
/// "Dismiss" action buttons. It auto-dismisses after 5 seconds.
///
/// Tapping "View" navigates to the message detail screen for [messageId]
/// (if provided) using the supplied [router].
///
/// This function is safe to call even if [scaffoldMessengerKey] has no current
/// state (e.g. during app startup); it will silently return in that case.
void showInAppNotification({
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  required GoRouter router,
  required String? title,
  required String? body,
  required String? messageId,
}) {
  final messengerState = scaffoldMessengerKey.currentState;
  if (messengerState == null) return;

  // Nothing to display if both title and body are absent.
  final hasTitle = title != null && title.isNotEmpty;
  final hasBody = body != null && body.isNotEmpty;
  if (!hasTitle && !hasBody) return;

  // Clear any existing material banner before showing a new one.
  messengerState.clearMaterialBanners();

  Timer? autoDismissTimer;

  final banner = MaterialBanner(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    leading: const Icon(Icons.mail_rounded),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasTitle)
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasBody)
          Padding(
            padding: EdgeInsets.only(top: hasTitle ? 4 : 0),
            child: Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    ),
    actions: [
      if (messageId != null && messageId.isNotEmpty)
        TextButton(
          onPressed: () {
            autoDismissTimer?.cancel();
            messengerState.hideCurrentMaterialBanner();
            router.go('${RoutePaths.inbox}/$messageId');
          },
          child: const Text('VIEW'),
        ),
      TextButton(
        onPressed: () {
          autoDismissTimer?.cancel();
          messengerState.hideCurrentMaterialBanner();
        },
        child: const Text('DISMISS'),
      ),
    ],
  );

  messengerState.showMaterialBanner(banner);

  // Auto-dismiss after 5 seconds.
  autoDismissTimer = Timer(const Duration(seconds: 5), () {
    try {
      messengerState.hideCurrentMaterialBanner();
    } catch (_) {
      // State may have been disposed; ignore.
    }
  });
}
