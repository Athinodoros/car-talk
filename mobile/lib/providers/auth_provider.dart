import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/storage_keys.dart';
import '../models/auth_state.dart';
import '../models/user.dart';
import '../models/auth_tokens.dart';
import 'fcm_provider.dart';
import 'repository_providers.dart';
import 'socket_provider.dart';
import 'storage_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(storageProvider);

    // Read all keys in parallel instead of sequentially
    final results = await Future.wait([
      storage.read(key: StorageKeys.accessToken),
      storage.read(key: StorageKeys.refreshToken),
      storage.read(key: StorageKeys.userId),
      storage.read(key: StorageKeys.userEmail),
      storage.read(key: StorageKeys.userDisplayName),
    ]);

    final accessToken = results[0];
    final refreshToken = results[1];
    final userId = results[2];
    final userEmail = results[3];
    final userDisplayName = results[4];

    if (accessToken != null && refreshToken != null && userId != null && userEmail != null && userDisplayName != null) {
      final user = User(id: userId, email: userEmail, displayName: userDisplayName);
      final tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken);

      // Connect socket with stored token
      ref.read(socketServiceProvider).connect(accessToken);

      // Register for push notifications
      ref.read(fcmServiceProvider).initialize();

      return AuthState(
        user: user,
        tokens: tokens,
        isAuthenticated: true,
        isLoading: false,
      );
    }

    return const AuthState(isLoading: false);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.login(email: email, password: password);

      await _storeAuthData(response.user, response.tokens);
      ref.read(socketServiceProvider).connect(response.tokens.accessToken);

      // Register for push notifications
      ref.read(fcmServiceProvider).initialize();

      state = AsyncData(AuthState(
        user: response.user,
        tokens: response.tokens,
        isAuthenticated: true,
        isLoading: false,
      ));
    } catch (e) {
      state = const AsyncData(AuthState(isLoading: false));
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String plateNumber,
    String? stateOrRegion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.register(
        email: email,
        password: password,
        displayName: displayName,
        plateNumber: plateNumber,
        stateOrRegion: stateOrRegion,
      );

      await _storeAuthData(response.user, response.tokens);
      ref.read(socketServiceProvider).connect(response.tokens.accessToken);

      // Register for push notifications
      ref.read(fcmServiceProvider).initialize();

      state = AsyncData(AuthState(
        user: response.user,
        tokens: response.tokens,
        isAuthenticated: true,
        isLoading: false,
      ));
    } catch (e) {
      state = const AsyncData(AuthState(isLoading: false));
      rethrow;
    }
  }

  Future<void> logout() async {
    // Unregister device token from backend before disconnecting
    await ref.read(fcmServiceProvider).removeToken();

    ref.read(socketServiceProvider).disconnect();

    final storage = ref.read(storageProvider);
    await storage.delete(key: StorageKeys.accessToken);
    await storage.delete(key: StorageKeys.refreshToken);
    await storage.delete(key: StorageKeys.userId);
    await storage.delete(key: StorageKeys.userEmail);
    await storage.delete(key: StorageKeys.userDisplayName);

    state = const AsyncData(AuthState(isLoading: false));
  }

  Future<void> _storeAuthData(User user, AuthTokens tokens) async {
    final storage = ref.read(storageProvider);
    await Future.wait([
      storage.write(key: StorageKeys.accessToken, value: tokens.accessToken),
      storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken),
      storage.write(key: StorageKeys.userId, value: user.id),
      storage.write(key: StorageKeys.userEmail, value: user.email),
      storage.write(key: StorageKeys.userDisplayName, value: user.displayName),
    ]);
  }
}
