// The phone's back button on a main section goes back inside the app (to
// More or Home) instead of closing it; only a second press on Home leaves.
//
//   flutter test test/layout/back_button_test.dart

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/app/shell/shell_back_handler.dart';
import 'package:dairy_sacco_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:dairy_sacco_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  // Long enough for a closing screen's animation to finish.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

String _location(AppUnderTest app) => app.container
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .path;

void main() {
  setUpAll(loadFonts);

  test('where back leads from a section', () {
    expect(backTargetFor(onHome: false, openedFromMore: true), BackTarget.more);
    expect(
      backTargetFor(onHome: false, openedFromMore: false),
      BackTarget.home,
    );
    expect(backTargetFor(onHome: true, openedFromMore: false), BackTarget.exit);
  });

  testWidgets('admin: Reports → More → Home → asks before closing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(412, 915) * 2;
    addTearDown(tester.view.reset);

    // Count the times the app asks Android to close it.
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final app = await AppUnderTest.open(tester, 'admin', '/reports');
    final seen = <String, Object>{};
    try {
      seen['start'] = find.byType(ReportsScreen).evaluate().length;
      await _back(tester);
      seen['after 1'] = _location(app);
      await _back(tester);
      seen['after 2'] = _location(app);

      await _back(tester);
      seen['asks'] = find
          .text('Press back again to close DairyGo')
          .evaluate()
          .length;
      seen['exits after first press'] = exits;
      // Too late: the message has gone, so it asks again.
      await tester.pump(const Duration(seconds: 3));
      await _back(tester);
      seen['exits after a late press'] = exits;
      await _back(tester);
      seen['exits after a quick second press'] = exits;

      // A screen opened on top closes first, and the app stays open.
      await tester.pump(const Duration(seconds: 3));
      app.container.read(appRouterProvider).push('/settings');
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      seen['settings open'] = find.byType(SettingsScreen).evaluate().length;
      await _back(tester);
      seen['settings closed'] = find.byType(SettingsScreen).evaluate().length;
      seen['still in app'] = _location(app);
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['start'], 1);
    expect(seen['after 1'], '/more'); // Reports is opened from More
    expect(seen['after 2'], '/dashboard');
    expect(seen['asks'], 1);
    expect(seen['exits after first press'], 0);
    expect(seen['exits after a late press'], 0);
    expect(seen['exits after a quick second press'], 1);
    expect(seen['settings open'], 1);
    expect(seen['settings closed'], 0);
    expect(seen['still in app'], '/dashboard');
  });

  testWidgets('board: Reports is on the bar, so back goes Home', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(320, 640) * 2;
    addTearDown(tester.view.reset);
    final app = await AppUnderTest.open(tester, 'board', '/reports');
    late String after;
    try {
      await _back(tester);
      after = _location(app);
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(after, '/dashboard');
  });

  testWidgets('collector: Intake goes Home', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(412, 915) * 2;
    addTearDown(tester.view.reset);
    final app = await AppUnderTest.open(tester, 'collector', '/collections');
    late String after;
    try {
      await _back(tester);
      after = _location(app);
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(after, '/dashboard');
  });
}
