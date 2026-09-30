import '../../data/models/register_request.dart';
import '../entities/auth_state.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthState> login({required String identity, required String password});
  Future<UserEntity?> getCurrentUser();

  /// The profile saved at the last sign-in, used to open the app instantly.
  Future<UserEntity?> savedUser();

  /// Whether the session ran out on this phone (not used for longer than the
  /// server's idle limit), which can be known without a connection.
  Future<bool> sessionIdleExpired();
  Future<UserEntity> register(RegisterRequest request);
  Future<List<UserEntity>> listUsers();

  /// Gives a staff member of the Sacco another role (1 admin, 2 collector,
  /// 3 board member).
  Future<UserEntity> changeStaffRole(int userId, int roleId, {String? reason});

  /// Removes a staff member's account; what they recorded is kept.
  Future<void> removeStaff(int userId, {String? reason});
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );

  /// Signs out on this phone and, when [notifyServer], ends the session on
  /// the server too (best effort: works offline).
  Future<void> logout({bool notifyServer = true});
}
