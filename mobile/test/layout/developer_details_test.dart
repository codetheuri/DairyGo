// The developer's details are on the splash and sign-in screens and in
// "About DairyGo" on the More page, fully on screen on the smallest phone at
// the largest text.
//
//   flutter test test/layout/developer_details_test.dart

import 'package:dairy_sacco_mobile/core/constants/developer.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/auth_state.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:dairy_sacco_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

class _SignedOut extends AuthController {
  @override
  Future<AuthState> build() async => AuthState.unauthenticated();
}

const _small = Size(320, 640);

void _smallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = _small * 2;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void _onScreen(WidgetTester tester, Finder found) {
  expect(found, findsOneWidget);
  final box = tester.getRect(found);
  expect(box.left >= 0 && box.right <= _small.width, isTrue, reason: '$box');
}

void main() {
  setUpAll(loadFonts);

  for (final (name, screen) in const [
    ('splash', SplashScreen()),
    ('sign-in', LoginScreen()),
  ]) {
    testWidgets('$name screen names the developer', (tester) async {
      _smallPhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(_SignedOut.new)],
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump();
      final credit = find.textContaining(Developer.name);
      await tester.ensureVisible(credit);
      await tester.pump();
      _onScreen(tester, credit);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('More > About DairyGo shows how to reach the developer', (
    tester,
  ) async {
    _smallPhone(tester);
    final app = await AppUnderTest.open(tester, 'admin', '/more');
    try {
      final about = find.text('About DairyGo');
      await tester.scrollUntilVisible(about, 200);
      // Clear of the bottom bar.
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(about);
      await tester.pumpAndSettle();
      for (final text in [Developer.name, Developer.phone, Developer.email]) {
        _onScreen(tester, find.text(text));
      }
      expect(app.errors, isEmpty);
    } finally {
      await app.close();
    }
  });
}
