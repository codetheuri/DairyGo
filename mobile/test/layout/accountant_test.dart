// The accountant (role 4, books.manage, records no milk): their own layout,
// Home · Money · Pay · Books · More, with the money home and no milk
// entries; admins keep theirs. The money screen shows a month or a financial
// year. Money recorded names its account: the account for the way of paying
// is shown and left to the server unless another is picked. On the smallest
// phone at the largest text and on a normal phone; nothing scrolls sideways.
//
//   flutter test test/layout/accountant_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _jane = '5464a4f0-f0c3-403a-aa75-63035e289335';
const _sizes = [(Size(320, 640), 2.0), (Size(412, 915), 1.0)];

const _accountantPermissions = [
  'books.read', 'books.manage', 'finance.read', 'finance.expenses.manage', //
  'finance.accounts.manage', 'payouts.read', 'payouts.runs.manage',
  'payouts.runs.pay', 'payouts.advances.manage', 'payouts.charges.manage',
  'customers.read', 'customers.statement.read', 'customers.payments.manage',
  'reports.payout.read', 'reports.reconciliation.read', 'members.read',
  'milk.prices.read', 'sacco.settings.read',
];

final _choices = <String, Object>{
  'success': true,
  'data': {
    'accounts': [
      {'id': 'petty', 'name': 'Petty cash', 'kind': 'CASH'},
      {'id': 'paybill', 'name': 'M-Pesa paybill', 'kind': 'MPESA'},
      {'id': 'float', 'name': 'Collector float', 'kind': 'CASH'},
    ],
    'defaults': {'CASH': 'petty', 'MPESA': 'paybill'},
  },
};

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

void _screen(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<AppUnderTest> _openAccountant(WidgetTester tester, String route) =>
    AppUnderTest.open(
      tester,
      'admin',
      route,
      user: userFor('admin').copyWith(
        roleName: 'Accountant',
        roleId: 4,
        permissions: _accountantPermissions,
      ),
      replaced: {'sacco_cash-accounts_choices': _choices},
    );

Finder _inBar(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  setUpAll(loadFonts);

  for (final (size, scale) in _sizes) {
    final name = '${size.width.toInt()}dp @${scale}x';

    testWidgets('the accountant gets the money layout $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _openAccountant(tester, '/dashboard');
      try {
        await _settle(tester);
        for (final tab in ['Home', 'Money', 'Pay', 'More']) {
          expect(_inBar(tab), findsOneWidget, reason: '$tab in the bar');
        }
        for (final tab in ['Intake', 'Sales']) {
          expect(
            _inBar(tab),
            findsNothing,
            reason: 'no $tab for the accountant',
          );
        }
        expect(find.text('Cash in all accounts'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, _inBar('Money'));
        expect(find.text('Expenses & Money'), findsOneWidget);
        await _tap(tester, find.byTooltip('Month or financial year'));
        await _tap(tester, find.text('Financial year').last);
        expect(
          find.text('Financial year ${DateTime.now().year}'),
          findsOneWidget,
          reason: 'January by default: the calendar year',
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, _inBar('Pay'));
        expect(find.text('Farmer Pay'), findsOneWidget);

        await _tap(tester, _inBar('More'));
        expect(find.text('Farmer pay'), findsNothing, reason: 'already a tab');
        expect(find.text('Expenses & money'), findsNothing);
        expect(find.text('Farmers'), findsOneWidget, reason: 'on More');
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });
  }

  testWidgets('admins keep their layout', (tester) async {
    _screen(tester, const Size(412, 915), 1);
    final app = await AppUnderTest.open(tester, 'admin', '/dashboard');
    try {
      await _settle(tester);
      expect(_inBar('Intake'), findsOneWidget);
      expect(_inBar('Money'), findsNothing);
      await _tap(tester, _inBar('More'));
      expect(find.text('Farmer pay'), findsOneWidget);
      expect(find.text('Expenses & money'), findsOneWidget);
    } finally {
      await app.close();
    }
  });

  for (final (size, scale) in _sizes) {
    testWidgets(
      'an advance names its account ${size.width.toInt()}dp @${scale}x',
      (tester) async {
        _screen(tester, size, scale);
        final app = await _openAccountant(tester, '/members/$_jane/account');
        const post = 'POST sacco_members_${_jane}_advances';
        app.server.writes[post] = {
          'success': true,
          'data': {'entry': <String, Object>{}},
        };
        try {
          await _settle(tester);
          await _tap(tester, find.text('Give advance'));
          // M-Pesa by default: the M-Pesa account is shown.
          expect(find.text('M-Pesa paybill (M-Pesa)'), findsOneWidget);
          await _tap(tester, find.widgetWithText(ChoiceChip, 'Cash'));
          expect(
            find.text('Petty cash (Cash)'),
            findsOneWidget,
            reason: 'follows the way of paying',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Amount (KES)'),
            '500',
          );
          await _tap(tester, find.text('Save advance'));
          final body = app.server.sentBodies[post] as Map;
          expect(body['method'], 'CASH');
          expect(
            body.containsKey('cash_account_id'),
            isFalse,
            reason: 'the shown default is left to the server',
          );
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));

          // Picking another account sends it.
          await _tap(tester, find.text('Give advance'));
          await _tap(tester, find.widgetWithText(ChoiceChip, 'Cash'));
          await tester.enterText(
            find.widgetWithText(TextField, 'Amount (KES)'),
            '200',
          );
          await _tap(tester, find.text('Petty cash (Cash)'));
          await _tap(tester, find.text('Collector float (Cash)').last);
          await _tap(tester, find.text('Save advance'));
          expect(
            (app.server.sentBodies[post] as Map)['cash_account_id'],
            'float',
          );
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        } finally {
          await app.close();
        }
      },
    );
  }

  for (final (size, scale) in _sizes) {
    testWidgets(
      'the accountant sets the financial year ${size.width.toInt()}dp @${scale}x',
      (tester) async {
        _screen(tester, size, scale);
        Map<String, Object> year(int month, String from, String to) => {
          'success': true,
          'data': {
            'financial_year': {
              'start_month': month,
              'this_from': from,
              'this_to': to,
              'last_from': '2025-01-01',
              'last_to': '2025-12-31',
            },
          },
        };
        final app = await AppUnderTest.open(
          tester,
          'admin',
          '/settings',
          user: userFor('admin').copyWith(
            roleName: 'Accountant',
            roleId: 4,
            permissions: _accountantPermissions,
          ),
          replaced: {
            'sacco_financial-year': year(1, '2026-01-01', '2026-12-31'),
          },
        );
        app.server.writes['PUT sacco_financial-year'] = year(
          7,
          '2026-07-01',
          '2027-06-30',
        );
        try {
          await _settle(tester);
          expect(find.textContaining('Starts in January'), findsOneWidget);
          await _tap(tester, find.text('Financial year'));
          await _tap(tester, find.text('January').last);
          await _tap(tester, find.text('July').last);
          await _tap(tester, find.text('Save'));
          expect(app.server.sentBodies['PUT sacco_financial-year'], {
            'start_month': 7,
          });
          expect(
            find.text('The financial year now starts in July'),
            findsOneWidget,
          );
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        } finally {
          await app.close();
        }
      },
    );
  }
}
