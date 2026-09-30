import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// The outcome of renewing the session.
enum RefreshResult {
  /// New tokens are saved.
  refreshed,

  /// The server ended the session (idle too long, logged out elsewhere,
  /// account deactivated): the user must sign in again.
  sessionEnded,

  /// No answer (no signal, timeout, server down). The session may still be
  /// valid, so the user must not be signed out.
  unreachable,
}

/// Renews the access token with the refresh token. One instance is shared by
/// every HTTP client, and concurrent callers share one request: the server
/// rotates the refresh token on each use, so parallel refreshes would race.
class TokenRefresher {
  final SecureStorageService _storage;
  final Dio _dio;
  Future<RefreshResult>? _inFlight;

  /// [dio] must have no auth interceptor (the refresh call must not trigger
  /// another refresh); tests pass their own.
  TokenRefresher(this._storage, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectionTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: {'Accept': 'application/json'},
            ),
          );

  /// How long before expiry the access token is renewed, so a request never
  /// leaves with a token that expires on the way.
  static const renewBefore = Duration(minutes: 2);

  Future<RefreshResult> refresh() =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  /// Whether the saved access token is expired or about to expire.
  Future<bool> accessTokenExpiring() async {
    final expiresAt = await _storage.getAccessExpiresAt();
    return expiresAt != null &&
        DateTime.now().isAfter(expiresAt.subtract(renewBefore));
  }

  Future<RefreshResult> _refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshResult.sessionEnded;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return RefreshResult.unreachable;
      await _storage.saveSession(SessionTokens.fromJson(data));
      return RefreshResult.refreshed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) return RefreshResult.sessionEnded;
      return RefreshResult.unreachable;
    }
  }
}
