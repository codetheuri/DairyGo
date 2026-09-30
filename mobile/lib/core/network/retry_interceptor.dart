import 'package:dio/dio.dart';

import 'idempotency_interceptor.dart';
import 'network_connectivity_interceptor.dart';

/// Retries requests that failed because the connection dropped or timed
/// out, which is common on weak rural networks.
///
/// - Reads (GET) are always safe to retry.
/// - Saves are retried only when they carry an Idempotency-Key: the server
///   then performs them once, however many times they arrive. A save the
///   server reports as "still processing" (409) is retried too, to collect
///   its result.
/// - Nothing is retried when the phone has no connection at all.
class RetryInterceptor extends Interceptor {
  final Dio _dio;

  /// Waits before each retry; the list length is the number of retries.
  final List<Duration> delays;

  RetryInterceptor(
    this._dio, {
    this.delays = const [Duration(seconds: 1), Duration(seconds: 3)],
  });

  static const _attemptKey = 'retry_attempt';

  static bool _noAnswer(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      default:
        return false;
    }
  }

  static bool _retryable(DioException err) {
    final o = err.requestOptions;
    if (o.extra[offlineExtra] == true) return false;
    if (o.method == 'GET') return _noAnswer(err);
    if (!o.headers.containsKey(IdempotencyInterceptor.header)) return false;
    return _noAnswer(err) || err.response?.statusCode == 409;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!_retryable(err) || attempt >= delays.length) {
      return handler.next(err);
    }

    await Future<void>.delayed(delays[attempt]);
    options.extra[_attemptKey] = attempt + 1;
    try {
      return handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      // The retried request already went through the interceptors, including
      // this one, so its error is final.
      return handler.next(e);
    }
  }
}
