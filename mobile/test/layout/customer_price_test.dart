// A customer's price from a date: the Price card and its history, the
// change sheet (check first; asked whether to reprice sales paid in full),
// and voided payments kept on the statement with a Void payment button for
// the others. On the smallest phone at the largest text and on a normal
// phone; nothing scrolls sideways.
//
//   flutter test test/layout/customer_price_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _id = 'c0570e00-0001-4c00-8a00-000000000001';

Map<String, Object> _ok(Map<String, Object?> data) => {
  'success': true,
  'message': 'ok',
  'data': data,
};

final _customer = {
  'id': _id,
  'sacco_id': 'demo',
  'name': 'Ann Hotel',
  'customer_type': 'HOTEL',
  'default_price_per_litre': 70,
  'status': 'ACTIVE',
  'created_at': '2026-09-01T08:00:00+03:00',
  'updated_at': '2026-09-01T08:00:00+03:00',
  'balance': 5370,
  'month_litres': 80,
};

Map<String, Object?> _line(
  String kind,
  String id,
  double debit,
  double credit, {
  bool voided = false,
}) => {
  'kind': kind,
  'reference_id': id,
  'date': '2026-10-05',
  'description': kind == 'SALE'
      ? 'Milk sale 10.00 L @ 70.00'
      : 'Payment (MPESA) ref QX1',
  'litres': kind == 'SALE' ? 10 : 0,
  'debit': debit,
  'credit': credit,
  'balance': 700,
  'recorded_by': 'Alice Wanjiru',
  'recorded_at': '2026-10-05T10:42:00+03:00',
  if (voided) ...{
    'voided': true,
    'void_reason': 'Wrong customer',
    'voided_by': 'Alice Wanjiru',
    'voided_at': '2026-10-05T11:00:00+03:00',
  },
};

final _answers = <String, Object>{
  'sacco_customers_$_id': _ok({'customer': _customer}),
  'sacco_customers_${_id}_prices': _ok({
    'price_today': 70,
    'first_day': '2026-09-01',
    'schedule': [
      {
        'id': 'p2',
        'price_per_litre': 70,
        'effective_date': '2026-10-01',
        'reason': 'New contract',
        'created_by': 'Mary Admin',
        'is_active': true,
      },
      {
        'id': 'p1',
        'price_per_litre': 62,
        'effective_date': '2026-09-01',
        'reason': 'Agreed price before the price history',
        'is_active': true,
      },
    ],
    'cancelled': [
      {
        'id': 'p0',
        'price_per_litre': 90,
        'effective_date': '2026-10-03',
        'void_reason': 'Typed wrong',
        'is_active': false,
      },
    ],
  }),
  'sacco_customers_${_id}_statement': _ok({
    'statement': {
      'customer': _customer,
      'from_date': '2026-10-01',
      'to_date': '2026-10-31',
      'opening_balance': 0,
      'total_debit': 700,
      'total_credit': 0,
      'total_litres': 10,
      'closing_balance': 700,
      'lines': [
        _line('SALE', 's1', 700, 0),
        _line('PAYMENT', 'pay1', 0, 300, voided: true),
        _line('PAYMENT', 'pay2', 0, 100),
      ],
    },
  }),
};

List<String> _adminPermissions() => [
  ...((jsonDecode(
                File(
                  'test/layout/fixtures/admin/auth_me.json',
                ).readAsStringSync(),
              )
              as Map)['body']['data']['user']['permissions']
          as List)
      .cast<String>(),
  'customers.prices.manage',
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
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

    testWidgets('change a customer price from a date $name', (tester) async {
      phone(tester);
      final app = await AppUnderTest.open(
        tester,
        'admin',
        '/customers/$_id',
        replaced: _answers,
        permissions: _adminPermissions(),
      );
      app.server.writes['POST sacco_customers_${_id}_prices'] = _ok({
        'summary': {
          'credit_sales': 3,
          'credit_change': 150,
          'paid_sales': 1,
          'paid_change': 50,
          'handtyped_sales': 1,
        },
        'repriced': 3,
        'preview': true,
      });
      final seen = <String, Object>{};
      try {
        await _settle(tester);
        final change = find.text('Change price');
        await tester.ensureVisible(change);
        await _settle(tester);
        seen['history'] = find
            .textContaining('From 1 Oct 2026')
            .evaluate()
            .length;
        seen['cancelled shown'] = find
            .textContaining('cancelled: Typed wrong')
            .evaluate()
            .length;
        await tester.tap(change);
        await _settle(tester);
        await tester.enterText(find.byType(TextField).at(0), '75');
        await tester.enterText(find.byType(TextField).at(1), 'New contract');
        await tester.ensureVisible(find.text('Check'));
        await tester.tap(find.text('Check'));
        await _settle(tester);
        seen['says what changes'] = find
            .textContaining('3 sales not fully paid')
            .evaluate()
            .length;
        seen['asks about paid sales'] = find
            .textContaining('paid in full at the old price')
            .evaluate()
            .length;
        await tester.ensureVisible(find.text('Yes, reprice them'));
        await tester.tap(find.text('Yes, reprice them'));
        await _settle(tester);
        await tester.ensureVisible(find.text('Save price'));
        await tester.tap(find.text('Save price'));
        await _settle(tester);
        final body =
            app.server.sentBodies['POST sacco_customers_${_id}_prices'] as Map;
        seen['sent'] =
            '${body['price_per_litre']} ${body['include_paid']} ${body['preview']}';
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen, {
        'history': 1,
        'cancelled shown': 1,
        'says what changes': 1,
        'asks about paid sales': 1,
        'sent': '75.0 true null',
      });
    });

    testWidgets('voided payment stays; others can be voided $name', (
      tester,
    ) async {
      phone(tester);
      final app = await AppUnderTest.open(
        tester,
        'admin',
        '/customers/$_id',
        replaced: _answers,
        permissions: _adminPermissions(),
      );
      final seen = <String, int>{};
      try {
        await _settle(tester);
        final voided = find.text('Voided');
        await tester.scrollUntilVisible(
          voided,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        seen['crossed out'] = voided.evaluate().length;
        seen['why'] = find
            .textContaining('Voided by Alice Wanjiru: Wrong customer')
            .evaluate()
            .length;
        final other = find.text('Payment (MPESA) ref QX1').last;
        await tester.ensureVisible(other);
        await _settle(tester);
        await tester.tap(other);
        await _settle(tester);
        seen['void button'] = find.text('Void payment').evaluate().length;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen, {'crossed out': 1, 'why': 1, 'void button': 1});
    });
  }
}
