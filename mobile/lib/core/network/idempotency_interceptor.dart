import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/uuid.dart';

/// Gives every save an Idempotency-Key so the server performs it once.
///
/// The key belongs to the save, not to one HTTP request: while a save has
/// not had a definite answer (no reply, timeout, or "still processing"),
/// sending the same save again (an automatic retry, or the user tapping Save
/// again) reuses its key, and the server returns the first result instead of
/// recording the milk, sale or payment twice. Once the server has answered,
/// an identical save is a new one and gets a new key.
class IdempotencyInterceptor extends Interceptor {
  static const header = 'Idempotency-Key';
  static const _fingerprintKey = 'idempotency_fingerprint';

  /// How long an unanswered save keeps its key. Longer than any retry, far
  /// shorter than the server keeps keys (48 h).
  static const reuseWindow = Duration(minutes: 10);

  final _pending = <String, _Attempt>{};

  static bool _isWrite(String method) =>
      const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());

  static String _fingerprint(RequestOptions o) {
    final body = o.data == null ? '' : jsonEncode(o.data);
    return '${o.method} ${o.path} $body';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isWrite(options.method) || options.headers.containsKey(header)) {
      return handler.next(options);
    }
    final now = DateTime.now();
    _pending.removeWhere((_, a) => now.difference(a.startedAt) > reuseWindow);
    final fingerprint = _fingerprint(options);
    final attempt = _pending.putIfAbsent(
      fingerprint,
      () => _Attempt(uuidV4(), now),
    );
    options.headers[header] = attempt.key;
    options.extra[_fingerprintKey] = fingerprint;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _settle(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    // Answered (other than "still processing"): the save is settled.
    if (status != null && status != 409) _settle(err.requestOptions);
    handler.next(err);
  }

  void _settle(RequestOptions o) {
    final fingerprint = o.extra[_fingerprintKey];
    if (fingerprint is String) _pending.remove(fingerprint);
  }
}

class _Attempt {
  final String key;
  final DateTime startedAt;
  _Attempt(this.key, this.startedAt);
}
