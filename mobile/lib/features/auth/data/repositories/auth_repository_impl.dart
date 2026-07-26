import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<AuthState> login({
    required String identity,
    required String password,
  }) async {
    try {
      final res = await _remoteDataSource.login(identity, password);
      final token = (res['access_token'] ?? res['token']) as String;
      final userJson = res['user'] as Map<String, dynamic>;
      final user = UserEntity.fromJson(userJson);

      await _storageService.saveToken(token);

      return AuthState.authenticated(user: user, token: token);
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      return AuthState.unauthenticated(cleanMsg);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) return null;
      return await _remoteDataSource.getMe();
    } catch (_) {
      await _storageService.deleteToken();
      return null;
    }
  }

  @override
  Future<UserEntity> register(RegisterRequest request) {
    return _remoteDataSource.register(request);
  }

  @override
  Future<List<UserEntity>> listUsers() {
    return _remoteDataSource.listUsers();
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) {
    return _remoteDataSource.changePassword(currentPassword, newPassword, confirmPassword);
  }

  @override
  Future<void> logout() async {
    await _storageService.deleteToken();
  }
}
