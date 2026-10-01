// Next of kin on the farmer forms and profile, and the customers who owe
// from the Sacco ledger, on the smallest phone and a large one, at normal
// and the largest text.
//
//   flutter test test/layout/next_of_kin_and_owing_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshots)

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/core/widgets/app_text_field.dart';
import 'package:dairy_sacco_mobile/features/customers/presentation/widgets/customers_owing_sheet.dart';
import 'package:dairy_sacco_mobile/features/members/presentation/widgets/next_of_kin_dialog.dart';
import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _setScreen(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // Let a focused field finish scrolling itself into view first.
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  // AppTextField shows its label above the field.
  final field = find.descendant(
    of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, text);
  await tester.pump();
}

Map<String, Object?> _farmer({bool withKin = false}) => {
  'success': true,
  'message': 'Member retrieved',
  'data': {
    'member': {
      'id': 'f1',
      'membership_number': 'MEM-0007',
      'first_name': 'Peter',
      'last_name': 'Kamau Njoroge wa Githunguri',
      'phone': '0712000013',
      'status': 'ACTIVE',
      if (withKin) ...{
        'next_of_kin_name': 'Mary Wanjiku Kamau Njoroge',
        'next_of_kin_relationship': 'Spouse',
        'next_of_kin_phone': '0712000099',
      },
    },
  },
};

