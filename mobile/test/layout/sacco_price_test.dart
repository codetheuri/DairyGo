// A Sacco price from a date: the dialog checks first and shows what changes
// on milk already recorded, a reason is needed to save it, a change to the
// price asks again, and a paid month is said out loud. On the smallest phone
// at the largest text and on a normal phone; nothing scrolls sideways.
//
//   flutter test test/layout/sacco_price_test.dart

import 'package:dairy_sacco_mobile/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _post = 'POST sacco_milk-prices';
const _why = "Why? (kept in each record's history) *";
const _sizes = [(Size(320, 640), 2.0), (Size(412, 915), 1.0)];

Map<String, Object> _answer({
  bool preview = true,
  int repriced = 0,
  int farmers = 0,
  double change = 0,
  int own = 0,
  String? paidThrough,
}) => {
  'success': true,
  'message': 'ok',
  'data': {
    'price': {
      'id': 'p1',
      'sacco_id': 's1',
      'price_per_litre': 45,
      'effective_date': '2026-10-01T00:00:00+03:00',
      'is_active': true,
      'created_at': '2026-11-06T09:00:00+03:00',
      'updated_at': '2026-11-06T09:00:00+03:00',
    },
    'preview': preview,
    'repriced': repriced,
    'farmers': farmers,
    'litres': 52.35,
    'value_change': change,
    'own_price_farmers': own,
    'paid_through': ?paidThrough,
  },
};

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

Finder _textContaining(String text) => find.textContaining(text);

Finder _inDialog(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
  matching: find.byType(TextFormField),
);

/// Runs [body] on the open dialog; always closes the app, so a failed
/// expectation is reported instead of leaving the error handler replaced.
Future<void> _withDialog(
  WidgetTester tester,
  Size size,
  double scale,
  Future<void> Function(AppUnderTest app) body,
) async {
  final app = await _open(tester, size, scale);
  try {
    await body(app);
  } finally {
    await app.close();
  }
}

Future<AppUnderTest> _open(WidgetTester tester, Size size, double scale) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final app = await AppUnderTest.open(tester, 'admin', '/settings');
  await _tap(tester, find.text('Change Rate'));
  return app;
}

void main() {
  for (final (size, scale) in _sizes) {
    final name = '${size.width.toInt()}dp @${scale}x';

    testWidgets(
      'milk already recorded: shows what changes, needs a reason $name',
      (tester) async {
        await _withDialog(tester, size, scale, (app) async {
          app.server.writes[_post] = _answer(
            repriced: 1240,
            farmers: 212,
            change: 186000,
            own: 3,
          );
          await _tap(tester, find.text('Set Active Price Rate'));
          expect((app.server.sentBodies[_post] as Map)['preview'], true);
          expect(_textContaining('1,240 milk records'), findsOneWidget);
          expect(
            _textContaining('KES 186,000.00 more for 212 farmers'),
            findsOneWidget,
          );
          expect(
            _textContaining('3 farmers on their own price stay'),
            findsOneWidget,
          );
          expect(_textContaining('tap Work out again'), findsOneWidget);
          expect(_inDialog(_why), findsOneWidget);
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));

          // No reason: nothing more is sent.
          final sent = app.server.sent.length;
          await _tap(tester, find.text('Save and reprice'));
          expect(find.text('Say why the price is changing'), findsOneWidget);
          expect(app.server.sent.length, sent);

          // Changing the price throws the check away: it asks again.
          final priceField = find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(TextFormField),
              )
              .first;
          await tester.ensureVisible(priceField);
          await _settle(tester);
          await tester.enterText(priceField, '46');
          await _settle(tester);
          expect(find.text('Save and reprice'), findsNothing);
          expect(find.text('Set Active Price Rate'), findsOneWidget);
          await _tap(tester, find.text('Set Active Price Rate'));
          expect(find.text('Save and reprice'), findsOneWidget);

          await tester.enterText(
            _inDialog("Why? (kept in each record's history) *"),
            'Board agreed 46 from October',
          );
          app.server.writes[_post] = _answer(
            preview: false,
            repriced: 1240,
            farmers: 212,
            change: 186000,
          );
          await _tap(tester, find.text('Save and reprice'));
          final body = app.server.sentBodies[_post] as Map;
          expect(body['reason'], 'Board agreed 46 from October');
          expect(body['price_per_litre'], 46);
          expect(body.containsKey('preview'), isFalse);
          expect(find.byType(Dialog), findsNothing);
          expect(
            _textContaining('1,240 milk records repriced'),
            findsOneWidget,
          );
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        });
      },
    );

    testWidgets('nothing recorded yet: saves straight away $name', (
      tester,
    ) async {
      await _withDialog(tester, size, scale, (app) async {
        app.server.writes[_post] = _answer();
        await _tap(tester, find.text('Set Active Price Rate'));
        expect(
          app.server.sent.where((s) => s == _post).length,
          2,
          reason: 'one check, one save',
        );
        expect(
          (app.server.sentBodies[_post] as Map).containsKey('preview'),
          isFalse,
        );
        expect(find.byType(Dialog), findsNothing);
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      });
    });

    testWidgets('a paid month is said out loud; no reason needed $name', (
      tester,
    ) async {
      await _withDialog(tester, size, scale, (app) async {
        app.server.writes[_post] = _answer(paidThrough: '2026-10-31');
        await _tap(tester, find.text('Set Active Price Rate'));
        expect(
          _textContaining('Milk up to 31 Oct 2026 is in an approved pay run'),
          findsOneWidget,
        );
        expect(_textContaining('cancel that pay run first'), findsOneWidget);
        expect(find.text('Save price'), findsOneWidget);
        expect(
          _inDialog("Why? (kept in each record's history) *"),
          findsNothing,
        );
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      });
    });
  }
}
