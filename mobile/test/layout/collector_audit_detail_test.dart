// The collector audit detail (Reports → Collector Audit → a collector) is
// opened by tapping, not from a menu, so the other layout tests never reach
// it. Every day must balance as intake + received = sales + given + spoiled
// + unaccounted, with no "to station" figure: deliveries to coolers are sales.
//
//   flutter test test/layout/collector_audit_detail_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshot)

import 'package:dairy_sacco_mobile/core/widgets/balance_badge.dart';
import 'package:dairy_sacco_mobile/features/transfers/presentation/widgets/transfer_tile.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

void main() {
  setUpAll(loadFonts);

  for (final size in const [Size(320, 640), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('collector audit detail ${size.width.toInt()}dp @${scale}x', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = size * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final app = await AppUnderTest.open(tester, 'admin', '/reports');
        try {
          // The tab bar scrolls; bring the tab into view like a user would.
          await tester.ensureVisible(find.text('Collector Audit'));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Collector Audit'));
          // Tab animation, then the report loads.
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          await tester.tap(find.text('uxcol').first);
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }

          expect(find.text('To Station'), findsNothing);
          expect(find.textContaining('Handover'), findsNothing);
          expect(find.text('Intake'), findsWidgets);
          expect(find.text('Sales'), findsWidgets);
          expect(find.text('Spoiled'), findsWidgets);
          expect(find.byType(BalanceBadge), findsWidgets);
          // Transfers count in the period and show on their day, with names.
          expect(find.textContaining('Transfers: received'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byType(TransferTile).first,
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.byType(TransferTile), findsWidgets);

          if (_screenshots && size.width == 412 && scale == 1.0) {
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/collector_audit_detail.png'),
            );
          }
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      });
    }
  }
}
