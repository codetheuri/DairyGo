import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';
import 'token_refresher.dart';

/// Attaches the access token to requests and keeps the session alive.
///
/// - Before a request, an access token that is about to expire is renewed.
/// - A 401 is answered by renewing once and retrying the request.
/// - Only when the server ends the session (the renewal itself is refused)
///   is [onSessionExpired] called, so the app returns to the login screen.
///   Losing the signal never signs the user out.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storageService;
  final TokenRefresher? refresher;
  final VoidCallback? onSessionExpired;

  static const _retriedKey = 'auth_retried';

  AuthInterceptor(
    this._dio,
    this._storageService, {
    this.refresher,
    this.onSessionExpired,
  });

  /// Login and refresh are the only calls made without a session.
  static bool _isAuthCall(RequestOptions o) =>
      o.path.contains('/auth/login') || o.path.contains('/auth/refresh');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    if (_isAuthCall(options)) return handler.next(options);

    final refresher = this.refresher;
    if (refresher != null && await refresher.accessTokenExpiring()) {
      if (await refresher.refresh() == RefreshResult.sessionEnded) {
        await _endSession();
      }
    }
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // A 401 from login means wrong credentials, not an ended session.
    if (err.response?.statusCode != 401 || _isAuthCall(options)) {
      return handler.next(err);
    }

    final refresher = this.refresher;
    if (refresher == null || options.extra[_retriedKey] == true) {
      await _endSession();
      return handler.next(err);
    }

    switch (await refresher.refresh()) {
      case RefreshResult.refreshed:
        options.extra[_retriedKey] = true;
        options.headers['Authorization'] =
            'Bearer ${await _storageService.getToken()}';
        try {
          return handler.resolve(await _dio.fetch<dynamic>(options));
        } on DioException catch (e) {
          return handler.next(e);
        }
      case RefreshResult.sessionEnded:
        await _endSession();
        return handler.next(err);
      case RefreshResult.unreachable:
        return handler.next(err);
    }
  }

  Future<void> _endSession() async {
    await _storageService.clearSession();
    onSessionExpired?.call();
  }
}
