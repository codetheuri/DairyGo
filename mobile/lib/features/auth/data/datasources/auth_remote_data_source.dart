import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../models/register_request.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String identity, String password);
  Future<UserEntity> getMe();
  Future<UserEntity> register(RegisterRequest request);
  Future<List<UserEntity>> listUsers();
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['errors'] is Map) {
        final errs = data['errors'] as Map;
        if (errs.isNotEmpty) {
          final firstVal = errs.values.first?.toString();
          if (firstVal != null && firstVal.isNotEmpty) {
            return firstVal;
          }
        }
      }
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty && msg != 'Validation failed') {
        return msg;
      }
    }
    return e.message ?? fallback;
  }

  @override
  Future<Map<String, dynamic>> login(String identity, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'login': identity,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        error: data['message'] ?? 'Login failed',
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Authentication failed'));
    }
  }

  @override
  Future<UserEntity> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final userData = data['data'];
        final userMap = (userData is Map && userData['user'] != null)
            ? userData['user']
            : userData;
        return UserEntity.fromJson(userMap as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to retrieve profile');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to retrieve user profile'));
    }
  }

  @override
  Future<UserEntity> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final userData = data['data'];
        final userMap = (userData is Map && userData['user'] != null)
            ? userData['user']
            : userData;
        return UserEntity.fromJson(userMap as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Registration failed'));
    }
  }

  @override
  Future<List<UserEntity>> listUsers() async {
    try {
      final response = await _dio.get('/api/v1/auth/users', queryParameters: {'per_page': 100});
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['users'] as List? ?? [])
            .map((e) => UserEntity.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load staff users');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load staff users'));
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/me/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to change password');
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Incorrect current password or invalid request'));
    }
  }
}
