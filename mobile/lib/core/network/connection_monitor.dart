import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'network_connectivity_service.dart';

/// How well the app can reach the DairyGo server right now.
enum ConnectionQuality {
  /// Requests are answered promptly.
  online,

  /// Requests get through but take several seconds.
  slow,

  /// Requests are not answered: no signal, no data bundle, or the server
  /// cannot be reached.
  offline,
}

class ConnectionStatus {
  final ConnectionQuality quality;

  /// When the server last answered; shown as "saved data from 10:42".
  final DateTime? lastOnlineAt;

  const ConnectionStatus(this.quality, {this.lastOnlineAt});

  bool get isOffline => quality == ConnectionQuality.offline;
  bool get isSlow => quality == ConnectionQuality.slow;
}

/// Judges the connection from real traffic, not only from whether Wi-Fi or
/// mobile data is switched on: a phone can be "connected" with no data
/// bundle, and then nothing loads.
///
/// - Every API response reports how long it took; the median of the last few
///   decides between online and slow.
/// - A request still unanswered after [slowAfter] marks the connection slow
///   while it waits.
/// - Requests that get no answer at all, or the phone reporting no network,
///   mark it offline; the server's /health is then checked with growing
///   pauses until it answers.
class ConnectionMonitor extends Notifier<ConnectionStatus> {
  /// A typical request slower than this means a slow connection.
  static const slowThreshold = Duration(milliseconds: 2500);

  /// A request waiting longer than this shows the slow banner meanwhile.
  static const slowAfter = Duration(seconds: 4);

  static const _window = 5;
  static const _probeTimeout = Duration(seconds: 6);
  static const _probeDelays = [5, 10, 20, 30]; // seconds

  final _latencies = <Duration>[];
  int _failuresInARow = 0;
  int _inFlightSlow = 0;
  Timer? _probeTimer;
  int _probeRound = 0;
  Future<bool>? _probing;
  late Dio _probeDio;

  @override
  ConnectionStatus build() {
    _probeDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
      ),
    );
    final sub = ref
        .watch(networkConnectivityServiceProvider)
        .onConnectivityChanged
        .listen(_onNetworkChanged, onError: (_) {});
    ref.onDispose(() {
      sub.cancel();
      _probeTimer?.cancel();
    });
    return const ConnectionStatus(ConnectionQuality.online);
  }

  /// The current status, for code outside widgets (e.g. interceptors).
  ConnectionStatus get current => state;

  /// Uses [dio] for health checks instead of a real one (tests).
  set probeClient(Dio dio) => _probeDio = dio;

  void _onNetworkChanged(bool hasNetwork) {
    if (!hasNetwork) {
      _setOffline();
    } else if (state.isOffline) {
      unawaited(checkNow());
    }
  }

  /// A response arrived after [elapsed] (any status: the server answered).
  void reportAnswered(Duration elapsed) {
    _failuresInARow = 0;
    // The server answered: no need for the scheduled health check.
    _probeTimer?.cancel();
    _probeRound = 0;
    _latencies.add(elapsed);
    if (_latencies.length > _window) _latencies.removeAt(0);
    _publish(answered: true);
  }

  /// A request got no answer at all.
  void reportNoAnswer() {
    _failuresInARow++;
    if (_failuresInARow >= 2) {
      _setOffline();
    } else {
      unawaited(checkNow());
    }
  }

  /// A request has been waiting longer than [slowAfter]; call [slowRequestDone]
  /// when it finishes.
  void slowRequestStarted() {
    _inFlightSlow++;
    _publish();
  }

  void slowRequestDone() {
    if (_inFlightSlow > 0) _inFlightSlow--;
    _publish();
  }

  /// Asks the server's /health whether it can be reached. Concurrent callers
  /// share one check. Returns whether the server answered.
  Future<bool> checkNow() => _probing ??= _probe().whenComplete(() {
    _probing = null;
  });

  Future<bool> _probe() async {
    final started = DateTime.now();
    try {
      await _probeDio.get<dynamic>('/health');
      _probeTimer?.cancel();
      _probeRound = 0;
      reportAnswered(DateTime.now().difference(started));
      return true;
    } catch (_) {
      _setOffline();
      return false;
    }
  }

  void _setOffline() {
    _latencies.clear();
    state = ConnectionStatus(
      ConnectionQuality.offline,
      lastOnlineAt: state.lastOnlineAt,
    );
    _scheduleProbe();
  }

  void _scheduleProbe() {
    if (_probeTimer?.isActive ?? false) return;
    final seconds = _probeDelays[_probeRound.clamp(0, _probeDelays.length - 1)];
    _probeRound++;
    _probeTimer = Timer(Duration(seconds: seconds), () => checkNow());
  }

  /// Recomputes online/slow. Only an answer from the server ([answered])
  /// can bring the status back from offline; a request merely waiting cannot.
  void _publish({bool answered = false}) {
    if (state.isOffline && !answered) return;
    final sorted = [..._latencies]..sort();
    final median = sorted.isEmpty ? Duration.zero : sorted[sorted.length ~/ 2];
    final slow = _inFlightSlow > 0 || median > slowThreshold;
    final quality = slow ? ConnectionQuality.slow : ConnectionQuality.online;
    final lastOnlineAt = answered ? DateTime.now() : state.lastOnlineAt;
    if (quality == state.quality && lastOnlineAt == state.lastOnlineAt) return;
    state = ConnectionStatus(quality, lastOnlineAt: lastOnlineAt);
  }
}

final connectionMonitorProvider =
    NotifierProvider<ConnectionMonitor, ConnectionStatus>(
      ConnectionMonitor.new,
    );

/// Feeds every request's outcome to the [ConnectionMonitor].
class ConnectionMonitorInterceptor extends Interceptor {
  final ConnectionMonitor _monitor;
  static const _startedKey = 'monitor_started';
  static const _timerKey = 'monitor_timer';
  static const _slowKey = 'monitor_slow';

  ConnectionMonitorInterceptor(this._monitor);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedKey] = DateTime.now();
    options.extra[_timerKey] = Timer(ConnectionMonitor.slowAfter, () {
      options.extra[_slowKey] = true;
      _monitor.slowRequestStarted();
    });
    handler.next(options);
  }

  void _finish(RequestOptions o, {required bool answered}) {
    (o.extra[_timerKey] as Timer?)?.cancel();
    if (o.extra.remove(_slowKey) == true) _monitor.slowRequestDone();
    final started = o.extra[_startedKey] as DateTime?;
    if (started == null) return;
    if (answered) {
      _monitor.reportAnswered(DateTime.now().difference(started));
    } else {
      _monitor.reportNoAnswer();
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions, answered: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final noAnswer =
        err.response == null &&
        err.type != DioExceptionType.cancel &&
        err.type != DioExceptionType.badCertificate;
    _finish(err.requestOptions, answered: !noAnswer);
    handler.next(err);
  }
}
