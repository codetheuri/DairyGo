// Tabs and filter chips are always fully on screen: none is cut off at the
// edge or reached only by scrolling sideways, on the smallest phone at the
// largest text and on a large phone.
//
//   flutter test test/layout/fits_width_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(loadFonts);

  // role, page, labels that must all be visible
  const pages = [
    ('admin', '/reports', ['Payouts', 'Ledger', 'Collectors']),
    ('admin', '/members', ['All', 'Active', 'Inactive', 'Suspended']),
    ('admin', '/collections', ['All Shifts', 'Morning', 'Evening']),
    ('admin', '/field-operations', ['Sales', 'Transfers', 'Spoilage']),
    ('board', '/dashboard', ['Collector Shift', 'Overview']),
  ];

  for (final size in const [Size(320, 640), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      for (final (role, path, labels) in pages) {
        testWidgets('$role $path: ${size.width.toInt()}dp @${scale}x', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = size * 2;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final app = await AppUnderTest.open(tester, role, path);
          final problems = <String>[];
          try {
            await _settle(tester);
            for (final label in labels) {
              final found = find.text(label);
              if (found.evaluate().isEmpty) {
                problems.add('"$label" is not shown');
                continue;
              }
              final box = tester.getRect(found.first);
              if (box.left < 0 || box.right > size.width) {
                problems.add('"$label" runs off the screen: $box');
              }
              final sideways = find.ancestor(
                of: found.first,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.right,
                ),
              );
              if (sideways.evaluate().isNotEmpty) {
                problems.add('"$label" is in a row that scrolls sideways');
              }
            }
          } finally {
            await app.close();
          }
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
          expect(problems, isEmpty, reason: problems.join('\n'));
        });
      }
    }
  }
}
