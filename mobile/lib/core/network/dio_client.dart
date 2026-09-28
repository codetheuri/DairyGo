import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
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
  );
});

/// DioClient configures the HTTP network client instance.
class DioClient {
  static Dio createDio(
    SecureStorageService storageService,
    NetworkConnectivityService connectivityService, {
    VoidCallback? onSessionExpired,
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

    dio.interceptors.add(NetworkConnectivityInterceptor(connectivityService));
    dio.interceptors.add(AuthInterceptor(storageService, onSessionExpired: onSessionExpired));
    dio.interceptors.add(RetryInterceptor(dio));

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
