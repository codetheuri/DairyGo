// Downloading reports: the list each role sees, choosing a period and format,
// and a farmer's statement from their profile, on the smallest phone and a
// large one, at normal and the largest text.
//
//   flutter test test/layout/report_downloads_test.dart

import 'dart:io';

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/features/report_downloads/data/report_download_service.dart';
import 'package:dairy_sacco_mobile/features/report_downloads/presentation/report_download_controller.dart';
import 'package:dairy_sacco_mobile/features/report_downloads/presentation/widgets/report_download_sheet.dart';
import 'package:dairy_sacco_mobile/core/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Lets real file writes finish: widget tests run on a fake clock, under
/// which the download's file I/O would never complete.
Future<void> _finishFiles(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

const _farmer = {
  'success': true,
  'message': 'Member retrieved',
  'data': {
    'member': {
      'id': 'f1',
      'membership_number': '002',
      'first_name': 'Rudiah',
      'last_name': 'Mungayo',
      'phone': '0726750512',
      'status': 'ACTIVE',
    },
  },
};

void main() {
  setUpAll(loadFonts);
  late Directory dir;
  // Android's "Save as" screen: the user picks a place and it is saved.
  late List<Map<Object?, Object?>> saveCalls;
  const files = MethodChannel('dairygo/files');
  setUp(() {
    dir = Directory.systemTemp.createTempSync('reports');
    saveCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(files, (call) async {
          saveCalls.add(call.arguments as Map<Object?, Object?>);
          return 'saved';
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(files, null);
    dir.deleteSync(recursive: true);
  });

  // Downloads go to a temporary folder instead of the phone's documents.
  List<dynamic> savedHere() => [
    reportDownloadServiceProvider.overrideWith(
      (ref) => ReportDownloadService(
        ref.watch(dioClientProvider),
        baseDir: () async => dir,
      ),
    ),
  ];

  for (final size in const [Size(320, 640), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      final name = '${size.width.toInt()}dp @${scale}x';

      testWidgets('Admin downloads farmer payouts: $name', (tester) async {
        _setScreen(tester, size, scale);
        final app = await AppUnderTest.open(
          tester,
          'admin',
          '/report-downloads',
          extra: savedHere().cast(),
        );
        final seen = <String, Object?>{};
        try {
          await _settle(tester);
          for (final title in [
            'Farmer Payouts',
            'Farmer Statement',
            'Milk Collections',
            'Customer Statement',
            'Sacco Summary',
            'Farmer Register',
          ]) {
            await tester.scrollUntilVisible(
              find.text(title),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            seen[title] = find.text(title).evaluate().length;
          }
          await tester.scrollUntilVisible(
            find.text('Farmer Payouts'),
            -150,
            scrollable: find.byType(Scrollable).first,
          );
          await _tap(tester, find.text('Farmer Payouts'));
          seen['sheet'] = find.byType(ReportDownloadSheet).evaluate().length;
          await _tap(tester, find.text('Last month'));
          await _tap(tester, find.text('Excel (accounts)'));
          await _tap(tester, find.text('Download Excel'));
          await _finishFiles(tester);
          seen['done'] = find.textContaining('Downloaded:').evaluate().length;
          seen['open'] = find.text('Open').evaluate().length;
          seen['share'] = find.text('Share').evaluate().length;
          await _tap(tester, find.text('Save to phone'));
          seen['saved note'] = find
              .text('Saved to your phone')
              .evaluate()
              .length;
          seen['saved'] = await tester.runAsync(
            () async => dir.listSync(recursive: true).whereType<File>().length,
          );
        } finally {
          await app.close();
        }
        expect(app.errors, isEmpty, reason: app.errors.join('\n'));
        for (final title in [
          'Farmer Payouts',
          'Farmer Statement',
          'Milk Collections',
          'Customer Statement',
          'Sacco Summary',
          'Farmer Register',
        ]) {
          expect(seen[title], greaterThan(0), reason: title);
        }
        expect(seen['sheet'], 1);
        expect(seen['done'], 1);
        expect(seen['open'], 1);
        expect(seen['share'], 1);
        expect(seen['saved note'], 1);
        expect(saveCalls.single['mime'], contains('spreadsheetml'));
        expect(saveCalls.single['path'], endsWith('.xlsx'));
        expect(seen['saved'], 1);
        expect(app.server.requests, contains('sacco_exports_farmer-payouts'));
      });
    }
  }

  testWidgets('A collector sees only collections and sales', (tester) async {
    _setScreen(tester, const Size(320, 640), 2.0);
    final app = await AppUnderTest.open(
      tester,
      'collector',
      '/report-downloads',
      extra: savedHere().cast(),
    );
    final seen = <String, int>{};
    try {
      await _settle(tester);
      for (final t in ['Milk Collections', 'Milk Sales', 'Farmer Payouts']) {
        seen[t] = find.text(t).evaluate().length;
      }
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen, {'Milk Collections': 1, 'Milk Sales': 1, 'Farmer Payouts': 0});
  });

  testWidgets('A statement needs a farmer; the profile fills one in', (
    tester,
  ) async {
    _setScreen(tester, const Size(412, 915), 1.0);
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/members',
      extra: savedHere().cast(),
    );
    app.server.replaced['sacco_members_f1'] = _farmer;
    final seen = <String, Object?>{};
    try {
      // From the list: no farmer chosen yet.
      app.container.read(appRouterProvider).push('/report-downloads');
      await _settle(tester);
      await _tap(tester, find.text('Farmer Statement'));
      await _tap(tester, find.text('Download PDF'));
      seen['asks'] = find.text('Choose a farmer.').evaluate().length;
      Navigator.of(tester.element(find.byType(ReportDownloadSheet))).pop();
      await _settle(tester);

      // From the farmer's profile: the farmer is filled in.
      app.container.read(appRouterProvider).push('/members/f1');
      await _settle(tester);
      await _tap(tester, find.text('Download Statement'));
      seen['farmer'] = find.text('Rudiah Mungayo · 002').evaluate().length;
      await _tap(tester, find.text('Download PDF'));
      await _finishFiles(tester);
      seen['done'] = find.textContaining('Downloaded:').evaluate().length;
      seen['texts'] = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ReportDownloadSheet),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .join(' | ');
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['asks'], 1);
    expect(seen['farmer'], 1);
    expect(seen['done'], 1, reason: '${seen['texts']}');
    expect(app.server.requests, contains('sacco_exports_farmer-statement'));
  });

  testWidgets('The Reports screen links to downloads', (tester) async {
    _setScreen(tester, const Size(320, 640), 1.0);
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/reports',
      extra: savedHere().cast(),
    );
    late int found;
    try {
      await _settle(tester);
      await tester.tap(find.byTooltip('Download reports (PDF or Excel)'));
      await _settle(tester);
      found = find.text('Download Reports').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(found, 1);
  });

  testWidgets('Downloaded reports can be deleted, one or all', (tester) async {
    _setScreen(tester, const Size(320, 640), 2);
    final folder = Directory('${dir.path}/reports')..createSync();
    for (final n in ['a.pdf', 'b.xlsx', 'c.pdf']) {
      File('${folder.path}/$n').writeAsStringSync('x');
    }
    Future<List<String>> left() async => (await tester.runAsync(
      () async =>
          folder.listSync().map((f) => f.uri.pathSegments.last).toList(),
    ))!;

    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/report-downloads',
      extra: savedHere().cast(),
    );
    final seen = <String, Object?>{};
    try {
      await _finishFiles(tester);
      final first = find.text('a.pdf');
      await tester.scrollUntilVisible(
        first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(
        tester,
        find.descendant(
          of: find.ancestor(of: first, matching: find.byType(ListTile)),
          matching: find.byIcon(Icons.adaptive.more),
        ),
      );
      await _tap(tester, find.text('Delete').last);
      seen['ask one'] = find.text('Delete this report?').evaluate().length;
      await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));
      await _finishFiles(tester);
      seen['after one'] = await left();

      await _tap(tester, find.text('Delete all'));
      seen['ask all'] = find
          .text('Delete all downloaded reports?')
          .evaluate()
          .length;
      await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));
      await _finishFiles(tester);
      seen['after all'] = await left();
      await _finishFiles(tester);
      seen['list gone'] = find.text('Delete all').evaluate().length;
    } finally {
      await app.close();
    }
    expect(app.errors, isEmpty, reason: app.errors.join('\n'));
    expect(seen['ask one'], 1);
    expect(seen['after one'], unorderedEquals(['b.xlsx', 'c.pdf']));
    expect(seen['ask all'], 1);
    expect(seen['after all'], isEmpty);
    expect(seen['list gone'], 0);
  });
}
