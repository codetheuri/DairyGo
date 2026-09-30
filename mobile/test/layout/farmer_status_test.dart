// Changing a farmer's status (active, inactive, suspended), what a suspended
// or inactive farmer looks like, and the Sacco's "mark farmers inactive"
// setting, on the smallest phone and a large one, at normal and the largest
// text.
//
//   flutter test test/layout/farmer_status_test.dart

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/features/members/presentation/widgets/farmer_status_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

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
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

Map<String, Object?> _farmer(String status) => {
  'success': true,
  'message': 'Member retrieved',
  'data': {
    'member': {
      'id': 'f1',
      'membership_number': '007',
      'first_name': 'Peter',
      'last_name': 'Kamau',
      'phone': '0712000013',
      'status': status,
    },
  },
};

const _noHistory = {
  'success': true,
  'message': 'Farmer history',
  'data': {'history': <Object>[]},
};

void main() {
  setUpAll(loadFonts);

  const sizes = [Size(320, 640), Size(412, 915)];
  const scales = [1.0, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      final name = '${size.width.toInt()}dp @${scale}x';

      testWidgets('Suspend a farmer: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/members');
        app.server.replaced['sacco_members_f1'] = _farmer('ACTIVE');
        app.server.replaced['sacco_members_f1_history'] = _noHistory;
        app.server.writes['PATCH sacco_members_f1_status'] = _farmer(
          'SUSPENDED',
        );
        final seen = <String, Object?>{};
        try {
          app.container.read(appRouterProvider).push('/members/f1');
          await _settle(tester);
          await _tap(tester, find.text('Change Status'));
          seen['sheet'] = find.byType(FarmerStatusSheet).evaluate().length;
          seen['now'] = find.text('Active (now)').evaluate().length;

          await _tap(tester, find.text('Suspended'));
          await _tap(tester, find.text('Make suspended'));
          seen['needs reason'] = find
              .text('Give a reason for suspending the farmer.')
              .evaluate()
              .length;
          seen['nothing sent'] = [...app.server.sent];

          await tester.enterText(
            find.widgetWithText(TextField, 'Reason (required)'),
            'Water found in the milk',
          );
          await _tap(tester, find.text('Make suspended'));
          seen['closed'] = find.byType(FarmerStatusSheet).evaluate().length;
          seen['told'] = find
              .text('Peter Kamau is now suspended')
              .evaluate()
              .length;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['sheet'], 1);
        expect(seen['now'], 1);
        expect(seen['needs reason'], 1);
        expect(seen['nothing sent'], isEmpty);
        expect(seen['closed'], 0);
        expect(seen['told'], 1);
        expect(app.server.sentBodies['PATCH sacco_members_f1_status'], {
          'status': 'SUSPENDED',
          'reason': 'Water found in the milk',
        });
      });

      testWidgets('A suspended farmer takes no milk: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/members');
        app.server.replaced['sacco_members_f1'] = _farmer('SUSPENDED');
        app.server.replaced['sacco_members_f1_history'] = _noHistory;
        final seen = <String, Object?>{};
        try {
          app.container.read(appRouterProvider).push('/members/f1');
          await _settle(tester);
          seen['note'] = find
              .text('Suspended: milk cannot be recorded for this farmer.')
              .evaluate()
              .length;
          final button = find.widgetWithText(
            ElevatedButton,
            'Suspended: no milk intake',
          );
          seen['button'] = button.evaluate().length;
          seen['disabled'] =
              tester.widget<ElevatedButton>(button).onPressed == null;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['note'], 1);
        expect(seen['button'], 1);
        expect(seen['disabled'], isTrue);
      });
    }
  }

  testWidgets('An inactive farmer: explained, and can be reactivated', (
    tester,
  ) async {
    _setScreen(tester, const Size(320, 640), 1.0);
    final app = await AppUnderTest.open(tester, 'admin', '/members');
    app.server.replaced['sacco_members_f1'] = _farmer('INACTIVE');
    app.server.replaced['sacco_members_f1_history'] = _noHistory;
    app.server.writes['PATCH sacco_members_f1_status'] = _farmer('ACTIVE');
    final seen = <String, Object?>{};
    try {
      app.container.read(appRouterProvider).push('/members/f1');
      await _settle(tester);
      seen['note'] = find
          .text('Inactive: recording milk makes this farmer active again.')
          .evaluate()
          .length;
      seen['can record'] = find
          .text('Record Milk Intake for Peter')
          .evaluate()
          .length;
      await _tap(tester, find.text('Change Status'));
      await _tap(tester, find.text('Active'));
      await _tap(tester, find.text('Make active'));
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['note'], 1);
    expect(seen['can record'], 1);
    // No reason given: none is sent.
    expect(app.server.sentBodies['PATCH sacco_members_f1_status'], {
      'status': 'ACTIVE',
    });
  });

  testWidgets('A collector cannot change a farmer\'s status', (tester) async {
    _setScreen(tester, const Size(320, 640), 2.0);
    final app = await AppUnderTest.open(tester, 'collector', '/members');
    app.server.replaced['sacco_members_f1'] = _farmer('ACTIVE');
    late int buttons;
    try {
      app.container.read(appRouterProvider).push('/members/f1');
      await _settle(tester);
      buttons = find.text('Change Status').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(buttons, 0);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Set the days without milk @${scale}x', (tester) async {
      _setScreen(tester, const Size(320, 640), scale);
      final app = await AppUnderTest.open(tester, 'admin', '/settings');
      app.server.writes['PUT sacco_settings'] = {
        'success': true,
        'message': 'Sacco settings updated successfully',
        'data': {
          'settings': {'sacco_id': 's1', 'inactive_after_days': 30},
        },
      };
      final seen = <String, Object?>{};
      try {
        await _settle(tester);
        seen['default'] = find
            .text('After 60 days without milk')
            .evaluate()
            .length;
        await _tap(tester, find.text('Mark farmers inactive'));
        final field = find.widgetWithText(TextField, 'Days without milk');
        await tester.enterText(field, '400');
        await _tap(tester, find.text('Save'));
        seen['too many'] = find.text('Enter 0 to 365 days').evaluate().length;
        await tester.enterText(field, '30');
        await _tap(tester, find.text('Save'));
      } finally {
        await app.close();
      }
      expect(app.errors, isEmpty, reason: app.errors.join('\n'));
      expect(seen['default'], 1);
      expect(seen['too many'], 1);
      expect(app.server.sentBodies['PUT sacco_settings'], {
        'inactive_after_days': 30,
      });
    });
  }

  testWidgets('A collector does not see the setting', (tester) async {
    _setScreen(tester, const Size(412, 915), 1.0);
    final app = await AppUnderTest.open(tester, 'collector', '/settings');
    late int cards;
    try {
      await _settle(tester);
      cards = find.text('Mark farmers inactive').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(cards, 0);
  });
}
