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

import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

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

/// Text that must be on screen, checked at the first size.
const _mustShow = {
  'admin-noprice /settings': 'Set Initial Buying Price',
  'admin-noprice /collections/record': 'No price set for today',
};

void main() {
  setUpAll(loadFonts);

  for (final role in routesByRole.keys) {
    for (final route in routesByRole[role]!) {
      testWidgets('$role $route lays out on every screen size', (tester) async {
        final problems = <String>[];

        for (final entry in _sizes.entries) {
          for (final scale in _textScales) {
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = entry.value * 2;
            tester.platformDispatcher.textScaleFactorTestValue = scale;

            final app = await AppUnderTest.open(tester, role, route);
            try {
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
              await app.close();
            }

            for (final e in app.errors.toSet()) {
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
