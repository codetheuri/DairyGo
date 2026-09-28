import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final user = await repo.getCurrentUser();
    if (user != null) {
      final token = await ref.read(secureStorageServiceProvider).getToken();
      return AuthState.authenticated(user: user, token: token ?? '');
    }
    return AuthState.unauthenticated();
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
    state = AsyncValue.data(AuthState.unauthenticated());
  }

  /// Called when the server rejects the token (expired, user deactivated or
  /// Sacco suspended). Several requests can fail at once, so only the first
  /// one signs the user out.
  void expireSession() {
    if (state.valueOrNull?.isAuthenticated != true) return;
    state = AsyncValue.data(
      AuthState.unauthenticated('Your session has ended. Please log in again.'),
    );
  }
}
