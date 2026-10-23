// A customer's statement says who recorded each sale and payment: on the
// line, and in full when the line is tapped. On the smallest phone at the
// largest text, and nothing scrolls sideways.
//
//   flutter test test/layout/customer_statement_test.dart

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
  'name': 'Kiambu Cooler',
  'phone': '0733 000 001',
  'customer_type': 'COOLER',
  'default_price_per_litre': 62,
  'status': 'ACTIVE',
  'created_at': '2026-09-01T08:00:00+03:00',
  'updated_at': '2026-09-01T08:00:00+03:00',
  'balance': 1240,
};

final _answers = <String, Object>{
  'sacco_customers_$_id': _ok({'customer': _customer}),
  'sacco_customers_${_id}_statement': _ok({
    'statement': {
      'customer': _customer,
      'from_date': '2026-10-01',
      'to_date': '2026-10-09',
      'opening_balance': 0,
      'total_debit': 1240,
      'total_credit': 0,
      'total_litres': 20,
      'closing_balance': 1240,
      'lines': [
        {
          'kind': 'SALE',
          'reference_id': 's1',
          'date': '2026-10-05',
          'description': 'Milk sale 20.00 L @ 62.00',
          'litres': 20,
          'debit': 1240,
          'credit': 0,
          'balance': 1240,
          'rate': 62,
          'recorded_by': 'Alice Wanjiru',
          'recorded_at': '2026-10-05T10:42:00+03:00',
          'method': 'CREDIT',
          'late_reason': 'Receipt found later',
        },
      ],
    },
  }),
};

void main() {
  setUpAll(loadFonts);

  for (final (size, scale) in const [
    (Size(320, 640), 2.0),
    (Size(412, 915), 1.0),
  ]) {
    testWidgets(
      'statement line shows who recorded it ${size.width.toInt()}dp @${scale}x',
      (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = size * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await AppUnderTest.open(
          tester,
          'admin',
          '/customers/$_id',
          replaced: _answers,
        );
        final seen = <String, int>{};
        try {
          final line = find.textContaining('by Alice Wanjiru');
          await tester.scrollUntilVisible(
            line,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          seen['on the line'] = line.evaluate().length;
          seen['litres in period'] = find.text('20 L').evaluate().length;
          await tester.tap(line);
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          seen['sold by'] = find.text('Sold by').evaluate().length;
          seen['rate'] = find.text('20.0 L @ KES 62.00').evaluate().length;
          seen['late'] = find
              .textContaining('Receipt found later')
              .evaluate()
              .length;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen, {
          'on the line': 1,
          'litres in period': 1,
          'sold by': 1,
          'rate': 1,
          'late': 1,
        });
      },
    );
  }
}
