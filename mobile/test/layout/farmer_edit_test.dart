// Editing a farmer's details (personal, next of kin, location, payout) and
// their change history, on the smallest phone and a large one, at normal and
// the largest text.
//
//   flutter test test/layout/farmer_edit_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshots)

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/core/widgets/app_text_field.dart';
import 'package:dairy_sacco_mobile/features/members/presentation/screens/edit_farmer_screen.dart';
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

String _text(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

Map<String, Object?> _farmer() => {
  'success': true,
  'message': 'Member retrieved',
  'data': {
    'member': {
      'id': 'f1',
      'membership_number': 'MEM-0007',
      'first_name': 'Peter',
      'last_name': 'Kamau',
      'phone': '0712000013',
      'national_id': '12345678',
      'gender': 'MALE',
      'location': 'Githunguri Route A',
      'status': 'ACTIVE',
      'mpesa_number': '0712000013',
      'mpesa_name': 'PETER KAMAU',
      'bank_name': 'Equity Bank',
      'bank_account_number': '0123456789',
      'bank_branch': 'Kiambu',
      'next_of_kin_name': 'Mary Wanjiku',
      'next_of_kin_relationship': 'Spouse',
      'next_of_kin_phone': '0712000099',
    },
  },
};

const _history = {
  'success': true,
  'message': 'Farmer history',
  'data': {
    'history': [
      {
        'id': 'h1',
        'entity_type': 'member',
        'entity_id': 'f1',
        'action': 'UPDATE',
        'actor_name': 'uxadmin',
        'old_values': '{"mpesa_number":"0711111111"}',
        'new_values': '{"mpesa_number":"0712000013"}',
        'created_at': '2026-09-30T10:15:00Z',
      },
    ],
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

      testWidgets('Edit a farmer: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/members');
        app.server.replaced['sacco_members_f1'] = _farmer();
        app.server.replaced['sacco_members_f1_history'] = _history;
        app.server.writes['PUT sacco_members_f1'] = _farmer();
        final seen = <String, Object?>{};
        try {
          app.container.read(appRouterProvider).push('/members/f1');
          await _settle(tester);
          seen['bank shown'] = find
              .text('Equity Bank · 0123456789 · Kiambu')
              .evaluate()
              .length;

          await _tap(tester, find.text('Change history'));
          seen['history'] = find.textContaining('0711111111').evaluate().length;

          await _tap(tester, find.text('Edit Farmer Details'));
          seen['form'] = find.byType(EditFarmerScreen).evaluate().length;
          // Starts from the saved details.
          seen['prefilled'] = [
            _text(tester, 'First Name *'),
            _text(tester, 'M-Pesa Number'),
            _text(tester, 'Next of kin full name'),
            _text(tester, 'Bank'),
          ].join('|');
          // No membership number field: it cannot change.
          seen['membership field'] = _field(
            'Membership Number',
          ).evaluate().length;

          await _type(tester, 'M-Pesa Number', '0799000000');
          await _type(tester, 'Bank', '');
          await _type(tester, 'Bank Account Number', '');
          await _type(tester, 'Bank Branch', '');
          await _type(tester, 'Collection Route / Village', 'Ndumberi');
          if (shoot) {
            await tester.ensureVisible(find.text('Payout Details'));
            await tester.pump();
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/edit_farmer.png'),
            );
          }
          await _tap(tester, find.text('Save Changes'));
          seen['saved'] = find.text('Farmer details saved').evaluate().length;
          seen['closed'] = find.byType(EditFarmerScreen).evaluate().length;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['bank shown'], 1);
        expect(seen['history'], greaterThan(0));
        expect(seen['form'], 1);
        expect(seen['prefilled'], 'Peter|0712000013|Mary Wanjiku|Equity Bank');
        expect(seen['membership field'], 0);
        expect(seen['saved'], 1);
        expect(seen['closed'], 0);
        expect(app.server.sent, ['PUT sacco_members_f1']);
        final body = app.server.sentBodies['PUT sacco_members_f1'] as Map;
        expect(body['mpesa_number'], '0799000000');
        expect(body['location'], 'Ndumberi');
        // Emptied fields are sent empty, which clears them.
        expect(body['bank_name'], '');
        expect(body['bank_account_number'], '');
        // Untouched details are sent as they were.
        expect(body['first_name'], 'Peter');
        expect(body['gender'], 'MALE');
        expect(body['next_of_kin_relationship'], 'Spouse');
      });
    }
  }

  testWidgets('A refused edit shows why and keeps the form', (tester) async {
    _setScreen(tester, const Size(412, 915), 1.0);
    final app = await AppUnderTest.open(tester, 'admin', '/members');
    app.server.replaced['sacco_members_f1'] = _farmer();
    // No answer for the save: it fails as a refusal from the server would.
    final seen = <String, int>{};
    try {
      app.container.read(appRouterProvider).push('/members/f1/edit');
      await _settle(tester);
      await _tap(tester, find.text('Save Changes'));
      seen['message'] = find.text('not found').evaluate().length;
      seen['still open'] = find.byType(EditFarmerScreen).evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['message'], 1);
    expect(seen['still open'], 1);
  });

  testWidgets('A collector cannot edit a farmer', (tester) async {
    _setScreen(tester, const Size(320, 640), 2.0);
    final app = await AppUnderTest.open(tester, 'collector', '/members');
    app.server.replaced['sacco_members_f1'] = _farmer();
    final seen = <String, int>{};
    try {
      app.container.read(appRouterProvider).push('/members/f1');
      await _settle(tester);
      seen['button'] = find.text('Edit Farmer Details').evaluate().length;
      seen['icon'] = find.byTooltip('Edit farmer details').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['button'], 0);
    expect(seen['icon'], 0);
  });
}
