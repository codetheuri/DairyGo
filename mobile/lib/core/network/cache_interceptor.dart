import 'dart:async';

import 'package:dio/dio.dart';

import '../cache/response_cache.dart';

/// Keys used in [RequestOptions.extra].
abstract class CacheExtra {
  /// Set on a response that came from the phone rather than the server.
  static const fromCache = 'from_cache';

  /// Set on the silent request that checks a shown copy is still current.
  static const background = 'cache_background';
}

String _cacheKey(RequestOptions o) {
  final params =
      o.queryParameters.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
  return '${o.path}?${params.join('&')}';
}

Response<dynamic> _cachedResponse(RequestOptions o, CachedResponse entry) =>
    Response<dynamic>(
      requestOptions: o,
      data: entry.data,
      statusCode: 200,
      extra: {CacheExtra.fromCache: true},
    );

/// First in the chain: answers a GET from the phone when a usable copy is
/// saved, so the screen appears at once, then asks the server in the
/// background ("stale-while-revalidate"). If the server's answer differs,
/// [ResponseCache.updates] fires and open screens reload from the new copy.
class CacheFirstInterceptor extends Interceptor {
  final Dio _dio;
  final ResponseCache _cache;
  final _refreshing = <String>{};

  CacheFirstInterceptor(this._dio, this._cache);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method != 'GET' ||
        options.extra[CacheExtra.background] == true) {
      return handler.next(options);
    }
    final key = _cacheKey(options);
    final entry = await _cache.read(key);
    if (entry == null || !_cache.canShowInstantly(entry)) {
      return handler.next(options);
    }
    handler.resolve(_cachedResponse(options, entry));
    if (!_cache.isFresh(entry)) unawaited(_refresh(key, options));
  }

  Future<void> _refresh(String key, RequestOptions options) async {
    if (!_refreshing.add(key)) return; // already being refreshed
    try {
      await _dio.fetch<dynamic>(
        options.copyWith(
          extra: {...options.extra, CacheExtra.background: true},
        ),
      );
    } catch (_) {
      // Offline or failed: the saved copy stays on screen.
    } finally {
      _refreshing.remove(key);
    }
  }
}

/// Last in the chain: saves every successful GET, marks saved copies out of
/// date after the user changes data, and answers from the phone when the
/// server cannot be reached.
class CacheStoreInterceptor extends Interceptor {
  final ResponseCache _cache;

  CacheStoreInterceptor(this._cache);

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final o = response.requestOptions;
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      if (o.method == 'GET') {
        final changed = await _cache.write(_cacheKey(o), response.data);
        if (changed && o.extra[CacheExtra.background] == true) {
          _cache.notifyUpdated();
        }
      } else {
        _cache.markAllStale(); // a record was added or changed
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final o = err.requestOptions;
    // Only when there was no answer at all; a real error from the server
    // (403, 404, 422...) must reach the screen.
    if (o.method == 'GET' &&
        err.response == null &&
        o.extra[CacheExtra.background] != true) {
      final entry = await _cache.read(_cacheKey(o));
      if (entry != null) return handler.resolve(_cachedResponse(o, entry));
    }
    handler.next(err);
  }
}
