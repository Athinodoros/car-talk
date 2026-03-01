import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/unread_count_provider.dart';
import '../router/route_paths.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndexFromLocation(String location) {
    if (location.startsWith(RoutePaths.inbox)) return 0;
    if (location.startsWith(RoutePaths.send)) return 1;
    if (location.startsWith(RoutePaths.sent)) return 2;
    if (location.startsWith(RoutePaths.profile)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.inbox);
      case 1:
        context.go(RoutePaths.send);
      case 2:
        context.go(RoutePaths.sent);
      case 3:
        context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndexFromLocation(location);
    final unreadCount = ref.watch(unreadCountProvider);

    final int unread = unreadCount.value ?? 0;
    final String inboxLabel = unread > 0
        ? 'Inbox, $unread unread ${unread == 1 ? 'message' : 'messages'}'
        : 'Inbox';

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          NavigationDestination(
            icon: Semantics(
              label: inboxLabel,
              child: Badge(
                isLabelVisible: unread > 0,
                label: ExcludeSemantics(
                  child: Text('$unread'),
                ),
                child: const Icon(Icons.inbox_outlined),
              ),
            ),
            selectedIcon: Semantics(
              label: inboxLabel,
              child: Badge(
                isLabelVisible: unread > 0,
                label: ExcludeSemantics(
                  child: Text('$unread'),
                ),
                child: const Icon(Icons.inbox),
              ),
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send),
            label: 'Send',
          ),
          const NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            selectedIcon: Icon(Icons.outbox),
            label: 'Sent',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
