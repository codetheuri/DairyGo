// Shared set-up for the layout tests: runs the real app, signed in as a role,
// with API responses served from test/layout/fixtures.

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/core/cache/response_cache.dart';
import 'package:dairy_sacco_mobile/core/network/cache_interceptor.dart';
import 'package:dairy_sacco_mobile/core/network/connection_monitor.dart';
import 'package:dairy_sacco_mobile/core/network/dio_client.dart';
import 'package:dairy_sacco_mobile/core/network/network_connectivity_service.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/auth_state.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_app_update.dart';

const commonRoutes = [
  '/dashboard',
  '/collections',
  '/field-operations',
  '/members',
  '/customers',
  '/more',
  '/settings',
  '/collections/record',
  '/field-sales/record',
  '/spoilage/record',
  '/members/register',
];

/// Main screens per role. 'admin-noprice' is a Sacco whose admin has not set
/// a milk price yet.
const routesByRole = {
  'collector': [...commonRoutes, '/transfers/record'],
  'admin': [
    ...commonRoutes,
    '/transfers/record',
    '/reports',
    '/settings/staff',
  ],
  'board': [...commonRoutes, '/reports'],
  'admin-noprice': ['/settings', '/collections/record'],
};

/// Serves the captured responses for one role. Any other request gets a 404,
/// which the screens must also lay out correctly.
class FixtureAdapter implements HttpClientAdapter {
  final String role;

  /// Holds every answer this long, to show loading states.
  final Duration delay;
  FixtureAdapter(this.role, {this.delay = Duration.zero});

  /// Answers that replace a fixture, by fixture name (for example
  /// 'sacco_milk-sales'), to play data changed on the server.
  final Map<String, Object> replaced = {};

  /// Answers to saves, by method and fixture name (for example
  /// 'PUT auth_users_29_role'). Any other save gets a 404.
  final Map<String, Object> writes = {};

  /// Names of the fixtures asked for, in order.
  final List<String> requests = [];

  /// Saves sent, in order, as 'METHOD name'.
  final List<String> sent = [];

  /// The body of the last save sent, by 'METHOD name'.
  final Map<String, Object?> sentBodies = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final name = options.path
        .replaceFirst(RegExp(r'^/api/v1/'), '')
        .replaceAll('/', '_');
    requests.add(name);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (options.path == '/health') {
      return ResponseBody.fromString('{"status":"ok"}', 200);
    }
    final file = File('test/layout/fixtures/$role/$name.json');
    var status = 404;
    Object body = {'success': false, 'message': 'not found'};
    if (options.method != 'GET') {
      sent.add('${options.method} $name');
      sentBodies['${options.method} $name'] = options.data;
    }
    if (writes.containsKey('${options.method} $name')) {
      status = 200;
      body = writes['${options.method} $name']!;
    } else if (options.method == 'GET' && replaced.containsKey(name)) {
      status = 200;
      body = replaced[name]!;
    } else if (options.method == 'GET' && file.existsSync()) {
      final fixture =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      status = fixture['status'] as int;
      body = fixture['body'] as Object;
      // Later pages: repeat the rows once, then report the end of the list.
      final page = int.tryParse('${options.queryParameters['page'] ?? 1}') ?? 1;
      final data = body is Map ? body['data'] : null;
      if (page > 1 && data is Map && data['meta'] is Map) {
        (data['meta'] as Map)['has_next'] = false;
      }
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

class _SignedIn extends AuthController {
  final UserEntity user;
  _SignedIn(this.user);

  @override
  Future<AuthState> build() async =>
      AuthState.authenticated(user: user, token: 'test');
}

class _Online extends NetworkConnectivityService {
  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);

  @override
  Future<bool> checkHasConnection() async => true;
}

UserEntity userFor(String role) {
  final fixture = jsonDecode(
    File('test/layout/fixtures/$role/auth_me.json').readAsStringSync(),
  );
  return UserEntity.fromJson(
    fixture['body']['data']['user'] as Map<String, dynamic>,
  );
}

/// Loads the app's bundled fonts and the Material icons, so screenshots show
/// real text and text is measured as on a phone.
Future<void> loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
    }
    await loader.load();
  }

  await load('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/Inter-$w.ttf',
  ]);
  await load('Outfit', [
    'assets/fonts/Outfit-SemiBold.ttf',
    'assets/fonts/Outfit-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// An open app for one role on one route. Collects layout errors raised after
/// navigating. Call [close] when done.
class AppUnderTest {
  final WidgetTester tester;
  final ProviderContainer container;
  final FixtureAdapter server;
  final List<String> errors = [];
  final FlutterExceptionHandler? _previousHandler;

  AppUnderTest._(
    this.tester,
    this.container,
    this.server,
    this._previousHandler,
  );

  /// [responseDelay] holds every API answer, to show loading states;
  /// [settle] waits for the screen to finish loading; with [cache], reads go
  /// through the saved-copy interceptors as in the app; [updates] plays the
  /// update server (nothing published by default); [permissions] replaces
  /// what the role may do, as an operator would in the console; [extra]
  /// overrides any other provider.
  static Future<AppUnderTest> open(
    WidgetTester tester,
    String role,
    String route, {
    Duration responseDelay = Duration.zero,
    bool settle = true,
    ResponseCache? cache,
    FakeAppUpdateService? updates,
    List<String>? permissions,
    List<Override> extra = const [],
  }) async {
    final server = FixtureAdapter(role, delay: responseDelay);
    final dio = Dio(BaseOptions(baseUrl: 'http://fixtures'))
      ..httpClientAdapter = server;
    if (cache != null) {
      dio.interceptors
        ..add(CacheFirstInterceptor(dio, cache))
        ..add(CacheStoreInterceptor(cache));
    }
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _SignedIn(
            permissions == null
                ? userFor(role)
                : userFor(role).copyWith(permissions: permissions),
          ),
        ),
        dioClientProvider.overrideWithValue(dio),
        authDioProvider.overrideWithValue(dio),
        networkConnectivityServiceProvider.overrideWithValue(_Online()),
        if (cache != null) responseCacheProvider.overrideWithValue(cache),
        // Never the real update server or installer.
        ...fakeUpdateOverrides(updates),
        ...extra,
      ],
    );
    final app = AppUnderTest._(tester, container, server, FlutterError.onError);
    FlutterError.onError = (details) {
      // The error's first line plus the widget's source location.
      final where =
          RegExp(
            r'file:///\S*/lib/(\S+\.dart:\d+)',
          ).firstMatch(details.toString())?.group(1) ??
          '?';
      app.errors.add(
        '${details.exceptionAsString().split('\n').first}  [$where]',
      );
    };

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DairySaccoApp(),
      ),
    );
    await tester.pump();
    container.read(appRouterProvider).go(route);
    // Health checks go to the fixtures too, never to the network.
    container.read(connectionMonitorProvider.notifier).probeClient = dio;
    await tester.pump();
    app.errors.clear(); // ignore the start-up screen shown before navigating
    // Let requests, debounces and the first frames of the screen finish.
    for (var i = 0; i < (settle ? 8 : 2); i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    return app;
  }

  Future<void> close() async {
    FlutterError.onError = _previousHandler;
    await tester.pumpWidget(const SizedBox.shrink());
    // Flush timers: snack bars, delayed answers, background tab loading.
    await tester.pump(const Duration(seconds: 10));
    container.dispose();
  }
}
