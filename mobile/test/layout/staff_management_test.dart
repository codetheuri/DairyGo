// Staff management for a Sacco administrator: changing a staff member's role
// and removing them, on the smallest phone and a large one, at normal and
// the largest text.
//
//   flutter test test/layout/staff_management_test.dart
//   ... --update-goldens --dart-define=SCREENSHOTS=true   (screenshots)

import 'package:dairy_sacco_mobile/features/settings/presentation/widgets/staff_actions_sheet.dart';
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
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUpAll(loadFonts);

  const sizes = [Size(320, 640), Size(412, 915)];
  const scales = [1.0, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      final name = '${size.width.toInt()}dp @${scale}x';
      final shoot = _screenshots && size.width == 412 && scale == 1.0;

      testWidgets('Change a role: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/settings/staff');
        // The collector (id 29) becomes a board member.
        app.server.writes['PUT auth_users_29_role'] = {
          'success': true,
          'message': 'Role changed to Board Member / Executive',
          'data': {
            'user': {
              'id': 29,
              'email': 'c@ux.io',
              'username': 'uxcol',
              'role_name': 'Board Member / Executive',
            },
          },
        };
        final seen = <String, int>{};
        try {
          seen['you'] = find.text('You').evaluate().length;
          seen['manage'] = find.text('Manage ›').evaluate().length;
          if (shoot) {
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/staff_list_admin.png'),
            );
          }

          // Your own row opens nothing.
          await tester.tap(find.text('Admin UX Test Dairy'));
          await _settle(tester);
          seen['own sheet'] = find.byType(StaffActionsSheet).evaluate().length;

          await tester.tap(find.text('Col One'));
          await _settle(tester);
          seen['sheet'] = find.byType(StaffActionsSheet).evaluate().length;
          seen['no change yet'] = find
              .text('This is their role now')
              .evaluate()
              .length;
          await _tap(tester, find.text('Board Member'));
          if (shoot) {
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/staff_actions_admin.png'),
            );
          }
          await _tap(tester, find.widgetWithText(FilledButton, 'Change role'));
          seen['confirm'] = find
              .text('Make Col One a Board Member?')
              .evaluate()
              .length;
          await tester.tap(
            find.widgetWithText(FilledButton, 'Change role').last,
          );
          await _settle(tester);
          seen['done'] = find
              .text('Col One is now a Board Member')
              .evaluate()
              .length;
          seen['closed'] = find.byType(StaffActionsSheet).evaluate().length;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['you'], 1);
        expect(seen['manage'], 2);
        expect(seen['own sheet'], 0);
        expect(seen['sheet'], 1);
        expect(seen['no change yet'], 1);
        expect(seen['confirm'], 1);
        expect(seen['done'], 1);
        expect(seen['closed'], 0);
        expect(app.server.sent, ['PUT auth_users_29_role']);
        // The list is loaded again after the change.
        expect(app.server.requests.where((r) => r == 'auth_users').length, 2);
      });

      testWidgets('Remove a staff member: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(tester, 'admin', '/settings/staff');
        app.server.writes['DELETE auth_users_29'] = {
          'success': true,
          'message': 'Staff account removed',
          'data': null,
        };
        final seen = <String, int>{};
        try {
          await tester.tap(find.text('Col One'));
          await _settle(tester);
          await _tap(tester, find.text('Remove from the Sacco'));
          seen['confirm'] = find.text('Remove Col One?').evaluate().length;
          if (shoot) {
            await expectLater(
              find.byType(DairySaccoApp),
              matchesGoldenFile('screenshots/staff_remove_admin.png'),
            );
          }
          await tester.tap(find.widgetWithText(TextButton, 'Remove'));
          await _settle(tester);
          seen['done'] = find.text('Col One was removed').evaluate().length;
          seen['closed'] = find.byType(StaffActionsSheet).evaluate().length;
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        expect(seen['confirm'], 1);
        expect(seen['done'], 1);
        expect(seen['closed'], 0);
        expect(app.server.sent, ['DELETE auth_users_29']);
      });
    }
  }

  testWidgets('A refused change shows the server\'s reason', (tester) async {
    _setScreen(tester, const Size(412, 915), 1.0);
    // No answer is set up, so the save fails as the server's refusals do.
    final app = await AppUnderTest.open(tester, 'admin', '/settings/staff');
    final seen = <String, int>{};
    try {
      await tester.tap(find.text('Grace Muthoni'));
      await _settle(tester);
      await _tap(tester, find.text('Remove from the Sacco'));
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await _settle(tester);
      seen['message'] = find.text('not found').evaluate().length;
      seen['still open'] = find.byType(StaffActionsSheet).evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['message'], 1);
    expect(seen['still open'], 1);
  });
}
