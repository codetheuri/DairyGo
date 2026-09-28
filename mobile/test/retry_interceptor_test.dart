import 'dart:convert';
import 'dart:typed_data';

import 'package:dairy_sacco_mobile/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails the first [failures] requests with a connection error.
class _FlakyAdapter implements HttpClientAdapter {
  int failures;
  int calls = 0;
  _FlakyAdapter(this.failures);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (failures > 0) {
      failures--;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_FlakyAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(dio, delays: const [Duration.zero, Duration.zero]),
  );
  return dio;
}

void main() {
  test('a GET that drops is retried and succeeds', () async {
    final adapter = _FlakyAdapter(2);
    final res = await _dio(adapter).get('http://x/api');
    expect(res.data, {'ok': true});
    expect(adapter.calls, 3);
  });

  test('a GET gives up after the configured retries', () async {
    final adapter = _FlakyAdapter(5);
    await expectLater(
      _dio(adapter).get('http://x/api'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 3);
  });

  test('a POST is never retried, so milk is not recorded twice', () async {
    final adapter = _FlakyAdapter(1);
    await expectLater(
      _dio(adapter).post('http://x/api', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });
}
