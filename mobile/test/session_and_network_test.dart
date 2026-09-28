import 'dart:async';
import 'dart:convert';

import 'package:dairy_sacco_mobile/core/network/auth_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/connection_monitor.dart';
import 'package:dairy_sacco_mobile/core/network/idempotency_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/network_connectivity_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/network_connectivity_service.dart';
import 'package:dairy_sacco_mobile/core/network/retry_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/token_refresher.dart';
import 'package:dairy_sacco_mobile/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory session storage.
class _Storage extends SecureStorageService {
  String? access = 'old';
  String? refresh = 'r1';
  DateTime? accessExpiresAt = DateTime.now().add(const Duration(hours: 1));
  bool cleared = false;
  _Storage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<DateTime?> getAccessExpiresAt() async => accessExpiresAt;
  @override
  Future<void> saveSession(SessionTokens t) async {
    access = t.accessToken;
    refresh = t.refreshToken;
    accessExpiresAt = t.accessExpiresAt;
  }

  @override
  Future<void> clearSession() async {
    access = refresh = null;
    cleared = true;
  }
}

/// A scripted server: [handle] decides each answer; null means no answer.
class _Server implements HttpClientAdapter {
  final ResponseBody? Function(RequestOptions o) handle;
  final requests = <RequestOptions>[];
  Duration delay;
  _Server(this.handle, {this.delay = Duration.zero});

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    requests.add(o);
    await Future<void>.delayed(delay);
    final res = handle(o);
    if (res == null) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.receiveTimeout,
      );
    }
    return res;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _tokens(String access, String refresh) => _json(200, {
  'success': true,
  'data': {
    'access_token': access,
    'refresh_token': refresh,
    'access_expires_at': DateTime.now()
        .add(const Duration(hours: 1))
        .toIso8601String(),
  },
});

Dio _dioFor(_Server server) =>
    Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = server;

