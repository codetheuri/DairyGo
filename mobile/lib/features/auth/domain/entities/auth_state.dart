import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_entity.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required bool isAuthenticated,
    UserEntity? user,
    String? token,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _AuthState;

  factory AuthState.unauthenticated([String? errorMessage]) => AuthState(
        isAuthenticated: false,
        user: null,
        token: null,
        isLoading: false,
        errorMessage: errorMessage,
      );

  factory AuthState.authenticated({
    required UserEntity user,
    required String token,
  }) =>
      AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
        isLoading: false,
        errorMessage: null,
      );
}
