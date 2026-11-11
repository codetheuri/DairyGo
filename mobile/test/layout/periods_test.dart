// Phase 5 of the books: months and years (closing, reopening, the year
// end) and reconciling a bank statement with the cashbook. Each screen on
// the smallest phone at the largest text and on a normal phone; nothing
// scrolls sideways; closing sends what the API expects. Fixtures were
// captured from the local API after the phase 5 scenario (backend
// docs/books.md).
//
//   flutter test test/layout/periods_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _sizes = [(Size(320, 640), 2.0), (Size(412, 915), 1.0)];
const _bank = 'bcb1c9e2-c6a9-48b4-96b4-f0844a4c243d';

const _accountant = [
  'books.read', 'books.manage', 'finance.read', 'finance.expenses.manage', //
  'finance.accounts.manage', 'payouts.read', 'payouts.runs.manage',
  'payouts.runs.pay', 'payouts.advances.manage', 'payouts.charges.manage',
  'payouts.shares.manage', 'customers.read', 'customers.statement.read',
  'customers.payments.manage', 'reports.payout.read', 'members.read',
  'milk.prices.read', 'sacco.settings.read',
];

Map<String, dynamic> _fixture(String name) =>
    (jsonDecode(
              File('test/layout/fixtures/admin/$name.json').readAsStringSync(),
            )
            as Map<String, dynamic>)['body']
        as Map<String, dynamic>;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
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

Future<void> _scrollTo(
  WidgetTester tester,
  Finder f, {
  Finder? inside,
  bool up = false,
}) async {
  final list = find.descendant(
    of: inside ?? find.byType(ListView).last,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(f, up ? -150 : 150, scrollable: list.first);
  await _settle(tester);
}

void _screen(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<AppUnderTest> _open(
  WidgetTester tester,
  String route, {
  Map<String, Object> replaced = const {},
  List<String> permissions = _accountant,
}) => AppUnderTest.open(
  tester,
  'admin',
  route,
  user: userFor(
    'admin',
  ).copyWith(roleName: 'Accountant', roleId: 4, permissions: permissions),
  replaced: replaced,
);

void main() {
  setUpAll(loadFonts);

  for (final (size, scale) in _sizes) {
    final name = '${size.width.toInt()}dp @${scale}x';

    testWidgets('months and years $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/books/periods');
      try {
        await _settle(tester);
        expect(
          find.text('Closed through 30 Sep 2026'),
          findsWidgets,
          reason: 'the status, and the history',
        );
        expect(find.text('Close October 2026'), findsOneWidget);
        expect(find.text('Reopen'), findsOneWidget);
        expect(find.text('FINANCIAL YEARS'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _scrollTo(tester, find.text('HISTORY'));
        expect(find.text('Closed through 30 Sep 2026'), findsWidgets);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _scrollTo(tester, find.text('Close October 2026'), up: true);

        app.server.writes['POST sacco_books_periods_close'] = _fixture(
          'sacco_books_periods',
        );
        await _tap(tester, find.text('Close October 2026'));
        expect(
          find.text('Close the books through October 2026?'),
          findsOneWidget,
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.widgetWithText(FilledButton, 'Close'));
        expect(app.server.sentBodies['POST sacco_books_periods_close'], {
          'through': '2026-10-31',
        });

        await _tap(tester, find.text('Reopen'));
        expect(find.text('Reopen months'), findsOneWidget);
        await _tap(tester, find.widgetWithText(FilledButton, 'Reopen'));
        expect(find.text('Give the reason.'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('reconciling the bank $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/finance/accounts/$_bank');
      try {
        await _settle(tester);
        await _tap(tester, find.byTooltip('Month before'));
        expect(
          find.byIcon(Icons.check_circle_rounded),
          findsWidgets,
          reason: 'October\'s matched lines are ticked in the cashbook',
        );
        await _tap(tester, find.byTooltip('Reconcile with the bank'));
        expect(find.text('Reconcile with the bank'), findsOneWidget);
        expect(find.textContaining('4 of 5 matched'), findsOneWidget);
        expect(find.text('Import statement'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.textContaining('4 of 5 matched'));
        expect(find.text('In the bank only'), findsOneWidget);
        await _scrollTo(tester, find.text('Cash deposit'));
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.text('Cash deposit'));
        expect(
          find.textContaining('Nothing in the cashbook has this amount'),
          findsOneWidget,
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });
  }
}
