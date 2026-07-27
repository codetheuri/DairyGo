import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../reports/presentation/controllers/report_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final remoteDS = AuthRemoteDataSourceImpl(dio);
  return AuthRepositoryImpl(remoteDS, storageService);
});

final saccoStaffListProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.listUsers();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

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
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(identity: identity, password: password);

    invalidateAllAppMetrics(ref);
    state = AsyncValue.data(result);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    invalidateAllAppMetrics(ref);
    state = AsyncValue.data(AuthState.unauthenticated());
  }
}
