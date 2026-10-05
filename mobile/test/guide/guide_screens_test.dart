// Pictures for the "how to" guides sent to Sacco staff on WhatsApp. Drives
// the real app as a collector, step by step, and saves each screen with the
// place to tap, for docs/guides/mark.py to circle and caption.
//
// Runs only when asked (a plain `flutter test` skips it):
//
//   flutter test test/guide/guide_screens_test.dart \
//     --dart-define=GUIDE=true --update-goldens
//
// or, for everything (pictures, cards and videos): docs/guides/build.sh

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/core/widgets/app_text_field.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../layout/harness.dart';
import 'guide_data.dart';

const _on = bool.fromEnvironment('GUIDE');

/// A phone like the ones Maru's staff use, at normal text size.
const _phone = Size(412, 915);
const _ratio = 2.0;

/// One picture in a guide: the screen, what to say, and where to tap.
class _Step {
  final String task;
  final String title;
  final int number;
  final String file;
  final String caption;
  final Rect? tap;

  _Step(this.task, this.title, this.number, this.file, this.caption, this.tap);

  Map<String, Object?> toJson() => {
    'task': task,
    'title': title,
    'step': number,
    'file': file,
    'caption': caption,
    'ratio': _ratio,
    if (tap != null)
      'tap': {
        'left': tap!.left,
        'top': tap!.top,
        'width': tap!.width,
        'height': tap!.height,
      },
  };
}

final _steps = <_Step>[];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Records the screens of one task: [shot] saves the current screen with a
/// caption, circling [tap] (and tapping it afterwards unless [thenTap] is
/// false).
class _Guide {
  final WidgetTester tester;
  final String task;
  final String title;
  int _n = 0;

  _Guide(this.tester, this.task, this.title);

  Future<void> shot(String caption, {Finder? tap, bool thenTap = true}) async {
    Rect? rect;
    if (tap != null) {
      expect(tap, findsWidgets, reason: '$task step ${_n + 1}: $caption');
      rect = _target(tester, tap);
      // Scroll only when the spot is hidden, so pictures start at the top
      // as staff see them.
      // The bottom bar and buttons pinned above it cover the last ~120 dp.
      if (rect.top < 0 || rect.bottom > _phone.height - 120) {
        await tester.ensureVisible(tap.first);
        await _settle(tester);
        rect = _target(tester, tap);
      }
    }
    _n++;
    final file = '${task}_$_n.png';
    await expectLater(
      find.byType(DairySaccoApp),
      matchesGoldenFile('shots/$file'),
    );
    _steps.add(_Step(task, title, _n, file, caption, rect));
    if (tap != null && thenTap) {
      await tester.tap(tap.first);
      await _settle(tester);
    }
  }
}

/// The area to circle: the whole button or row the finder's text sits in
/// (its nearest ink response, or bottom bar destination), not just the words.
Rect _target(WidgetTester tester, Finder tap) {
  final tappable = find.ancestor(
    of: tap.first,
    matching: find.byWidgetPredicate(
      (w) => w is InkResponse || w is NavigationDestination,
    ),
  );
  final rect = tester.getRect(tap.first);
  if (tappable.evaluate().isEmpty) return rect;
  final around = tester.getRect(tappable.first);
  // A whole screen or list is too big to point at; keep the words then.
  return around.height > 160 ? rect : around;
}

/// Types into the app's labelled field (AppTextField shows its label above).
Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await _settle(tester);
}

Future<AppUnderTest> _open(WidgetTester tester, String route) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = _phone * _ratio;
  addTearDown(tester.view.reset);
  final app = await AppUnderTest.open(
    tester,
    'collector',
    route,
    user: guideCollector(),
    permissions: collectorPermissions,
    replaced: guideAnswers(),
  );
  await _settle(tester);
  return app;
}

