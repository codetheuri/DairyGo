// Android's navigation bar (back, home, recent) sits over the bottom of the
// screen. Nothing the app draws may go under it: not the bottom menu, not a
// sheet's button. The phone here has a 48dp bar, the 3-button kind.
//
//   flutter test test/layout/system_bars_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _bar = 48.0;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _phoneWithNavBar(WidgetTester tester, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(320, 640) * 2;
  tester.view.padding = const FakeViewPadding(bottom: _bar * 2);
  tester.view.viewPadding = const FakeViewPadding(bottom: _bar * 2);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUpAll(loadFonts);
  const limit = 640 - _bar;

  for (final scale in const [1.0, 2.0]) {
    testWidgets('bottom menu stays above the navigation bar @${scale}x', (
      tester,
    ) async {
      _phoneWithNavBar(tester, scale);
      final app = await AppUnderTest.open(tester, 'admin', '/more');
      double? bottom;
      try {
        await _settle(tester);
        bottom = tester.getRect(find.byType(NavigationBar)).bottom;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(bottom, lessThanOrEqualTo(limit));
    });

    testWidgets('a sheet\'s button stays above the navigation bar @${scale}x', (
      tester,
    ) async {
      _phoneWithNavBar(tester, scale);
      final app = await AppUnderTest.open(tester, 'admin', '/report-downloads');
      final seen = <String, double>{};
      try {
        await _settle(tester);
        await tester.tap(find.text('Farmer Payouts'));
        await _settle(tester);
        final sheet = find.byType(BottomSheet);
        seen['sheet'] = tester.getRect(sheet).bottom;
        final button = find
            .descendant(of: sheet, matching: find.byType(FilledButton))
            .last;
        await tester.ensureVisible(button);
        await tester.pump();
        seen['button'] = tester.getRect(button).bottom;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen['sheet'], lessThanOrEqualTo(limit));
      expect(seen['button'], lessThanOrEqualTo(limit));
    });
  }
}
