import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../cache/response_cache.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'cache_interceptor.dart';
import 'connection_monitor.dart';
import 'idempotency_interceptor.dart';
import 'network_connectivity_interceptor.dart';
import 'network_connectivity_service.dart';
import 'retry_interceptor.dart';
import 'token_refresher.dart';

/// One connection pool for the whole app. Opening a connection costs a TCP
/// and TLS handshake, measured at 0.6–2.6 s on a slow link, so connections
/// are kept for 55 s between requests (Dart's default is 15 s) instead of
/// being reopened after every short pause. The server keeps them for 60 s.
final HttpClient _sharedHttpClient = HttpClient()
  ..idleTimeout = const Duration(seconds: 55)
  ..connectionTimeout = ApiConstants.connectionTimeout;

/// Renews the session. Shared by every client so concurrent renewals become
/// one request (the server rotates the refresh token on each use).
final tokenRefresherProvider = Provider<TokenRefresher>((ref) {
  return TokenRefresher(ref.watch(secureStorageServiceProvider));
});

/// Dio for the auth endpoints (login, current user, staff). The session is
/// built from these calls, so this client must not depend on it.
final authDioProvider = Provider<Dio>((ref) {
  return DioClient.createDio(
    ref.watch(secureStorageServiceProvider),
    ref.watch(networkConnectivityServiceProvider),
    refresher: ref.watch(tokenRefresherProvider),
    monitor: ref.read(connectionMonitorProvider.notifier),
  );
});

/// Dio for all Sacco data. It is rebuilt whenever the signed-in user changes,
/// so every provider that fetches through it reloads for the new session
/// instead of briefly showing the previous user's data or errors.
final dioClientProvider = Provider<Dio>((ref) {
  ref.watch(sessionUserIdProvider);
  final auth = ref.read(authControllerProvider.notifier);
  return DioClient.createDio(
    ref.watch(secureStorageServiceProvider),
    ref.watch(networkConnectivityServiceProvider),
    refresher: ref.watch(tokenRefresherProvider),
    monitor: ref.read(connectionMonitorProvider.notifier),
    onSessionExpired: auth.expireSession,
    cache: ref.watch(responseCacheProvider),
  );
});

/// Responses saved on the phone for the signed-in user; null when signed out.
final responseCacheProvider = Provider<ResponseCache?>((ref) {
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) return null;
  final cache = ResponseCache.forUser(userId);
  ref.onDispose(cache.dispose);
  return cache;
});

/// Lets a provider reload when a background refresh brings newer data than
/// the saved copy it showed. The reload reads the just-saved copy, so it is
/// instant and needs no network.
extension ReloadOnNewerData on Ref {
  void reloadWhenNewerDataArrives({bool Function()? when}) {
    final cache = read(responseCacheProvider);
    if (cache == null) return;
    final sub = cache.updates.listen((_) {
      if (when == null || when()) invalidateSelf();
    });
    onDispose(sub.cancel);
  }
}

/// DioClient configures the HTTP network client instance.
class DioClient {
  static Dio createDio(
    SecureStorageService storageService,
    NetworkConnectivityService connectivityService, {
    TokenRefresher? refresher,
    ConnectionMonitor? monitor,
    VoidCallback? onSessionExpired,
    ResponseCache? cache,
  }) {
    final dio =
        Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectionTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          )
          ..httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () => _sharedHttpClient,
          );

    // Order matters:
    // 1. a saved copy is served before any network work;
    // 2. no connection stops the request early;
    // 3. the monitor times what really goes out;
    // 4. the session is renewed and the token attached;
    // 5. saves get their Idempotency-Key before any retry;
    // 6. dropped reads and keyed saves are retried;
    // 7. successful reads are saved on the phone.
    if (cache != null) dio.interceptors.add(CacheFirstInterceptor(dio, cache));
    dio.interceptors.add(
      NetworkConnectivityInterceptor(connectivityService, monitor: monitor),
    );
    if (monitor != null) {
      dio.interceptors.add(ConnectionMonitorInterceptor(monitor));
    }
    dio.interceptors.add(
      AuthInterceptor(
        dio,
        storageService,
        refresher: refresher,
        onSessionExpired: onSessionExpired,
      ),
    );
    dio.interceptors.add(IdempotencyInterceptor());
    dio.interceptors.add(RetryInterceptor(dio));
    if (cache != null) dio.interceptors.add(CacheStoreInterceptor(cache));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    return dio;
  }
}
