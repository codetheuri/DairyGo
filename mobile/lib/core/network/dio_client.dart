import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../cache/response_cache.dart';
import 'auth_interceptor.dart';
import 'cache_interceptor.dart';
import 'network_connectivity_interceptor.dart';
import 'network_connectivity_service.dart';
import 'retry_interceptor.dart';

/// Dio for the auth endpoints (login, current user, staff). The session is
/// built from these calls, so this client must not depend on it.
final authDioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  final connectivityService = ref.watch(networkConnectivityServiceProvider);
  return DioClient.createDio(storageService, connectivityService);
});

/// Dio for all Sacco data. It is rebuilt whenever the signed-in user changes,
/// so every provider that fetches through it reloads for the new session
/// instead of briefly showing the previous user's data or errors.
final dioClientProvider = Provider<Dio>((ref) {
  ref.watch(sessionUserIdProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final connectivityService = ref.watch(networkConnectivityServiceProvider);
  final auth = ref.read(authControllerProvider.notifier);
  return DioClient.createDio(
    storageService,
    connectivityService,
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
    VoidCallback? onSessionExpired,
    ResponseCache? cache,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Order matters: a saved copy is served before any network work, and
    // responses are saved after auth and retries have run.
    if (cache != null) dio.interceptors.add(CacheFirstInterceptor(dio, cache));
    dio.interceptors.add(NetworkConnectivityInterceptor(connectivityService));
    dio.interceptors.add(
      AuthInterceptor(storageService, onSessionExpired: onSessionExpired),
    );
    dio.interceptors.add(RetryInterceptor(dio));
    if (cache != null) dio.interceptors.add(CacheStoreInterceptor(cache));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    return dio;
  }
}
