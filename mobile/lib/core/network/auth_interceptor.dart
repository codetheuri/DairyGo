import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// AuthInterceptor dynamically injects the JWT token into HTTP request headers.
/// 
/// Senior Architect Note:
/// Automatically attaches `Authorization: Bearer <token>` to outgoing requests.
/// If HTTP 401 (Unauthorized) occurs, it clears stale credentials.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Clear invalid token session
      await _storageService.deleteToken();
    }
    return handler.next(err);
  }
}