void main() {
  group('session renewal', () {
    test('simultaneous renewals send one request', () async {
      final storage = _Storage();
      final server = _Server(
        (_) => _tokens('new', 'r2'),
        delay: const Duration(milliseconds: 50),
      );
      final refresher = TokenRefresher(storage, dio: _dioFor(server));
      final results = await Future.wait([
        for (var i = 0; i < 5; i++) refresher.refresh(),
      ]);
      expect(results.toSet(), {RefreshResult.refreshed});
      expect(server.requests, hasLength(1));
      expect(storage.access, 'new');
      expect(storage.refresh, 'r2');
    });

    test('a refused renewal ends the session; no answer does not', () async {
      final refused = TokenRefresher(
        _Storage(),
        dio: _dioFor(_Server((_) => _json(401, {'success': false}))),
      );
      expect(await refused.refresh(), RefreshResult.sessionEnded);

      final offline = TokenRefresher(
        _Storage(),
        dio: _dioFor(_Server((_) => null)),
      );
      expect(await offline.refresh(), RefreshResult.unreachable);
    });

    Future<({Dio dio, _Storage storage, List<bool> ended})> client({
      required ResponseBody? Function(RequestOptions) refreshAnswer,
    }) async {
      final storage = _Storage();
      final ended = <bool>[];
      final api = _Server(
        (o) => o.headers['Authorization'] == 'Bearer new'
            ? _json(200, {'ok': true})
            : _json(401, {'message': 'Unauthorized'}),
      );
      final dio = _dioFor(api);
      dio.interceptors.add(
        AuthInterceptor(
          dio,
          storage,
          refresher: TokenRefresher(
            storage,
            dio: _dioFor(_Server(refreshAnswer)),
          ),
          onSessionExpired: () => ended.add(true),
        ),
      );
      return (dio: dio, storage: storage, ended: ended);
    }

    test(
      'an expired access token is renewed and the request retried',
      () async {
        final c = await client(refreshAnswer: (_) => _tokens('new', 'r2'));
        final res = await c.dio.get('/data');
        expect(res.data, {'ok': true});
        expect(c.ended, isEmpty);
      },
    );

    test('the server ending the session signs the user out', () async {
      final c = await client(refreshAnswer: (_) => _json(401, {}));
      await expectLater(c.dio.get('/data'), throwsA(isA<DioException>()));
      expect(c.ended, [true]);
      expect(c.storage.cleared, isTrue);
    });

    test('losing the signal while renewing never signs the user out', () async {
      final c = await client(refreshAnswer: (_) => null);
      await expectLater(c.dio.get('/data'), throwsA(isA<DioException>()));
      expect(c.ended, isEmpty);
      expect(c.storage.cleared, isFalse);
    });

    test('a token about to expire is renewed before the request', () async {
      final storage = _Storage()
        ..accessExpiresAt = DateTime.now().add(const Duration(seconds: 30));
      final refreshServer = _Server((_) => _tokens('new', 'r2'));
      final api = _Server(
        (o) => _json(200, {'auth': o.headers['Authorization']}),
      );
      final dio = _dioFor(api);
      dio.interceptors.add(
        AuthInterceptor(
          dio,
          storage,
          refresher: TokenRefresher(storage, dio: _dioFor(refreshServer)),
        ),
      );
      final res = await dio.get('/data');
      expect(res.data, {'auth': 'Bearer new'});
      expect(refreshServer.requests, hasLength(1));
      expect(api.requests, hasLength(1), reason: 'no failed first attempt');
    });
  });

  group('saves are recorded once', () {
    test('a retried save reuses its key; a new save gets a new one', () async {
      var answer = false;
      final server = _Server((_) => answer ? _json(200, {'ok': true}) : null);
      final dio = _dioFor(server)..interceptors.add(IdempotencyInterceptor());
      String key(int i) =>
          server.requests[i].headers[IdempotencyInterceptor.header] as String;

      final sale = {'customer_id': 'c1', 'quantity_litres': 20};
      await expectLater(dio.post('/sales', data: sale), throwsA(anything));
      answer = true;
      await dio.post('/sales', data: sale); // the user taps Save again
      expect(key(1), key(0), reason: 'unanswered save keeps its key');

      await dio.post('/sales', data: sale); // a genuinely new, identical sale
      expect(key(2), isNot(key(1)));
      await dio.post('/sales', data: {...sale, 'quantity_litres': 5});
      expect(key(3), isNot(key(2)));

      await dio.get('/sales');
      expect(
        server.requests.last.headers[IdempotencyInterceptor.header],
        isNull,
      );
    });

    test(
      'keyed saves are retried automatically; unkeyed ones are not',
      () async {
        var calls = 0;
        final server = _Server(
          (_) => ++calls < 2 ? null : _json(200, {'ok': 1}),
        );
        final keyed = _dioFor(server);
        keyed.interceptors
          ..add(IdempotencyInterceptor())
          ..add(RetryInterceptor(keyed, delays: const [Duration.zero]));
        expect((await keyed.post('/sales', data: {'a': 1})).data, {'ok': 1});
        final sent = server.requests
            .map((r) => r.headers[IdempotencyInterceptor.header])
            .toSet();
        expect(sent, hasLength(1), reason: 'the retry used the same key');

        calls = 0;
        final plain = _dioFor(server);
        plain.interceptors.add(
          RetryInterceptor(plain, delays: const [Duration.zero]),
        );
        await expectLater(
          plain.post('/sales', data: {'a': 1}),
          throwsA(anything),
        );
      },
    );
  });

  group('connection monitor', () {
    late ProviderContainer container;
    late ConnectionMonitor monitor;
    late bool healthUp;

    setUp(() {
      healthUp = true;
      container = ProviderContainer(
        overrides: [
          networkConnectivityServiceProvider.overrideWithValue(_Network()),
        ],
      );
      container.listen(connectionMonitorProvider, (_, __) {});
      monitor = container.read(connectionMonitorProvider.notifier)
        ..probeClient = _dioFor(
          _Server((_) => healthUp ? _json(200, {'status': 'ok'}) : null),
        );
    });
    tearDown(() => container.dispose());

    ConnectionQuality quality() =>
        container.read(connectionMonitorProvider).quality;

    test('quick answers are online, slow ones slow', () {
      for (var i = 0; i < 3; i++) {
        monitor.reportAnswered(const Duration(milliseconds: 300));
      }
      expect(quality(), ConnectionQuality.online);
      for (var i = 0; i < 3; i++) {
        monitor.reportAnswered(const Duration(seconds: 5));
      }
      expect(quality(), ConnectionQuality.slow);
    });

    test('a request waiting long shows slow, then clears', () {
      monitor.reportAnswered(const Duration(milliseconds: 300));
      monitor.slowRequestStarted();
      expect(quality(), ConnectionQuality.slow);
      monitor.slowRequestDone();
      expect(quality(), ConnectionQuality.online);
    });

    test('no answers mean offline; the health check brings it back', () async {
      healthUp = false;
      monitor.reportNoAnswer();
      monitor.reportNoAnswer();
      expect(quality(), ConnectionQuality.offline);

      healthUp = true;
      expect(await monitor.checkNow(), isTrue);
      expect(quality(), ConnectionQuality.online);
      expect(container.read(connectionMonitorProvider).lastOnlineAt, isNotNull);
    });

    test('offline: reads stop at once, saves check first', () async {
      healthUp = false;
      monitor.reportNoAnswer();
      monitor.reportNoAnswer();

      final api = _Server((_) => _json(200, {}));
      final dio = _dioFor(api)
        ..interceptors.add(
          NetworkConnectivityInterceptor(_Network(), monitor: monitor),
        );
      final read = dio.get('/list');
      await expectLater(
        read,
        throwsA(
          isA<DioException>().having(
            (e) => e.message,
            'message',
            ConnectionMessages.noInternet,
          ),
        ),
      );
      await expectLater(
        dio.post('/sales', data: {}),
        throwsA(
          isA<DioException>().having(
            (e) => e.message,
            'message',
            ConnectionMessages.cannotSave,
          ),
        ),
      );
      expect(api.requests, isEmpty, reason: 'nothing was sent while offline');

      healthUp = true; // the signal is back: the save checks and goes out
      await dio.post('/sales', data: {});
      expect(api.requests, hasLength(1));
    });
  });
}

class _Network extends NetworkConnectivityService {
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Future<bool> checkHasConnection() async => true;
}
