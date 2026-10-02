import 'package:dairy_sacco_mobile/core/widgets/late_entry_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, String? reason) async {
    tester.view.physicalSize = const Size(320, 640) * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LateEntryNote(reason: reason)),
      ),
    );
  }

  testWidgets('a late record says so, with the reason, on a small phone', (
    tester,
  ) async {
    await show(tester, "Collector's phone was off");
    expect(
      find.text("Entered late by DairyGo support: Collector's phone was off"),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a record made on its day shows nothing', (tester) async {
    await show(tester, null);
    expect(find.textContaining('Entered late'), findsNothing);
  });
}
