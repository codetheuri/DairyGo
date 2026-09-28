import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/response_cache.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(authDioProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final remoteDS = AuthRemoteDataSourceImpl(dio);
  return AuthRepositoryImpl(remoteDS, storageService);
});

final saccoStaffListProvider = FutureProvider.autoDispose<List<UserEntity>>((
  ref,
) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.listUsers();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in user's id, or null when signed out. Data providers depend on
/// it through [dioClientProvider], so they all reload when the user changes.
final sessionUserIdProvider = Provider<int?>((ref) {
  return ref.watch(
    authControllerProvider.select((s) => s.valueOrNull?.user?.id),
  );
});

class AuthController extends AsyncNotifier<AuthState> {
  static const _idleMessage =
      'You were signed out because the app was not used for a long time. '
      'Please log in again.';

  /// Opens straight into the app with the profile saved at sign-in and
  /// confirms the session with the server in the background, instead of
  /// waiting a full round trip (seconds on a slow link) before showing
  /// anything.
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    if (await repo.sessionIdleExpired()) {
      await repo.logout(notifyServer: false);
      await ResponseCache.clearAll();
      return AuthState.unauthenticated(_idleMessage);
    }

    final saved = await repo.savedUser();
    final token = await ref.read(secureStorageServiceProvider).getToken();
    if (saved != null) {
      Future.microtask(_confirmSession);
      return AuthState.authenticated(user: saved, token: token ?? '');
    }

    final user = await repo.getCurrentUser();
    if (user != null) {
      return AuthState.authenticated(user: user, token: token ?? '');
    }
    return AuthState.unauthenticated();
  }

  /// Checks the saved session with the server: updates the profile if it
  /// changed, and signs out if the server ended the session. Without a
  /// connection nothing changes.
  Future<void> _confirmSession() async {
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (user == null) {
        expireSession();
      } else if (state.valueOrNull?.user != user) {
        final token = await ref.read(secureStorageServiceProvider).getToken();
        state = AsyncValue.data(
          AuthState.authenticated(user: user, token: token ?? ''),
        );
      }
    } catch (_) {
      // Server unreachable: keep the saved session.
    }
  }

  /// Signs out if the app was left unused past the idle limit, e.g. when it
  /// comes back to the foreground after weeks in the background.
  Future<void> checkIdleSession() async {
    if (state.valueOrNull?.isAuthenticated != true) return;
    if (await ref.read(authRepositoryProvider).sessionIdleExpired()) {
      await ref.read(authRepositoryProvider).logout(notifyServer: false);
      await ResponseCache.clearAll();
      state = AsyncValue.data(AuthState.unauthenticated(_idleMessage));
    }
  }

  Future<void> login(String identity, String password) async {
    // Keep the previous (signed-out) state while loading, so the router
    // leaves the login screen up with its spinner.
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(identity: identity, password: password);
    state = AsyncValue.data(result);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    await ResponseCache.clearAll(); // no saved data left for the next user
    state = AsyncValue.data(AuthState.unauthenticated());
  }

  /// Called when the server ends the session (idle too long, user
  /// deactivated, Sacco suspended). Several requests can fail at once, so
  /// only the first one signs the user out.
  void expireSession() {
    if (state.valueOrNull?.isAuthenticated != true) return;
    unawaited(ref.read(authRepositoryProvider).logout(notifyServer: false));
    unawaited(ResponseCache.clearAll());
    state = AsyncValue.data(
      AuthState.unauthenticated('Your session has ended. Please log in again.'),
    );
  }
}
