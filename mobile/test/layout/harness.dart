// Shared set-up for the layout tests: runs the real app, signed in as a role,
// with API responses served from test/layout/fixtures.

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
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
  'collector': commonRoutes,
  'admin': [...commonRoutes, '/reports', '/settings/staff'],
  'board': [...commonRoutes, '/reports'],
  'admin-noprice': ['/settings', '/collections/record'],
};

/// Serves the captured responses for one role. Any other request gets a 404,
/// which the screens must also lay out correctly.
class FixtureAdapter implements HttpClientAdapter {
  final String role;
  FixtureAdapter(this.role);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final name = options.path
        .replaceFirst(RegExp(r'^/api/v1/'), '')
        .replaceAll('/', '_');
    final file = File('test/layout/fixtures/$role/$name.json');
    var status = 404;
    Object body = {'success': false, 'message': 'not found'};
    if (options.method == 'GET' && file.existsSync()) {
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
  final List<String> errors = [];
  final FlutterExceptionHandler? _previousHandler;

  AppUnderTest._(this.tester, this.container, this._previousHandler);

  static Future<AppUnderTest> open(
    WidgetTester tester,
    String role,
    String route,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://fixtures'))
      ..httpClientAdapter = FixtureAdapter(role);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _SignedIn(userFor(role))),
        dioClientProvider.overrideWithValue(dio),
        authDioProvider.overrideWithValue(dio),
        networkConnectivityServiceProvider.overrideWithValue(_Online()),
      ],
    );
    final app = AppUnderTest._(tester, container, FlutterError.onError);
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
    await tester.pump();
    app.errors.clear(); // ignore the start-up screen shown before navigating
    // Let requests, debounces and the first frames of the screen finish.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    return app;
  }

  Future<void> close() async {
    FlutterError.onError = _previousHandler;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2)); // flush timers (snack bars)
    container.dispose();
  }
}
