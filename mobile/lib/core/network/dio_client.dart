import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'network_connectivity_interceptor.dart';
import 'network_connectivity_service.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  final connectivityService = ref.watch(networkConnectivityServiceProvider);
  return DioClient.createDio(storageService, connectivityService);
});

/// DioClient configures the HTTP network client instance.
class DioClient {
  static Dio createDio(
    SecureStorageService storageService,
    NetworkConnectivityService connectivityService,
  ) {
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
    dio.interceptors.add(AuthInterceptor(storageService));

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
