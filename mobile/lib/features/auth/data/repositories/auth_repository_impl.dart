import 'dart:convert';

import '../../../../core/errors/failure.dart';
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
      final tokens = SessionTokens.fromJson(res);
      final user = UserEntity.fromJson(res['user'] as Map<String, dynamic>);

      await _storageService.saveSession(tokens);
      await _saveUser(user);

      return AuthState.authenticated(user: user, token: tokens.accessToken);
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      return AuthState.unauthenticated(cleanMsg);
    }
  }

  /// The signed-in user at start-up. With no connection the saved profile is
  /// used, so field staff stay signed in without signal; only a real
  /// rejection from the server (e.g. an expired or revoked session) signs
  /// them out.
  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _remoteDataSource.getMe();
      await _saveUser(user);
      return user;
    } on ServerUnreachableException {
      final saved = await _storageService.getUserJson();
      if (saved != null) {
        return UserEntity.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      }
      rethrow; // never signed in on this phone before: nothing to show
    } catch (_) {
      await _storageService.clearSession();
      return null;
    }
  }

  @override
  Future<UserEntity?> savedUser() async {
    final token = await _storageService.getToken();
    final saved = await _storageService.getUserJson();
    if (token == null || token.isEmpty || saved == null) return null;
    try {
      return UserEntity.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return null; // saved by an older app version with another shape
    }
  }

  @override
  Future<bool> sessionIdleExpired() async {
    final expiresAt = await _storageService.getSessionExpiresAt();
    return expiresAt != null && DateTime.now().isAfter(expiresAt);
  }

  Future<void> _saveUser(UserEntity user) =>
      _storageService.saveUserJson(jsonEncode(user.toJson()));

  @override
  Future<UserEntity> register(RegisterRequest request) {
    return _remoteDataSource.register(request);
  }

  @override
  Future<List<UserEntity>> listUsers() {
    return _remoteDataSource.listUsers();
  }

  @override
  Future<UserEntity> changeStaffRole(
    int userId,
    int roleId, {
    String? reason,
  }) => _remoteDataSource.changeStaffRole(userId, roleId, reason: reason);

  @override
  Future<void> removeStaff(int userId, {String? reason}) =>
      _remoteDataSource.removeStaff(userId, reason: reason);

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) {
    return _remoteDataSource.changePassword(
      currentPassword,
      newPassword,
      confirmPassword,
    );
  }

  @override
  Future<void> logout({bool notifyServer = true}) async {
    final refreshToken = await _storageService.getRefreshToken();
    await _storageService.clearSession();
    if (notifyServer && refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remoteDataSource.logout(refreshToken);
      } catch (_) {
        // Offline: the session still ends on the server after the idle limit.
      }
    }
  }
}