void main() {
  setUpAll(loadFonts);
  // As on a phone: no keyboard-focus rings around buttons.
  setUp(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch,
  );
  tearDownAll(() {
    if (!_on) return;
    File('test/guide/shots/steps.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent(
          '  ',
        ).convert([for (final s in _steps) s.toJson()]),
      );
  });

  Finder bar(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('1. find your way', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '01-find-your-way', 'Find your way around');
    try {
      await g.shot(
        'The bar at the bottom takes you to Home, Intake, Sales and Farmers.',
        tap: find.byType(NavigationBar),
        thenTap: false,
      );
      await g.shot(
        'Everything else is under More. Tap More.',
        tap: bar('More'),
      );
      await g.shot(
        'Here: Customers (who owes money), Download reports, Settings and your password.',
        tap: find.text('Customers'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });

  testWidgets('2. record milk', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '02-record-milk', 'Record milk from a farmer');
    try {
      await g.shot(
        'On Home, tap Record Intake.',
        tap: find.text('Record Intake'),
      );
      await g.shot(
        'Tap here to find the farmer.',
        tap: find.text('Tap to search or register a farmer'),
      );
      await g.shot(
        'Type the name or number, then tap the farmer. New farmer? Register them here.',
        tap: find.text(guideFarmer.name),
      );
      await _type(tester, 'Milk Quantity (Litres) *', '12.5');
      await g.shot(
        'Choose the shift, type the litres, then tap Record Milk Intake.',
        tap: find.text('Record Milk Intake'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });

  testWidgets('3. record a sale', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '03-record-sale', 'Record a sale');
    try {
      await g.shot('On Home, tap Direct Sale.', tap: find.text('Direct Sale'));
      await g.shot(
        'Tap here to choose the customer.',
        tap: find.textContaining('customer', findRichText: true).first,
      );
      await g.shot(
        'Tap the customer you sold to.',
        tap: find.text(guideCustomers.first.name),
      );
      await _type(tester, 'Quantity (Litres) *', '20');
      await g.shot(
        'Type the litres. Paid now, or on credit? Choose, then tap Record Sale.',
        tap: find.text('Record Sale'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });

  testWidgets('4. give milk to a collector', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(
      tester,
      '04-transfer-milk',
      'Give milk to another collector',
    );
    try {
      await g.shot(
        'On Home, tap Transfer Milk.',
        tap: find.text('Transfer Milk'),
      );
      await g.shot(
        'Choose the collector who takes the milk.',
        tap: find.text(guideCollectors.first.name),
      );
      await tester.enterText(find.byType(TextFormField).first, '15');
      await _settle(tester);
      await g.shot(
        'Type the litres, then tap Transfer. It counts for both of you at once.',
        tap: find.textContaining('Transfer 15 L'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });

  testWidgets('5. who owes money', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '05-who-owes', 'See which customers owe money');
    try {
      await g.shot('Tap More, at the bottom right.', tap: bar('More'));
      await g.shot('Tap Customers.', tap: find.text('Customers'));
      await g.shot(
        'The yellow bar at the top shows what customers owe. Tap it.',
        tap: find.textContaining('Customers owe'),
      );
      await g.shot(
        'Everyone who owes, biggest first. Tap a customer for their statement.',
        tap: find.text(guideCustomers.first.name).last,
      );
      await g.shot('Every sale and payment, and what they owe now.');
    } finally {
      await app.close();
    }
  });

  testWidgets('6. your milk balance', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '06-milk-balance', "Your day's milk balance");
    try {
      await g.shot(
        'Milk you collected but have not yet sold, moved or recorded as spoilt. '
        'Record every sale so it reaches 0.',
        tap: find.textContaining('Litres not sold yet'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });

  testWidgets('7. a customer pays', skip: !_on, (tester) async {
    final app = await _open(tester, '/dashboard');
    final g = _Guide(tester, '07-customer-pays', 'When a customer pays');
    try {
      await g.shot('Tap More, at the bottom right.', tap: bar('More'));
      await g.shot('Tap Customers.', tap: find.text('Customers'));
      await g.shot(
        'Tap the customer who paid. What they owe is on the right.',
        tap: find.text(guideCustomers.first.name),
      );
      await g.shot('Tap Record Payment.', tap: find.text('Record Payment'));
      await _type(tester, 'Amount received (KES) *', '10000');
      await _type(tester, 'Reference (e.g. M-Pesa code)', 'SJK4H7QX2P');
      await g.shot(
        'Type the amount, choose M-Pesa or Cash, add the M-Pesa code, then tap Record Payment. What they owe goes down at once.',
        tap: find.widgetWithText(ElevatedButton, 'Record Payment'),
        thenTap: false,
      );
    } finally {
      await app.close();
    }
  });
}
