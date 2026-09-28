import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/core/cache/response_cache.dart';
import 'package:dairy_sacco_mobile/core/errors/failure.dart';
import 'package:dairy_sacco_mobile/core/network/cache_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/network_connectivity_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/network_connectivity_service.dart';
import 'package:dairy_sacco_mobile/core/network/retry_interceptor.dart';
import 'package:dairy_sacco_mobile/core/storage/secure_storage_service.dart';
import 'package:dairy_sacco_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dairy_sacco_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server whose answer, status and reachability the test controls.
class _Server implements HttpClientAdapter {
  int calls = 0;
  int status = 200;
  bool reachable = true;
  Object body = {'n': 1};

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    calls++;
    if (!reachable) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late _Server server;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cache_test');
    server = _Server();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Dio client(ResponseCache cache) {
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = server;
    dio.interceptors
      ..add(CacheFirstInterceptor(dio, cache))
      ..add(CacheStoreInterceptor(cache));
    return dio;
  }

  test('a fresh saved copy is shown without asking the server', () async {
    final dio = client(ResponseCache(() async => dir));
    await dio.get('/list', queryParameters: {'page': 1});
    final res = await dio.get('/list', queryParameters: {'page': 1});
    expect(res.data, {'n': 1});
    expect(res.extra[CacheExtra.fromCache], isTrue);
    expect(server.calls, 1);
  });

  test(
    'an old copy is shown at once, refreshed, and newer data is announced',
    () async {
      final cache = ResponseCache(() async => dir, freshFor: Duration.zero);
      final dio = client(cache);
      await dio.get('/dash');
      server.body = {'n': 2};
      final announced = cache.updates.first;

      final shown = await dio.get('/dash');
      expect(shown.data, {'n': 1}, reason: 'the saved copy appears instantly');
      await announced.timeout(const Duration(seconds: 2));
      expect((await cache.read('/dash?'))!.data, {'n': 2});
    },
  );

  test('saved copies survive a restart of the app', () async {
    await client(ResponseCache(() async => dir)).get('/dash');
    final restarted = client(ResponseCache(() async => dir));
    expect((await restarted.get('/dash')).extra[CacheExtra.fromCache], isTrue);
    expect(server.calls, 1);
  });

  test('after recording something, the next read goes to the server', () async {
    final dio = client(ResponseCache(() async => dir));
    await dio.get('/list');
    await dio.post('/list', data: {});
    server.body = {'n': 2};
    final res = await dio.get('/list');
    expect(res.data, {'n': 2});
    expect(res.extra[CacheExtra.fromCache], isNot(true));
  });

  test('offline, the saved copy is shown instead of an error', () async {
    final cache = ResponseCache(() async => dir);
    final dio = client(cache);
    await dio.get('/list');
    cache.markAllStale(); // not shown instantly any more
    server.reachable = false;
    final res = await dio.get('/list');
    expect(res.data, {'n': 1});
    expect(res.extra[CacheExtra.fromCache], isTrue);
  });

  test('with no signal the full chain shows the saved copy at once', () async {
    final cache = ResponseCache(() async => dir);
    final online = client(cache);
    await online.get('/list');
    cache.markAllStale();

    final phone = _NoSignal();
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = server;
    dio.interceptors
      ..add(CacheFirstInterceptor(dio, cache))
      ..add(NetworkConnectivityInterceptor(phone))
      ..add(RetryInterceptor(dio, delays: const [Duration(seconds: 30)]))
      ..add(CacheStoreInterceptor(cache));
    final started = DateTime.now();
    final res = await dio.get('/list');
    expect(res.data, {'n': 1});
    expect(
      DateTime.now().difference(started).inSeconds,
      lessThan(5),
      reason: 'no retry wait when offline',
    );
    expect(server.calls, 1, reason: 'the network was never tried');
  });

  test('a real server error is not hidden behind a saved copy', () async {
    final cache = ResponseCache(() async => dir);
    final dio = client(cache);
    await dio.get('/list');
    cache.markAllStale();
    server.status = 403;
    await expectLater(dio.get('/list'), throwsA(isA<DioException>()));
  });

  group('start-up without signal', () {
    const user = UserEntity(id: 7, email: 'c@x.io', username: 'col');

    test('keeps the saved session when the server cannot be reached', () async {
      final storage = _MemoryStorage()
        ..token = 't'
        ..userJson = jsonEncode(user.toJson());
      final repo = AuthRepositoryImpl(_Unreachable(), storage);
      expect((await repo.getCurrentUser())?.id, 7);
      expect(storage.token, 't', reason: 'the user stays signed in');
    });

    test('signs out when the server rejects the session', () async {
      final storage = _MemoryStorage()
        ..token = 't'
        ..userJson = jsonEncode(user.toJson());
      final repo = AuthRepositoryImpl(_Rejected(), storage);
      expect(await repo.getCurrentUser(), isNull);
      expect(storage.token, isNull);
      expect(storage.userJson, isNull);
    });
  });
}

class _MemoryStorage extends SecureStorageService {
  String? token;
  String? userJson;
  _MemoryStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<void> deleteToken() async => token = null;
  @override
  Future<String?> getUserJson() async => userJson;
  @override
  Future<void> saveUserJson(String json) async => userJson = json;
  @override
  Future<void> deleteUserJson() async => userJson = null;
}

class _Unreachable extends Fake implements AuthRemoteDataSource {
  @override
  Future<UserEntity> getMe() => throw const ServerUnreachableException();
}

class _Rejected extends Fake implements AuthRemoteDataSource {
  @override
  Future<UserEntity> getMe() => throw Exception('Unauthorized');
}

class _NoSignal extends NetworkConnectivityService {
  @override
  Future<bool> checkHasConnection() async => false;
}
