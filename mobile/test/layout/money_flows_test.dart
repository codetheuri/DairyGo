// Phase 4 of the books: other income, suppliers and bills, paying over
// money taken for a supplier, opening balances, a farmer's shares and where
// a deduction's money goes. Each screen on the smallest phone at the largest
// text and on a normal phone; nothing scrolls sideways; the forms send what
// the API expects. Fixtures were captured from the local API after the
// phase 4 scenario (backend docs/books.md).
//
//   flutter test test/layout/money_flows_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _sizes = [(Size(320, 640), 2.0), (Size(412, 915), 1.0)];
const _cic = 'f275d3c7-5fd1-4e4b-a6e3-e45c70a86eb8';
const _agro = 'c540585e-5e80-424f-9dcc-cdba6517bfd2';
const _jane = '5464a4f0-f0c3-403a-aa75-63035e289335';

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

Future<void> _scrollTo(WidgetTester tester, Finder f, {Finder? inside}) async {
  final list = find.descendant(
    of: inside ?? find.byType(ListView).last,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(f, 150, scrollable: list.first);
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

    testWidgets('other income on the money screen $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/finance');
      try {
        await _settle(tester);
        expect(find.text('Expense'), findsOneWidget, reason: 'the FAB');
        await _tap(tester, find.text('Other income'));
        expect(find.text('Equity Bank'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget, reason: 'the FAB follows');
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.text('Income'));
        expect(find.text('Record other income'), findsOneWidget);
        expect(find.text('Received into'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('suppliers, a bill and paying over $name', (tester) async {
      _screen(tester, size, scale);
      final list = _fixture('sacco_suppliers');
      // CIC with money waiting, so Pay over shows.
      final cic = _fixture('sacco_suppliers_$_cic');
      (cic['data']['supplier'] as Map<String, dynamic>)['held'] = 300;
      final app = await _open(
        tester,
        '/finance/suppliers',
        replaced: {'sacco_suppliers': list, 'sacco_suppliers_$_cic': cic},
      );
      try {
        await _settle(tester);
        expect(find.text('Bills to pay'), findsOneWidget);
        expect(find.text('CIC Insurance'), findsOneWidget);
        expect(find.text('Kiambu Agrovet'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.text('CIC Insurance'));
        expect(find.text('Insurance'), findsWidgets);
        expect(find.text('Pay over'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.text('Pay over'));
        expect(find.text('Pay over to CIC Insurance'), findsOneWidget);
        expect(find.text('Paid from'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await app.close();

        final agro = await _open(tester, '/finance/suppliers/$_agro');
        await _settle(tester);
        await _scrollTo(tester, find.textContaining('INV-77'));
        expect(find.textContaining('Repairs and maintenance'), findsOneWidget);
        expect(find.textContaining('paid'), findsWidgets);
        await _tap(tester, find.text('Record a bill'));
        expect(find.text('What it is for'), findsOneWidget);
        expect(
          find.text('Supplier'),
          findsNothing,
          reason: 'recorded from the supplier: no need to choose one',
        );
        expect(agro.errors, isEmpty, reason: agro.errors.join('\n'));
        await agro.close();
      } finally {
        await app.close();
      }
    });

    testWidgets('opening balances $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/books/opening');
      try {
        await _settle(tester);
        expect(find.text('ADDED BY YOU'), findsOneWidget);
        expect(find.text('1500  Fixed assets'), findsWidgets);
        expect(find.text('250,000.00 Dr'), findsWidgets);
        await _scrollTo(tester, find.text('3900  Opening balances'));
        expect(find.text('250,000.00 Cr'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.text('Balance'));
        expect(find.text('Add an opening balance'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('a farmer\'s shares $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/members/$_jane/account');
      try {
        await _settle(tester);
        await _scrollTo(tester, find.text('Pass on'));
        expect(find.textContaining('in shares'), findsOneWidget);
        expect(find.text('Refund'), findsOneWidget);
        expect(find.text('Opening shares'), findsWidgets);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.text('Refund'));
        expect(find.text('Refund shares'), findsOneWidget);
        expect(find.text('Paid from'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('no share actions without the permission $name', (
      tester,
    ) async {
      _screen(tester, size, scale);
      final app = await _open(
        tester,
        '/members/$_jane/account',
        permissions: [
          for (final p in _accountant)
            if (p != 'payouts.shares.manage') p,
        ],
      );
      try {
        await _settle(tester);
        await _scrollTo(tester, find.textContaining('in shares'));
        expect(find.text('Refund'), findsNothing);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });
  }

  testWidgets('a deduction paid over to a supplier', (tester) async {
    _screen(tester, const Size(320, 640), 2.0);
    final app = await _open(
      tester,
      '/payouts/deductions',
      permissions: [..._accountant, 'payouts.deductions.manage'],
    );
    try {
      await _settle(tester);
      expect(find.textContaining('savings (shares)'), findsOneWidget);
      await _tap(tester, find.text('Shares'));
      await _scrollTo(
        tester,
        find.text('Paid over to someone'),
        inside: find.byType(BottomSheet),
      );
      await _tap(tester, find.text('Paid over to someone'));
      await _scrollTo(
        tester,
        find.text('Paid over to'),
        inside: find.byType(BottomSheet),
      );
      expect(find.byTooltip('Add a supplier'), findsOneWidget);
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));

      await _scrollTo(
        tester,
        find.text('Save'),
        inside: find.byType(BottomSheet),
      );
      await _tap(tester, find.text('Save'));
      expect(
        find.text('Choose who the money is paid over to.'),
        findsOneWidget,
        reason: 'a payee is needed',
      );
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    } finally {
      await app.close();
    }
  });
}
