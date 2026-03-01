import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';
import 'auth_tokens.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    AuthTokens? tokens,
    @Default(false) bool isAuthenticated,
    @Default(true) bool isLoading,
  }) = _AuthState;
}
