// The books (phase 2): the accountant's Books tab and every books screen,
// on the smallest phone at the largest text and on a normal phone; nothing
// scrolls sideways. Starting the books, bringing them up to date, a manual
// journal, reversing one, adding an account and changing where a record
// posts send what the API expects. Fixtures were captured from the local API
// after the books scenario (backend docs/books.md).
//
//   flutter test test/layout/books_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _sizes = [(Size(320, 640), 2.0), (Size(412, 915), 1.0)];
const _manual = '974fc46a-7007-4513-a684-4524b3c8542d';
const _opening = '73ee47df-5fac-4a7a-80d2-797f061f9c4c';
const _bank = '698cd204-1b85-490d-8c37-302935f76c97';

const _accountant = [
  'books.read', 'books.manage', 'finance.read', 'finance.expenses.manage', //
  'finance.accounts.manage', 'payouts.read', 'payouts.runs.manage',
  'payouts.runs.pay', 'payouts.advances.manage', 'payouts.charges.manage',
  'customers.read', 'customers.statement.read', 'customers.payments.manage',
  'reports.payout.read', 'reports.reconciliation.read', 'members.read',
  'milk.prices.read', 'sacco.settings.read',
];

Map<String, dynamic> _fixture(String name) =>
    (jsonDecode(
              File('test/layout/fixtures/admin/$name.json').readAsStringSync(),
            )
            as Map<String, dynamic>)['body']
        as Map<String, dynamic>;

Map<String, Object> _status(Map<String, Object?> books) => {
  'success': true,
  'data': {'books': books, 'journals_made': 0},
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

/// Scrolls the last list on screen (or the one in [inside]) until [f] is
/// built: lists build only the rows in view.
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
}) => AppUnderTest.open(
  tester,
  'admin',
  route,
  user: userFor(
    'admin',
  ).copyWith(roleName: 'Accountant', roleId: 4, permissions: _accountant),
  replaced: replaced,
);

