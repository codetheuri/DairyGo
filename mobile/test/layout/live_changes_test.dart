// Records saved on another phone reach this one without pulling to refresh:
// a screen reloads when shown again, and the dashboard every minute.

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/app/router/app_router.dart';
import 'package:dairy_sacco_mobile/core/cache/response_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Kept in memory only (widget tests run on fake time, without real file
/// access), and never trusted without asking, as after a few seconds.
class _MemoryCache extends ResponseCache {
  final _saved = <String, CachedResponse>{};

  _MemoryCache()
    : super(
        () => throw UnsupportedError('memory only'),
        freshFor: Duration.zero,
      );

  @override
  Future<CachedResponse?> read(String key) async => _saved[key];

  @override
  Future<bool> write(String key, Object? data) async {
    final changed = jsonEncode(_saved[key]?.data) != jsonEncode(data);
    _saved[key] = CachedResponse(data, DateTime.now());
    return changed;
  }
}

ResponseCache _cache() => _MemoryCache();

/// The captured sales list with a sale added first, as another phone would.
Object _salesWithNewSale() {
  final fixture =
      jsonDecode(
            File(
              'test/layout/fixtures/admin/sacco_milk-sales.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final body = fixture['body'] as Map<String, dynamic>;
  final sales = (body['data'] as Map<String, dynamic>)['sales'] as List;
  final sale = Map<String, dynamic>.from(sales.first as Map)
    ..['id'] = 'new-sale-from-another-phone'
    ..['buyer_name'] = 'Ndumberi Cooler';
  sales.insert(0, sale);
  return body;
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a sale made on another phone shows when Sales is opened '
      'again', (tester) async {
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/field-operations',
      cache: _cache(),
    );
    final router = app.container.read(appRouterProvider);
    expect(find.text('Mama Njeri Hotel'), findsWidgets);
    expect(find.text('Ndumberi Cooler'), findsNothing);

    router.go('/dashboard');
    await _frames(tester);
    app.server.replaced['sacco_milk-sales'] = _salesWithNewSale();

    router.go('/field-operations');
    await _frames(tester);
    expect(find.text('Ndumberi Cooler'), findsOneWidget);
    expect(find.text('Mama Njeri Hotel'), findsWidgets);
    expect(app.errors, isEmpty);
    await app.close();
  });

  testWidgets('the dashboard reloads every minute only while it shows', (
    tester,
  ) async {
    final app = await AppUnderTest.open(
      tester,
      'admin',
      '/dashboard',
      cache: _cache(),
    );
    final router = app.container.read(appRouterProvider);
    int summaryRequests() =>
        app.server.requests.where((r) => r == 'sacco_dashboard_summary').length;

    final before = summaryRequests();
    await tester.pump(const Duration(minutes: 1));
    await _frames(tester);
    expect(summaryRequests(), greaterThan(before));

    router.go('/customers');
    await _frames(tester);
    final whileAway = summaryRequests();
    await tester.pump(const Duration(minutes: 3));
    await _frames(tester);
    expect(summaryRequests(), whileAway);
    expect(app.errors, isEmpty);
    await app.close();
  });
}
