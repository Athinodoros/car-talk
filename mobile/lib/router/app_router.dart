import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/message_detail_screen.dart';
import '../screens/send_message_screen.dart';
import '../screens/sent_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/app_shell.dart';
import 'route_paths.dart';

/// A [ChangeNotifier] that listens to Riverpod's [authProvider] and notifies
/// GoRouter when the auth state changes, triggering a redirect re-evaluation.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _sub = _ref.listen(authProvider, (prev, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.inbox,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final auth = authState.value;
      if (auth == null || auth.isLoading) {
        return null;
      }

      final isAuthenticated = auth.isAuthenticated;
      final currentPath = state.matchedLocation;
      final isAuthRoute =
          currentPath == RoutePaths.login || currentPath == RoutePaths.register;

      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.inbox;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.inbox,
            builder: (context, state) => const InboxScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MessageDetailScreen(messageId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.send,
            builder: (context, state) => const SendMessageScreen(),
          ),
          GoRoute(
            path: RoutePaths.sent,
            builder: (context, state) => const SentScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MessageDetailScreen(messageId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
