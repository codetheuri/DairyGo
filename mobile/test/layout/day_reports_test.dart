// Reports by day, week, month or chosen dates, the Ledger's day-by-day list,
// and litres sold to each customer. On the smallest phone at the largest
// text and on a normal phone; nothing scrolls sideways.
//
//   flutter test test/layout/day_reports_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/layout/fixtures/admin/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, Object> _ok(Map<String, Object?> data) => {
  'success': true,
  'message': 'ok',
  'data': data,
};

Map<String, Object?> _day(
  String date,
  double inL,
  double sold,
  String status,
) => {
  'date': date,
  'collected_litres': inL,
  'sold_litres': sold,
  'spoiled_litres': 0,
  'sales_kes': sold * 62,
  'unaccounted_litres': inL - sold,
  'allowance_litres': 1,
  'balance_status': status,
};

Map<String, Object> _answers() {
  final ledger = Map<String, Object?>.from(
    (_fixture('sacco_reports_reconciliation')['body']['data'] as Map)['ledger']
        as Map,
  );
  ledger['days'] = [
    _day('2026-10-01', 412.5, 412.5, 'BALANCED'),
    _day('2026-10-02', 400, 360, 'MISSING'),
  ];
  final customers = Map<String, Object?>.from(
    _fixture('sacco_customers')['body']['data'] as Map,
  );
  customers['customers'] = [
    for (final c in customers['customers'] as List)
      {...(c as Map), 'balance': 18600, 'month_litres': 1240.5},
  ];
  return {
    'sacco_reports_reconciliation': _ok({'ledger': ledger}),
    'sacco_customers': _ok(customers),
  };
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String _dayLabel(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

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

    testWidgets('reports step by day and list the days $name', (tester) async {
      phone(tester);
      final app = await AppUnderTest.open(
        tester,
        'admin',
        '/reports',
        replaced: _answers(),
      );
      final seen = <String, Object>{};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      try {
        await _settle(tester);
        seen['four choices'] = [
          'Day',
          'Week',
          'Month',
          'Dates',
        ].every((t) => find.text(t).evaluate().isNotEmpty);
        await tester.tap(find.text('Day'));
        await _settle(tester);
        seen['today'] = find.text(_dayLabel(today)).evaluate().length;
        seen['no later than today'] =
            tester
                .widget<IconButton>(
                  find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
                )
                .onPressed ==
            null;
        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
        );
        await _settle(tester);
        seen['yesterday'] = find
            .text(_dayLabel(today.subtract(const Duration(days: 1))))
            .evaluate()
            .length;

        await tester.tap(find.text('Month'));
        await _settle(tester);
        await tester.tap(find.text('Ledger'));
        await _settle(tester);
        final day = find.text('Fri 2 Oct');
        await tester.scrollUntilVisible(
          day,
          300,
          scrollable: find.byType(Scrollable).at(1),
        );
        seen['to check'] = find.textContaining('1 to check').evaluate().length;
        await tester.tap(day);
        await _settle(tester);
        seen['that day'] = find.text('Fri 2 Oct 2026').evaluate().length;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen, {
        'four choices': true,
        'today': 1,
        'no later than today': true,
        'yesterday': 1,
        'to check': 1,
        'that day': 1,
      });
    });

    testWidgets('customers show litres this month $name', (tester) async {
      phone(tester);
      final app = await AppUnderTest.open(
        tester,
        'admin',
        '/customers',
        replaced: _answers(),
      );
      int litres;
      try {
        await _settle(tester);
        litres = find.text('1240.5 L this month').evaluate().length;
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(litres, greaterThan(0));
    });
  }
}
