// Farmer pay and the Sacco's money: every screen lays out on the smallest
// phone at the largest text and on a large phone, nothing scrolls sideways,
// and each role sees only the actions its permissions allow.
//
//   flutter test test/layout/payouts_finance_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

// Ids in the captured fixtures (test/layout/fixtures/*/sacco_pay-runs_*.json).
const _paid = '4d999699-d674-4b4b-ba4c-541cc1fd8ba4';
const _draft = '93bf76b2-2118-41b8-9eef-5e46d7b6175a';
const _jane = '5464a4f0-f0c3-403a-aa75-63035e289335';
const _peter = 'd7646d16-7be9-4fdc-bea9-70b030bef818';
const _pettyCash = 'c493a85e-1786-4f56-9f1b-ea9910f864f1';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _screen(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

bool _shown(String text) => find.textContaining(text).evaluate().isNotEmpty;

/// Rows that scroll sideways. Swiping between tab pages (a PageView) and
/// the text inside a one-line field are not rows.
List<String> _sideways() => [
  for (final e
      in find
          .byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                w.axisDirection == AxisDirection.right &&
                w.physics?.toString().contains('PageScrollPhysics') != true &&
                w.restorationId != 'editable', // a text field's own text
          )
          .evaluate())
    'a row scrolls sideways: ${e.widget}',
];

void main() {
  setUpAll(loadFonts);

  const pages = [
    ('/payouts', 'Farmer Pay'),
    ('/payouts/runs/$_draft', 'Gross pay'),
    ('/payouts/runs/$_paid', 'Net pay'),
    ('/payouts/deductions', 'Registration fee'),
    ('/members/$_jane/account', 'Shares'),
    ('/members/$_peter/account', 'Owes the Sacco'),
    ('/finance', 'Expenses & Money'),
    ('/finance/accounts/$_pettyCash', 'Money in'),
  ];

  for (final size in const [Size(320, 640), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      for (final role in const ['admin', 'board']) {
        for (final (path, expected) in pages) {
          testWidgets('$role $path ${size.width.toInt()}dp @${scale}x', (
            tester,
          ) async {
            _screen(tester, size, scale);
            final app = await AppUnderTest.open(tester, role, path);
            final problems = <String>[];
            try {
              await _settle(tester);
              if (!_shown(expected)) problems.add('"$expected" is not shown');
              problems.addAll(_sideways());
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

  // Actions follow permissions, never role names.
  Future<Set<String>> actions(
    WidgetTester tester,
    String role,
    String path,
    List<String> labels,
  ) async {
    _screen(tester, const Size(412, 915), 1);
    final app = await AppUnderTest.open(tester, role, path);
    try {
      await _settle(tester);
      return {
        for (final l in labels)
          if (_shown(l)) l,
      };
    } finally {
      await app.close();
    }
  }

  testWidgets('draft pay run: admin prepares and approves, board approves', (
    tester,
  ) async {
    const labels = ['Approve', 'Work out again', 'Discard'];
    expect(
      await actions(tester, 'admin', '/payouts/runs/$_draft', labels),
      labels.toSet(),
    );
    expect(await actions(tester, 'board', '/payouts/runs/$_draft', labels), {
      'Approve',
    });
  });

  testWidgets('farmer account: only those allowed give advances and charges', (
    tester,
  ) async {
    const labels = ['Give advance', 'Add charge', 'Adjust'];
    expect(
      await actions(tester, 'admin', '/members/$_jane/account', labels),
      labels.toSet(),
    );
    expect(
      await actions(tester, 'board', '/members/$_jane/account', labels),
      isEmpty,
    );
  });

  testWidgets(
    'More shows farmer pay and money to admin and board, not collectors',
    (tester) async {
      const labels = ['Farmer pay', 'Expenses & money'];
      expect(await actions(tester, 'admin', '/more', labels), labels.toSet());
      expect(await actions(tester, 'board', '/more', labels), labels.toSet());
      expect(await actions(tester, 'collector', '/more', labels), isEmpty);
    },
  );

  testWidgets('a farmer opens their payslip from a paid run', (tester) async {
    _screen(tester, const Size(320, 640), 2);
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/payouts/runs/$_paid',
    );
    try {
      await _settle(tester);
      final jane = find.textContaining('Jane Muthoni');
      await tester.scrollUntilVisible(
        jane,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(jane);
      await _settle(tester);
      expect(find.text('Payslip'), findsOneWidget);
      expect(find.textContaining('Registration fee'), findsWidgets);
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
  });

  testWidgets('money tabs: accounts and income and spending', (tester) async {
    _screen(tester, const Size(320, 640), 2);
    final app = await AppUnderTest.open(tester, 'admin', '/finance');
    try {
      await _settle(tester);
      await tester.tap(find.text('Accounts'));
      await _settle(tester);
      expect(find.text('Petty cash'), findsOneWidget);
      await tester.tap(find.text('Income & spending'));
      await _settle(tester);
      expect(_shown('Milk sales'), isTrue);
      expect(_sideways(), isEmpty);
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
  });
}
