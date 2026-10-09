// A farmer's buying price on their profile: the Sacco's or their own, with
// history; admins set their own price, seeing first how many unpaid milk
// records change. Smallest phone at the largest text, nothing sideways.
//
//   flutter test test/layout/buying_price_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

Map<String, Object> _ok(Map<String, Object?> data) => {
  'success': true,
  'message': 'ok',
  'data': data,
};

Map<String, Object> _answers(String role) {
  final members =
      jsonDecode(
            File(
              'test/layout/fixtures/$role/sacco_members.json',
            ).readAsStringSync(),
          )['body']['data']['members']
          as List;
  final farmer = {
    ...(members.first as Map<String, dynamic>),
    'id': 'f1',
    'first_name': 'Jane',
    'last_name': 'Muthoni',
  };
  return {
    'sacco_members_f1': _ok({'member': farmer}),
    'sacco_members_f1_prices': _ok({
      'price_today': 45,
      'own_price': true,
      'sacco_price_today': 42,
      'schedule': [
        {
          'id': 'p1',
          'price_per_litre': 45,
          'effective_date': '2026-10-03',
          'reason': 'Agreed by the board',
        },
      ],
    }),
  };
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(loadFonts);

  void small(WidgetTester tester) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(320, 640) * 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('admin sees the own price and checks a new one', (tester) async {
    small(tester);
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/members/f1',
      replaced: _answers('admin'),
    );
    app.server.writes['POST sacco_members_f1_prices'] = _ok({
      'repriced': 3,
      'preview': true,
    });
    final seen = <String, int>{};
    try {
      await _settle(tester);
      final button = find.text('Set own price');
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      seen['own price'] = find.text('Own price KES 45.00/L').evaluate().length;
      seen['history'] = find
          .textContaining('Agreed by the board')
          .evaluate()
          .length;
      await tester.tap(button);
      await _settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Price per litre'),
        '48',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Reason *'),
        'New agreement',
      );
      await tester.ensureVisible(find.text('Check'));
      await tester.tap(find.text('Check'));
      await _settle(tester);
      seen['count'] = find.textContaining('3 milk records').evaluate().length;
      seen['save'] = find.text('Save price').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen, {'own price': 1, 'history': 1, 'count': 1, 'save': 1});
    final body = app.server.sentBodies['POST sacco_members_f1_prices'] as Map;
    expect(body['preview'], true);
    expect(body['price_per_litre'], 48);
  });

  testWidgets('a collector sees the price but cannot change it', (
    tester,
  ) async {
    small(tester);
    final app = await AppUnderTest.open(
      tester,
      'collector',
      '/members/f1',
      replaced: _answers('collector'),
      permissions: [...userFor('collector').permissions, 'milk.prices.read'],
    );
    final seen = <String, int>{};
    try {
      await _settle(tester);
      final price = find.text('Own price KES 45.00/L');
      await tester.scrollUntilVisible(
        price,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      seen['price'] = price.evaluate().length;
      seen['button'] = find.text('Set own price').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen, {'price': 1, 'button': 0});
  });
}
