import 'package:dio/dio.dart';

/// Retries reads (GET) that failed because the connection dropped or timed
/// out, which is common on weak rural networks. Writes are never retried: a
/// POST whose response was lost may already have been saved, and repeating it
/// could record the same milk twice.
class RetryInterceptor extends Interceptor {
  final Dio _dio;

  /// Waits before each retry; the list length is the number of retries.
  final List<Duration> delays;

  RetryInterceptor(this._dio, {this.delays = const [Duration(seconds: 1), Duration(seconds: 3)]});

  static const _attemptKey = 'retry_attempt';

  static bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (options.method != 'GET' || !_isTransient(err) || attempt >= delays.length) {
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
