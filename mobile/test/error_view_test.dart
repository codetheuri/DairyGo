import 'package:dairy_sacco_mobile/core/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, String message) async {
  // A pushed screen, so an automatic "go back" would be visible.
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: ErrorView(message: message, onRetry: () {}),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no access: explained, no Retry, and the screen stays', (
    tester,
  ) async {
    await _show(tester, 'Forbidden: insufficient permissions');
    expect(find.text('No access'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('No access'), findsOneWidget, reason: 'not closed');
  });

  testWidgets('no connection offers Retry', (tester) async {
    await _show(
      tester,
      'No internet connection. Check your signal or data bundle and try again.',
    );
    expect(find.text('Could not connect'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('other errors show the server message and Retry', (tester) async {
    await _show(tester, 'Customer not found');
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Customer not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