Finder _inBar(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  setUpAll(loadFonts);

  for (final (size, scale) in _sizes) {
    final name = '${size.width.toInt()}dp @${scale}x';

    testWidgets('the accountant reads the books $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/dashboard');
      try {
        await _settle(tester);
        expect(_inBar('Books'), findsOneWidget);
        expect(
          _inBar('Buyers'),
          findsNothing,
          reason: 'customers moved to More',
        );
        expect(
          find.text('The books agree with the records'),
          findsOneWidget,
          reason: 'shown on the accountant\'s home',
        );

        await _tap(tester, _inBar('Books'));
        expect(find.text('The books agree with the records'), findsOneWidget);
        expect(
          find.textContaining('The books start on 15 Sep 2026'),
          findsOneWidget,
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));

        await _tap(tester, find.text('Trial balance'));
        expect(find.text('ASSETS'), findsOneWidget);
        await _scrollTo(tester, find.text('Debits equal credits'));
        expect(find.text('Debits equal credits'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.byTooltip('Back'));

        await _tap(tester, find.text('Journals'));
        await _scrollTo(tester, find.text('Cooler bought on a loan'));
        expect(find.textContaining('J-19'), findsOneWidget);
        await _tap(tester, find.text('Cooler bought on a loan'));
        expect(find.text('1500  Fixed assets'), findsOneWidget);
        expect(find.text('5,000.00 Dr'), findsOneWidget);
        expect(find.text('5,000.00 Cr'), findsOneWidget);
        expect(find.text('Reverse this journal'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.byTooltip('Back'));
        await _tap(tester, find.byTooltip('Back'));

        await _tap(tester, find.text('Chart of accounts'));
        expect(find.text('LIABILITIES'), findsOneWidget);
        expect(find.text('Follows customers\' balances'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.byTooltip('Back'));

        await _tap(tester, find.text('Where records post'));
        expect(find.text('CASH, BANK AND M-PESA ACCOUNTS'), findsOneWidget);
        expect(find.textContaining('→ 6100 Fuel'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await _tap(tester, find.byTooltip('Back'));

        await _tap(tester, _inBar('More'));
        expect(find.text('Customers'), findsOneWidget, reason: 'on More');
      } finally {
        await app.close();
      }
    });

    testWidgets('an opening journal and a bank ledger $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/books/journals/$_opening');
      try {
        await _settle(tester);
        expect(
          find.text('From: Opening balances', findRichText: true),
          findsNothing,
        );
        expect(find.textContaining('From: Opening balances'), findsOneWidget);
        expect(
          find.text('Reverse this journal'),
          findsNothing,
          reason: 'a record\'s journal follows the record',
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await app.close();

        final ledger = await _open(tester, '/books/accounts/$_bank');
        await _settle(tester);
        expect(find.text('1001 Equity Bank'), findsOneWidget);
        expect(find.text('Opening'), findsOneWidget);
        expect(ledger.errors, isEmpty, reason: ledger.errors.join('\n'));
        await ledger.close();
      } finally {
        await app.close();
      }
    });

    testWidgets('starting the books $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(
        tester,
        '/books',
        replaced: {
          'sacco_books': _status({'started': false, 'controls': []}),
        },
      );
      app.server.writes['POST sacco_books_start'] = _fixture('sacco_books');
      try {
        await _settle(tester);
        expect(find.text('The books have not started'), findsOneWidget);
        await _tap(tester, find.text('Start the books'));
        await _tap(tester, find.text('OK'));
        await _tap(tester, find.text('Start'));
        final now = DateTime.now();
        final first = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        expect(
          app.server.sentBodies['POST sacco_books_start'],
          {'start_date': first},
          reason: 'the 1st of this month by default',
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('books that differ are brought up to date $name', (
      tester,
    ) async {
      _screen(tester, size, scale);
      final app = await _open(
        tester,
        '/books',
        replaced: {
          'sacco_books': _status({
            'started': true,
            'start_date': '2026-10-01',
            'journals': 20,
            'balanced': true,
            'agrees': false,
            'controls': [
              {
                'name': 'Petty cash',
                'account_id': 'x',
                'code': '1002',
                'books': 3100,
                'records': 3700,
                'difference': -600,
                'ok': false,
              },
            ],
            'not_in_account': 50,
          }),
        },
      );
      app.server.writes['POST sacco_books_sync'] = {
        'success': true,
        'data': {..._fixture('sacco_books')['data'] as Map, 'journals_made': 1},
      };
      try {
        await _settle(tester);
        expect(find.text('The books differ from the records'), findsOneWidget);
        expect(
          find.textContaining('Petty cash: books 3,100.00'),
          findsOneWidget,
        );
        expect(find.text('KES 50 not in any account'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Bring up to date'),
        );
        expect(app.server.sent, contains('POST sacco_books_sync'));
        expect(find.text('1 journal posted'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('a manual journal $name', (tester) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/books/journals/new');
      app.server.writes['POST sacco_books_journals'] = _fixture(
        'sacco_books_journals_$_manual',
      );
      try {
        await _settle(tester);
        await tester.enterText(
          find.widgetWithText(TextField, 'What is it for?'),
          'Cooler bought on a loan',
        );
        Future<void> line(int i, String account, String amount) async {
          await _tap(
            tester,
            find
                .widgetWithText(DropdownButtonFormField<String>, 'Account')
                .at(i),
          );
          await _tap(tester, find.text(account).last);
          await tester.enterText(
            find.widgetWithText(TextField, 'Amount (KES)').at(i),
            amount,
          );
          await _settle(tester);
        }

        expect(find.text('1200  Customers'), findsNothing);
        await line(0, '1500  Fixed assets', '5000');
        await line(1, '2200  Loans', '4000');
        expect(find.text('Off by 1,000.00'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save journal'),
              )
              .onPressed,
          isNull,
          reason: 'not saved until it balances',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount (KES)').at(1),
          '5000',
        );
        await _settle(tester);
        expect(find.text('Balanced'), findsOneWidget);
        await _tap(tester, find.widgetWithText(FilledButton, 'Save journal'));
        final body = app.server.sentBodies['POST sacco_books_journals'] as Map;
        expect(body['memo'], 'Cooler bought on a loan');
        final lines = (body['lines'] as List).cast<Map>();
        expect(lines[0]['debit'], 5000);
        expect(lines[1]['credit'], 5000);
        expect(lines[0].containsKey('credit'), isFalse);
        expect(find.text('Journal J-19 saved'), findsOneWidget);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      } finally {
        await app.close();
      }
    });

    testWidgets('reversing, an account, where a record posts $name', (
      tester,
    ) async {
      _screen(tester, size, scale);
      final app = await _open(tester, '/books/journals/$_manual');
      app.server.writes['POST sacco_books_journals_${_manual}_reverse'] =
          _fixture('sacco_books_journals_$_manual');
      app.server.writes['POST sacco_books_accounts'] = {
        'success': true,
        'data': {'account': <String, Object>{}},
      };
      app.server.writes['PUT sacco_books_links'] = _fixture(
        'sacco_books_links',
      );
      try {
        await _settle(tester);
        await _tap(tester, find.text('Reverse this journal'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Reason'),
          'Entered twice',
        );
        await _tap(tester, find.widgetWithText(FilledButton, 'Reverse'));
        expect(
          app.server.sentBodies['POST sacco_books_journals_${_manual}_reverse'],
          {'reason': 'Entered twice'},
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        await app.close();

        final chart = await _open(tester, '/books/accounts');
        chart.server.writes['POST sacco_books_accounts'] = {
          'success': true,
          'data': {'account': <String, Object>{}},
        };
        await _settle(tester);
        await _tap(tester, find.text('Account'));
        await tester.enterText(find.widgetWithText(TextField, 'Code'), '6200');
        await tester.enterText(
          find.widgetWithText(TextField, 'Name'),
          'Cooler repairs',
        );
        await _tap(tester, find.text('Save'));
        expect(chart.server.sentBodies['POST sacco_books_accounts'], {
          'code': '6200',
          'name': 'Cooler repairs',
          'type': 'EXPENSE',
          'description': '',
        });
        expect(chart.errors, isEmpty, reason: chart.errors.join('\n'));
        await chart.close();

        final links = await _open(tester, '/books/links');
        links.server.writes['PUT sacco_books_links'] = _fixture(
          'sacco_books_links',
        );
        await _settle(tester);
        await _tap(tester, find.text('Rent'));
        expect(find.text('Rent posts to'), findsOneWidget);
        expect(
          find.text('4000  Milk sales'),
          findsNothing,
          reason: 'an expense cannot post to income',
        );
        expect(
          find.text('1200  Customers'),
          findsNothing,
          reason: 'kept from records',
        );
        await _scrollTo(
          tester,
          find.text('6100  Fuel'),
          inside: find.byType(BottomSheet),
        );
        await _tap(tester, find.text('6100  Fuel'));
        final sent = links.server.sentBodies['PUT sacco_books_links'] as Map;
        expect(sent['key'], startsWith('expense_category:'));
        expect(links.errors, isEmpty, reason: links.errors.join('\n'));
        await links.close();
      } finally {
        await app.close();
      }
    });
  }

  testWidgets('admins find the books on More; the board does not', (
    tester,
  ) async {
    _screen(tester, const Size(412, 915), 1);
    final app = await AppUnderTest.open(tester, 'admin', '/more');
    try {
      await _settle(tester);
      expect(find.text('Books'), findsOneWidget);
      await _tap(tester, find.text('Books'));
      expect(find.text('The books agree with the records'), findsOneWidget);
    } finally {
      await app.close();
    }
    final board = await AppUnderTest.open(tester, 'board', '/more');
    try {
      await _settle(tester);
      expect(find.text('Books'), findsNothing);
    } finally {
      await board.close();
    }
  });
}
