// Layout check for every main screen, for each role, on the screen sizes and
// text sizes the app must support. It runs the real app with API responses
// captured from a test server (test/layout/fixtures) and fails on any layout
// error, such as a row or column that overflows.
//
//   flutter test test/layout
//
// To also save screenshots of each screen (phone with large text, and tablet
// landscape) to test/layout/screenshots/:
//
//   flutter test test/layout --update-goldens --dart-define=SCREENSHOTS=true

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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

/// Logical screen sizes, from a small phone to a tablet in landscape.
const _sizes = <String, Size>{
  'phone-small': Size(320, 640),
  'phone': Size(360, 800),
  'phone-large': Size(430, 932),
  'phone-landscape': Size(800, 360),
  'tablet': Size(800, 1280),
  'tablet-landscape': Size(1280, 800),
};

/// Normal text, and the largest font setting (the app caps it at 1.3x).
const _textScales = [1.0, 2.0];

const _commonRoutes = [
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

/// Text that must be on screen, checked at the first size. 'admin-noprice'
/// is a Sacco whose admin has not set a milk price yet.
const _mustShow = {
  'admin-noprice /settings': 'Set Initial Buying Price',
  'admin-noprice /collections/record': 'No price set for today',
};

const _routesByRole = {
  'collector': _commonRoutes,
  'admin': [..._commonRoutes, '/reports', '/settings/staff'],
  'board': [..._commonRoutes, '/reports'],
  'admin-noprice': ['/settings', '/collections/record'],
};

/// Serves the captured responses for one role. Any other request gets a 404,
/// which the screens must also lay out correctly.
class _FixtureAdapter implements HttpClientAdapter {
  final String role;
  _FixtureAdapter(this.role);

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

UserEntity _userFor(String role) {
  final fixture = jsonDecode(
    File('test/layout/fixtures/$role/auth_me.json').readAsStringSync(),
  );
  return UserEntity.fromJson(
    fixture['body']['data']['user'] as Map<String, dynamic>,
  );
}

Future<void> _loadFonts() async {
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

void main() {
  setUpAll(_loadFonts);

  for (final role in _routesByRole.keys) {
    for (final route in _routesByRole[role]!) {
      testWidgets('$role $route lays out on every screen size', (tester) async {
        final problems = <String>[];
        final user = _userFor(role);

        for (final entry in _sizes.entries) {
          for (final scale in _textScales) {
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = entry.value * 2;
            tester.platformDispatcher.textScaleFactorTestValue = scale;

            final dio = Dio(BaseOptions(baseUrl: 'http://fixtures'))
              ..httpClientAdapter = _FixtureAdapter(role);
            final container = ProviderContainer(
              overrides: [
                authControllerProvider.overrideWith(() => _SignedIn(user)),
                dioClientProvider.overrideWithValue(dio),
                authDioProvider.overrideWithValue(dio),
                networkConnectivityServiceProvider.overrideWithValue(_Online()),
              ],
            );

            final errors = <String>[];
            final previousHandler = FlutterError.onError;
            FlutterError.onError = (details) {
              // "overflowed by N pixels" plus the widget's source location.
              final text = details.toString();
              final where =
                  RegExp(
                    r'file:///\S*/lib/(\S+\.dart:\d+)',
                  ).firstMatch(text)?.group(1) ??
                  '?';
              errors.add(
                '${details.exceptionAsString().split('\n').first}  [$where]',
              );
            };
            try {
              await tester.pumpWidget(
                UncontrolledProviderScope(
                  container: container,
                  child: const DairySaccoApp(),
                ),
              );
              await tester.pump();
              container.read(appRouterProvider).go(route);
              await tester.pump();
              errors
                  .clear(); // ignore the start-up screen shown before navigating
              // Let requests, debounces and the first frames of each screen finish.
              for (var i = 0; i < 8; i++) {
                await tester.pump(const Duration(milliseconds: 250));
              }

              final mustShow = _mustShow['$role $route'];
              if (mustShow != null &&
                  entry.key == _sizes.keys.first &&
                  scale == _textScales.first) {
                await tester.scrollUntilVisible(
                  find.text(mustShow),
                  200,
                  scrollable: find.byType(Scrollable).first,
                );
                expect(
                  find.text(mustShow),
                  findsOneWidget,
                  reason: '$role $route should show "$mustShow"',
                );
              }

              if (_screenshots &&
                  scale == 2.0 &&
                  (entry.key == 'phone' || entry.key == 'tablet-landscape')) {
                final name =
                    '$role${route.replaceAll('/', '_')}_${entry.key}.png';
                await expectLater(
                  find.byType(DairySaccoApp),
                  matchesGoldenFile('screenshots/$name'),
                );
              }
            } finally {
              FlutterError.onError = previousHandler;
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump(
                const Duration(seconds: 2),
              ); // flush timers such as snack bars
              container.dispose();
            }

            for (final e in errors.toSet()) {
              problems.add('${entry.key} @${scale}x: $e');
            }
          }
        }

        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}
