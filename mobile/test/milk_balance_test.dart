import 'package:dairy_sacco_mobile/core/utils/milk_balance.dart';
import 'package:dairy_sacco_mobile/core/widgets/balance_badge.dart';
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

  // Milk not yet sold is usually still in the can, so it is never "missing".
  test('balance labels are plain words', () {
    expect(BalanceBadge.labelFor(150, 'MISSING'), '150.0 L not sold yet');
    expect(
      BalanceBadge.labelFor(-20, 'OVERSOLD'),
      '20.0 L sold over collected',
    );
    expect(BalanceBadge.labelFor(0, 'BALANCED'), 'Balanced');
  });

  // Collected 142.5 L, sold 312 L: never "-169.5 L not sold yet".
  test('the difference is named by its sign and never negative', () {
    final over = BalanceFigure.of(-169.5);
    expect(over.label, 'Sold over collected');
    expect(over.short, 'Oversold');
    expect(over.litres, 169.5);
    expect(over.sentence, '169.5 L more sold than collected');
    final left = BalanceFigure.of(12);
    expect(left.label, 'Not sold yet');
    expect(left.litres, 12);
    expect(left.sentence, '12.0 L not sold yet');
  });
}
