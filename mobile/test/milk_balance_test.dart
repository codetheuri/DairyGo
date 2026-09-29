import 'package:dairy_sacco_mobile/core/utils/milk_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The same cases as the server's pkg/reconcile tests.
  test('milk balance matches the server rule', () {
    MilkBalance b(double c, double s, double sp, double a) =>
        MilkBalance.compute(
          collected: c,
          sold: s,
          spoiled: sp,
          allowanceLitres: a,
        );

    expect(b(100, 90, 10, 0).status, 'BALANCED');
    expect(b(100, 80, 10, 0).status, 'MISSING');
    expect(b(100, 80, 10, 0).unaccountedLitres, 10);
    expect(b(100, 95, 10, 0).status, 'OVERSOLD');
    expect(b(100, 95, 10, 0).unaccountedLitres, -5);
    expect(b(100, 88, 10, 2).status, 'BALANCED', reason: 'within tolerance');
    expect(b(100, 87.9, 10, 2).status, 'MISSING');
    expect(b(10.1, 10, 0, 0.1).status, 'BALANCED', reason: 'rounding');
    expect(
      b(0, 5, 0, -1).status,
      'OVERSOLD',
      reason: 'negative allowance is 0',
    );
  });
}
