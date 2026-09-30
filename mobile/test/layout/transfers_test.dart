// Milk transfers between collectors: the Transfers tab on the Sales screen,
// a transfer's details, and the "Transfer milk" form, for each role, on the
// smallest phone and a large one, at normal and the largest text.
//
//   flutter test test/layout/transfers_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshots)

import 'package:dairy_sacco_mobile/features/transfers/presentation/widgets/transfer_tile.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _setScreen(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUpAll(loadFonts);

  const sizes = [Size(320, 640), Size(412, 915)];
  const scales = [1.0, 2.0];

  for (final role in const ['collector', 'admin', 'board']) {
    for (final size in sizes) {
      for (final scale in scales) {
        final name = '$role ${size.width.toInt()}dp @${scale}x';

        testWidgets('Transfers tab and details: $name', (tester) async {
          _setScreen(tester, size, scale);
          final app = await AppUnderTest.open(
            tester,
            role,
            '/field-operations',
          );
          final seen = <String, int>{};
          try {
            await tester.tap(find.text('Transfers'));
            await _settle(tester);
            seen['tiles'] = find.byType(TransferTile).evaluate().length;
            seen['button'] = find
                .text('Transfer milk to a collector')
                .evaluate()
                .length;
            // The collector's own figures and direction.
            seen['given'] = find.text('To Grace Wambui').evaluate().length;
            seen['received'] = find
                .text('From Peter Mwangi Kariuki Njoroge')
                .evaluate()
                .length;

            if (_screenshots && size.width == 412 && scale == 1.0) {
              await expectLater(
                find.byType(DairySaccoApp),
                matchesGoldenFile('screenshots/transfers_tab_$role.png'),
              );
            }

            await tester.tap(find.byType(TransferTile).first);
            await _settle(tester);
            seen['sheet'] = find.text('History').evaluate().length;
            if (_screenshots && size.width == 412 && scale == 1.0) {
              await expectLater(
                find.byType(DairySaccoApp),
                matchesGoldenFile('screenshots/transfer_detail_$role.png'),
              );
            }
          } finally {
            await app.close();
          }
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
          expect(seen['tiles'], role == 'collector' ? 2 : 3);
          expect(seen['sheet'], 1);
          // Board members read transfers but do not make them.
          expect(seen['button'], role == 'board' ? 0 : 1);
          if (role == 'collector') {
            expect(seen['given'], 1);
            expect(seen['received'], 1);
          }
        });
      }
    }
  }

  for (final role in const ['collector', 'admin']) {
    for (final size in sizes) {
      for (final scale in scales) {
        testWidgets(
          'Transfer milk form: $role ${size.width.toInt()}dp @${scale}x',
          (tester) async {
            _setScreen(tester, size, scale);
            final app = await AppUnderTest.open(
              tester,
              role,
              '/transfers/record',
            );
            final seen = <String, int>{};
            try {
              seen['holding'] = find
                  .textContaining('not yet sold, transferred or spoiled')
                  .evaluate()
                  .length;
              seen['from'] = find.text('From').evaluate().length;

              await tester.tap(find.text('Grace Wambui'));
              await tester.pump();
              await tester.enterText(find.byType(TextFormField).first, '20');
              await tester.pump();
              seen['label'] = find
                  .text('Transfer 20 L to Grace Wambui')
                  .evaluate()
                  .length;

              await tester.ensureVisible(
                find.text('Transfer 20 L to Grace Wambui'),
              );
              await tester.pump();
              await tester.tap(find.text('Transfer 20 L to Grace Wambui'));
              await _settle(tester);
              seen['confirm'] = find
                  .text('Give 20 L to Grace Wambui?')
                  .evaluate()
                  .length;
              if (_screenshots && size.width == 412 && scale == 1.0) {
                await expectLater(
                  find.byType(DairySaccoApp),
                  matchesGoldenFile('screenshots/transfer_confirm_$role.png'),
                );
              }
            } finally {
              await app.close();
            }
            expect(app.errors, isEmpty, reason: app.errors.join('\n'));
            expect(seen['label'], 1);
            expect(seen['confirm'], 1);
            // Collectors see what they hold; admins choose whose milk it is.
            expect(seen['holding'], role == 'collector' ? 1 : 0);
            expect(seen['from'], role == 'admin' ? 1 : 0);
          },
        );
      }
    }
  }
}
