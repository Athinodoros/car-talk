import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/socket_provider.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';

class CarPostAllApp extends ConsumerWidget {
  const CarPostAllApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(goRouterProvider);

    // Keep the connectivity-based socket auto-reconnect listener alive.
    ref.watch(socketAutoReconnectProvider);

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
    );
  }
}
