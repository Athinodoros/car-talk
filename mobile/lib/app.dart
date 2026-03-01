import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/fcm_provider.dart';
import 'providers/socket_provider.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';

/// Global key for the [ScaffoldMessenger] used to show in-app notifications
/// (e.g. foreground FCM push messages) from anywhere in the app without
/// needing a [BuildContext].
final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});

class CarPostAllApp extends ConsumerWidget {
  const CarPostAllApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(goRouterProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    // Keep the connectivity-based socket auto-reconnect listener alive.
    ref.watch(socketAutoReconnectProvider);

    // Keep the FCM foreground listener alive while the app is running.
    ref.watch(fcmForegroundListenerProvider);

    final themeLight = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final themeDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );

    // Show branded splash while auth state is resolving
    if (authState.isLoading && !authState.hasValue) {
      return MaterialApp(
        title: 'Car Post All',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: themeLight,
        darkTheme: themeDark,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Car Post All',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: themeLight,
      darkTheme: themeDark,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
