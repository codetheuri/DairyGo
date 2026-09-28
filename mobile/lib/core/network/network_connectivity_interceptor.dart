import 'package:dio/dio.dart';

import 'connection_monitor.dart';
import 'network_connectivity_service.dart';

/// Set on a request that failed because the phone has no connection.
const offlineExtra = 'offline';

/// Messages shown to the user when a request could not get through.
abstract class ConnectionMessages {
  static const noInternet =
      'No internet connection. Check your signal or data bundle and try again.';
  static const cannotSave =
      'No internet connection, so this was not saved. Check your signal or '
      'data bundle and try again.';
  static const tooSlow =
      'The connection is too slow and the server did not answer in time. '
      'Please try again.';
}

/// Stops requests early when there is no connection, so screens fall back to
/// saved data at once instead of waiting for a timeout, and turns network
/// failures into messages a user can act on.
class NetworkConnectivityInterceptor extends Interceptor {
  final NetworkConnectivityService _connectivityService;
  final ConnectionMonitor? monitor;

  NetworkConnectivityInterceptor(this._connectivityService, {this.monitor});

  static bool _isWrite(String method) =>
      const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var reachable = await _connectivityService.checkHasConnection();
    final monitor = this.monitor;
    if (reachable && monitor != null && monitor.current.isOffline) {
      // Reads fall back to saved data straight away. A save checks once
      // more first, so a stale "offline" never blocks a real save.
      reachable = _isWrite(options.method) && await monitor.checkNow();
    }
    if (!reachable) {
      options.extra[offlineExtra] = true; // retrying cannot help
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: _isWrite(options.method)
              ? ConnectionMessages.cannotSave
              : ConnectionMessages.noInternet,
        ),
        // Let later interceptors see it too, so a saved copy can be shown.
        true,
      );
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String? message = switch (err.type) {
      DioExceptionType.connectionError =>
        _isWrite(err.requestOptions.method)
            ? ConnectionMessages.cannotSave
            : ConnectionMessages.noInternet,
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => ConnectionMessages.tooSlow,
      _ => null,
    };
    if (message == null || err.message == ConnectionMessages.cannotSave) {
      return handler.next(err);
    }
    handler.next(err.copyWith(message: message));
  }
}
