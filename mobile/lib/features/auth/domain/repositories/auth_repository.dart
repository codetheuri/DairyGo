import '../../data/models/register_request.dart';
import '../entities/auth_state.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthState> login({required String identity, required String password});
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> register(RegisterRequest request);
  Future<List<UserEntity>> listUsers();
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
  Future<void> logout();
}
