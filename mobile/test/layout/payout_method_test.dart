// How each farmer is paid: M-Pesa or bank. Bank needs an account; the
// farmer list finds farmers by how they are paid or whose details are
// missing; the pay run's pay sheet is named as such. On the smallest phone
// at the largest text and on a normal phone; nothing scrolls sideways.
//
//   flutter test test/layout/payout_method_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

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

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
  matching: find.byType(TextFormField),
);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.pump();
  await tester.enterText(_field(label), text);
  await tester.pump();
}

/// The admin's farmer list with one farmer paid by bank without an account
/// and one on M-Pesa with no phone.
Map<String, Object> _farmers() {
  final body =
      jsonDecode(
            File(
              'test/layout/fixtures/admin/sacco_members.json',
            ).readAsStringSync(),
          )['body']
          as Map<String, dynamic>;
  final list = (body['data']['members'] as List).cast<Map<String, dynamic>>();
  body['data']['members'] = [
    {
      ...list[0],
      'first_name': 'Jane',
      'last_name': 'Muthoni',
      'payout_method': 'BANK',
      'bank_name': 'Equity',
      'bank_account_number': '',
    },
    {
      ...list[0],
      'id': 'm2',
      'first_name': 'Mutahi',
      'last_name': 'Macharia',
      'phone': '',
      'mpesa_number': null,
      'payout_method': 'MPESA',
    },
  ];
  return {'sacco_members': body};
}

void main() {
  setUpAll(loadFonts);

  for (final (size, scale) in const [
    (Size(320, 640), 2.0),
    (Size(412, 915), 1.0),
  ]) {
    final name = '${size.width.toInt()}dp @${scale}x';

    void phone(WidgetTester tester) {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = size * 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('register a farmer paid by bank $name', (tester) async {
      phone(tester);
      final app = await AppUnderTest.open(tester, 'admin', '/members/register');
      final seen = <String, Object>{};
      try {
        await _settle(tester);
        await _type(tester, 'First Name *', 'Jane');
        await _type(tester, 'Last Name *', 'Muthoni');
        await _type(tester, 'Phone Number *', '0707154545');
        seen['M-Pesa first'] = _field('M-Pesa Number').evaluate().length;
        await _tap(tester, find.text('Bank'));
        await _type(tester, 'Bank', 'Equity');
        await _tap(tester, find.text('Register Farmer Member'));
        seen['account needed'] = find
            .text('The account number is needed to pay by bank')
            .evaluate()
            .length;
        seen['nothing sent'] = app.server.sent.length;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen, {'M-Pesa first': 1, 'account needed': 1, 'nothing sent': 0});
    });

    testWidgets('find farmers whose details are missing $name', (tester) async {
      phone(tester);
      final app = await AppUnderTest.open(
        tester,
        'admin',
        '/members',
        replaced: _farmers(),
      );
      final seen = <String, int>{};
      try {
        await _settle(tester);
        await _tap(tester, find.text('Details missing'));
        seen['bank missing'] = find
            .text('Bank: account missing')
            .evaluate()
            .length;
        seen['mpesa missing'] = find
            .text('M-Pesa: number missing')
            .evaluate()
            .length;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      // The fixture answers every page the same, so a label can repeat.
      expect(seen['bank missing'], greaterThan(0));
      expect(seen['mpesa missing'], greaterThan(0));
    });
  }

  testWidgets('the pay run register is called the pay sheet', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(412, 915) * 2;
    addTearDown(tester.view.reset);
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/payouts/runs/4d999699-d674-4b4b-ba4c-541cc1fd8ba4',
    );
    final seen = <String, int>{};
    try {
      await _settle(tester);
      seen['pay sheet'] = find.text('Pay sheet').evaluate().length;
      seen['register'] = find.text('Register').evaluate().length;
    } finally {
      await app.close();
    }
    expect(seen, {'pay sheet': 1, 'register': 0});
  });
}
