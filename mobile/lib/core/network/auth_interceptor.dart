import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

/// AuthInterceptor dynamically injects the JWT token into HTTP request headers.
///
/// Automatically attaches `Authorization: Bearer <token>` to outgoing requests.
/// On HTTP 401 (expired token, deactivated user or suspended Sacco) it clears
/// the stored token and calls [onSessionExpired] so the app returns to login
/// instead of showing errors on every screen.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final VoidCallback? onSessionExpired;

  AuthInterceptor(this._storageService, {this.onSessionExpired});

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
    // A 401 from the login call means wrong credentials, not an expired session.
    final isLogin = err.requestOptions.path.contains('/auth/login');
    if (err.response?.statusCode == 401 && !isLogin) {
      await _storageService.deleteToken();
      onSessionExpired?.call();
    }
    return handler.next(err);
  }
}
