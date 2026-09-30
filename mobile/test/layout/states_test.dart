// Loading and connection states, which the other layout tests do not see
// because their fixtures answer at once.
//
//   flutter test test/layout/states_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshots)

import 'package:dairy_sacco_mobile/core/network/connection_monitor.dart';
import 'package:dairy_sacco_mobile/core/widgets/skeleton.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

/// A small phone with the largest text: the hardest case for banners.
Future<void> _smallPhoneLargeText(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(320, 640) * 2;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_screenshots) return;
  await tester.pump(const Duration(seconds: 1)); // let transitions finish
  await expectLater(
    find.byType(DairySaccoApp),
    matchesGoldenFile('screenshots/state_$name.png'),
  );
}

void main() {
  setUpAll(loadFonts);

  for (final role in ['collector', 'admin', 'board']) {
    for (final route in routesByRole[role]!) {
      testWidgets('$role $route while loading', (tester) async {
        await _smallPhoneLargeText(tester);
        final app = await AppUnderTest.open(
          tester,
          role,
          route,
          responseDelay: const Duration(seconds: 5),
          settle: false,
        );
        try {
          if (route == '/dashboard' && role == 'collector') {
            expect(find.byType(DashboardSkeleton), findsWidgets);
            await _shot(tester, 'loading_dashboard');
          }
          if (route == '/members') {
            expect(find.byType(ListSkeleton), findsOneWidget);
            if (role == 'collector') await _shot(tester, 'loading_list');
          }
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      });
    }
  }

  testWidgets('connection banners fit a small phone with large text', (
    tester,
  ) async {
    await _smallPhoneLargeText(tester);
    for (final route in ['/dashboard', '/field-sales/record']) {
      final app = await AppUnderTest.open(tester, 'collector', route);
      try {
        final monitor = app.container.read(connectionMonitorProvider.notifier);

        for (var i = 0; i < 3; i++) {
          monitor.reportAnswered(const Duration(seconds: 6));
        }
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Slow connection'), findsOneWidget);
        await _shot(tester, 'slow${route.replaceAll('/', '_')}');

        // The server stops answering, health checks included.
        monitor
          ..probeClient = (Dio()..httpClientAdapter = _NoAnswer())
          ..reportNoAnswer()
          ..reportNoAnswer();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('No internet connection'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        await _shot(tester, 'offline${route.replaceAll('/', '_')}');

        monitor.reportAnswered(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Back online'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 400)); // fade out
        expect(find.text('Back online'), findsNothing);
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    }
  });
}

class _NoAnswer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) => throw DioException(
    requestOptions: o,
    type: DioExceptionType.connectionError,
  );

  @override
  void close({bool force = false}) {}
}