void main() {
  setUpAll(loadFonts);

  const sizes = [Size(320, 640), Size(412, 915)];
  const scales = [1.0, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      final name = '${size.width.toInt()}dp @${scale}x';
      final shoot = _screenshots && size.width == 412 && scale == 1.0;

      testWidgets('Register a farmer without next of kin: $name', (
        tester,
      ) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(
          tester,
          'collector',
          '/members/register',
        );
        app.server.writes['POST sacco_members'] = _farmer();
        try {
          await _type(tester, 'First Name *', 'Peter');
          await _type(tester, 'Last Name *', 'Kamau');
          await _type(tester, 'Phone Number *', '0712000013');
          await _tap(tester, find.text('Register Farmer Member'));
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(app.server.sent, ['POST sacco_members']);
        final body = app.server.sentBodies['POST sacco_members'] as Map;
        expect(body['next_of_kin_name'] ?? '', isEmpty);
      });

      testWidgets('Register a farmer with next of kin: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(
          tester,
          'collector',
          '/members/register',
        );
        app.server.writes['POST sacco_members'] = _farmer(withKin: true);
        final seen = <String, int>{};
        try {
          await _type(tester, 'First Name *', 'Peter');
          await _type(tester, 'Last Name *', 'Kamau');
          await _type(tester, 'Phone Number *', '0712000013');

          // A next of kin phone without a name is not sent.
          await _type(tester, 'Next of kin phone', '0712000099');
          await _tap(tester, find.text('Register Farmer Member'));
          seen['name needed'] = find
              .text('Give their name, or leave next of kin empty')
              .evaluate()
              .length;
          seen['sent early'] = app.server.sent.length;

          await _type(tester, 'Next of kin full name', 'Mary Wanjiku');
          await _tap(tester, find.text('Relationship'));
          await tester.tap(find.text('Spouse').last);
          await _settle(tester);
          // The farmer's own number is not a next of kin contact.
          await _type(tester, 'Next of kin phone', '0712000013');
          await _tap(tester, find.text('Register Farmer Member'));
          seen['same phone'] = find
              .text('Use a different number from the farmer\'s own')
              .evaluate()
              .length;
          await _type(tester, 'Next of kin phone', '0712000099');
          if (shoot) {
            await tester.ensureVisible(find.text('Next of Kin (optional)'));
            await tester.pump();
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/register_farmer_next_of_kin.png'),
            );
          }
          await _tap(tester, find.text('Register Farmer Member'));
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['name needed'], 1);
        expect(seen['sent early'], 0);
        expect(seen['same phone'], 1);
        expect(app.server.sent, ['POST sacco_members']);
        final body = app.server.sentBodies['POST sacco_members'] as Map;
        expect(body['next_of_kin_name'], 'Mary Wanjiku');
        expect(body['next_of_kin_relationship'], 'Spouse');
        expect(body['next_of_kin_phone'], '0712000099');
      });

      testWidgets('Farmer profile, next of kin: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/members');
        app.server.replaced['sacco_members_f1'] = _farmer();
        app.server.writes['PUT sacco_members_f1'] = _farmer(withKin: true);
        final seen = <String, int>{};
        try {
          app.container.read(appRouterProvider).push('/members/f1');
          await _settle(tester);
          seen['missing'] = find
              .textContaining('Not recorded.')
              .evaluate()
              .length;
          await _tap(tester, find.text('Add next of kin'));
          seen['dialog'] = find.byType(NextOfKinDialog).evaluate().length;
          await _type(
            tester,
            'Next of kin full name',
            'Mary Wanjiku Kamau Njoroge',
          );
          await _tap(tester, find.text('Relationship'));
          await tester.tap(find.text('Spouse').last);
          await _settle(tester);
          await _type(tester, 'Next of kin phone', '0712000099');
          if (shoot) {
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/next_of_kin_dialog.png'),
            );
          }
          // The profile is asked for again after saving; it now has the kin.
          app.server.replaced['sacco_members_f1'] = _farmer(withKin: true);
          await _tap(tester, find.widgetWithText(FilledButton, 'Save'));
          seen['saved'] = find.text('Next of kin saved').evaluate().length;
          seen['shown'] = find
              .text('Mary Wanjiku Kamau Njoroge')
              .evaluate()
              .length;
          seen['change'] = find.text('Change next of kin').evaluate().length;
          if (shoot) {
            await tester.ensureVisible(find.text('Change next of kin'));
            await tester.pump();
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/farmer_profile_next_of_kin.png'),
            );
          }
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['missing'], 1);
        expect(seen['dialog'], 1);
        expect(seen['saved'], 1);
        expect(seen['shown'], 1);
        expect(seen['change'], 1);
        expect(app.server.sent, ['PUT sacco_members_f1']);
      });

      for (final role in const ['admin', 'board']) {
        testWidgets('Ledger shows who owes: $role $name', (tester) async {
          _setScreen(tester, size, scale);
          final app = await AppUnderTest.open(tester, role, '/reports');
          final seen = <String, int>{};
          try {
            await tester.tap(find.text('Ledger'));
            await _settle(tester);
            await _tap(tester, find.text('Customers Owe (now)'));
            seen['sheet'] = find.byType(CustomersOwingSheet).evaluate().length;
            seen['total'] = find
                .textContaining('2 customers owe KES 94800.00')
                .evaluate()
                .length;
            seen['largest first'] =
                tester.getTopLeft(find.text('KES 93000.00')).dy <
                    tester.getTopLeft(find.text('KES 1800.00')).dy
                ? 1
                : 0;
            if (shoot) {
              await expectLater(
                find.byType(DairySaccoApp),
                matchesGoldenFile('screenshots/customers_owing_$role.png'),
              );
            }
            await tester.tap(find.text('Mama Njeri Hotel').last);
            await _settle(tester);
            seen['closed'] = find.byType(CustomersOwingSheet).evaluate().length;
          } finally {
            await app.close();
          }
          expect(app.errors, isEmpty, reason: app.errors.join('\n'));
          expect(seen['sheet'], 1);
          expect(seen['total'], 1);
          expect(seen['largest first'], 1);
          expect(seen['closed'], 0);
          expect(
            app.server.requests,
            contains('sacco_customers_cf623959-71f2-4fd4-a77d-65ac7198ca37'),
          );
        });
      }
    }
  }

  testWidgets('A collector sees no next of kin and cannot add one', (
    tester,
  ) async {
    _setScreen(tester, const Size(320, 640), 2.0);
    final app = await AppUnderTest.open(tester, 'collector', '/members');
    app.server.replaced['sacco_members_f1'] = _farmer();
    final seen = <String, int>{};
    try {
      app.container.read(appRouterProvider).push('/members/f1');
      await _settle(tester);
      seen['ask'] = find.text('Not recorded.').evaluate().length;
      seen['button'] = find.text('Add next of kin').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['ask'], 1);
    expect(seen['button'], 0);
  });
}
