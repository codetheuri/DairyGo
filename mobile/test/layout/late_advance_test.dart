// An advance forgotten on the day: the admin picks the date it was given, in
// the period not yet paid, and says why it is recorded late. Today needs no
// reason. On the smallest phone at the largest text; nothing scrolls sideways.
//
//   flutter test test/layout/late_advance_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _jane = '5464a4f0-f0c3-403a-aa75-63035e289335';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

Finder _input(String label) => find.widgetWithText(TextField, label);

void main() {
  final today = DateUtils.dateOnly(DateTime.now());

  for (final (size, scale) in const [
    (Size(320, 640), 2.0),
    (Size(412, 915), 1.0),
  ]) {
    testWidgets(
      'an advance on an earlier day needs a reason ${size.width.toInt()}dp @${scale}x',
      (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = size * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final app = await AppUnderTest.open(
          tester,
          'admin',
          '/members/$_jane/account',
        );
        const post = 'POST sacco_members_${_jane}_advances';
        app.server.writes[post] = {
          'success': true,
          'data': {'entry': <String, Object>{}},
        };
        await _tap(tester, find.text('Give advance'));
        expect(find.text('Date given'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Why it is recorded late'), findsNothing);

        // Today: no date or reason is sent.
        await tester.enterText(_input('Amount (KES)'), '500');
        await _tap(tester, find.text('Save advance'));
        expect(app.server.sentBodies[post], {
          'amount': 500.0,
          'method': 'MPESA',
        });
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        if (today.day == 1) {
          await app.close();
          return;
        } // no earlier day this month to pick
        await _tap(tester, find.text('Give advance'));
        await tester.enterText(_input('Amount (KES)'), '1500');
        await _tap(tester, find.text('Change'));
        await _tap(tester, find.text('1').last);
        await _tap(tester, find.text('OK'));
        expect(find.text('Why it is recorded late'), findsOneWidget);

        await _tap(tester, find.text('Save advance'));
        expect(
          find.text('Say why it is recorded after the day.'),
          findsOneWidget,
        );

        await tester.enterText(
          _input('Why it is recorded late'),
          'Forgot to record it on the day',
        );
        await _tap(tester, find.text('Save advance'));
        final first = DateTime(today.year, today.month, 1);
        expect(app.server.sentBodies[post], {
          'amount': 1500.0,
          'method': 'MPESA',
          'date': '${first.year}-${first.month.toString().padLeft(2, '0')}-01',
          'late_reason': 'Forgot to record it on the day',
        });
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await app.close();
      },
    );
  }
}
