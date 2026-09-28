import 'package:dio/dio.dart';
import 'network_connectivity_service.dart';

class NetworkConnectivityInterceptor extends Interceptor {
  final NetworkConnectivityService _connectivityService;

  NetworkConnectivityInterceptor(this._connectivityService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final hasConnection = await _connectivityService.checkHasConnection();
    if (!hasConnection) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No Internet Connection. Please check your network connection.',
        ),
      );
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      final customError = DioException(
        requestOptions: err.requestOptions,
        type: err.type,
        response: err.response,
        error: err.type == DioExceptionType.connectionError
            ? 'No internet connection. Please verify your mobile data or Wi-Fi.'
            : 'The network is too slow right now and the server did not answer in time. Please try again.',
      );
      return super.onError(customError, handler);
    }
    super.onError(err, handler);
  }
}
