// Runs the app's real network layer against a local API with test data.
// Skipped unless LIVE_API is set:
//
//   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://localhost:18081 \
//     --dart-define=LIVE_USER=user --dart-define=LIVE_PASS=pass
//
// Never point it at production: it records a sale.

import 'package:dairy_sacco_mobile/core/network/auth_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/idempotency_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/retry_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/token_refresher.dart';
import 'package:dairy_sacco_mobile/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = String.fromEnvironment('LIVE_API');
const _user = String.fromEnvironment('LIVE_USER');
const _pass = String.fromEnvironment('LIVE_PASS');

class _Storage extends SecureStorageService {
  SessionTokens? tokens;
  bool cleared = false;
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getToken() async => tokens?.accessToken;
  @override
  Future<String?> getRefreshToken() async => tokens?.refreshToken;
  @override
  Future<DateTime?> getAccessExpiresAt() async => tokens?.accessExpiresAt;
  @override
  Future<void> saveSession(SessionTokens t) async => tokens = t;
  @override
  Future<void> clearSession() async => cleared = true;
}

void main() {
  test(
    'login, renewal and a keyed save against the real API',
    () async {
      final storage = _Storage();
      final plain = Dio(BaseOptions(baseUrl: _api));
      final login = await plain.post(
        '/api/v1/auth/login',
        data: {'login': _user, 'password': _pass},
      );
      storage.tokens = SessionTokens.fromJson(login.data['data']);
      expect(storage.tokens!.accessExpiresAt, isNotNull);
      expect(storage.tokens!.sessionExpiresAt, isNotNull);

      // Pretend the access token expired: the next request must renew first.
      final firstRefresh = storage.tokens!.refreshToken;
      storage.tokens = SessionTokens(
        accessToken: 'expired',
        refreshToken: firstRefresh,
        accessExpiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final dio = Dio(BaseOptions(baseUrl: _api));
      dio.interceptors
        ..add(
          AuthInterceptor(
            dio,
            storage,
            refresher: TokenRefresher(
              storage,
              dio: Dio(BaseOptions(baseUrl: _api)),
            ),
          ),
        )
        ..add(IdempotencyInterceptor())
        ..add(RetryInterceptor(dio));

      final customers = await dio.get(
        '/api/v1/sacco/customers',
        queryParameters: {'per_page': 1},
      );
      expect(customers.statusCode, 200);
      expect(
        storage.tokens!.refreshToken,
        isNot(firstRefresh),
        reason: 'rotated',
      );
      expect(storage.cleared, isFalse);

      // The same save sent twice with its key is recorded once.
      final customerId = customers.data['data']['customers'][0]['id'];
      final sale = {
        'customer_id': customerId,
        'quantity_litres': 7,
        'amount_paid': 0,
      };
      final key = 'live-${DateTime.now().microsecondsSinceEpoch}';
      final opts = Options(headers: {IdempotencyInterceptor.header: key});
      final a = await dio.post(
        '/api/v1/sacco/milk-sales',
        data: sale,
        options: opts,
      );
      final b = await dio.post(
        '/api/v1/sacco/milk-sales',
        data: sale,
        options: opts,
      );
      expect(b.data['data']['sale']['id'], a.data['data']['sale']['id']);
      expect(b.headers.value('idempotent-replayed'), 'true');
    },
    skip: _api.isEmpty ? 'set --dart-define=LIVE_API to run' : false,
  );
}
