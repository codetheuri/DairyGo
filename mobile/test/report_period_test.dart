// How the Reports period steps: days, Monday-to-Sunday weeks, months and
// chosen dates, and its label.
//
//   flutter test test/report_period_test.dart

import 'package:dairy_sacco_mobile/features/reports/domain/stepped_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fri = DateTime(2026, 10, 23, 15, 30);

  test('a day', () {
    final p = SteppedPeriod.of(PeriodKind.day, fri);
    expect(
      [p.fromDate, p.toDate, p.label],
      ['2026-10-23', '2026-10-23', 'Fri 23 Oct 2026'],
    );
    expect(p.step(-1).label, 'Thu 22 Oct 2026');
    expect(p.step(9).fromDate, '2026-11-01');
  });

  test('a week runs Monday to Sunday', () {
    final p = SteppedPeriod.of(PeriodKind.week, fri);
    expect(
      [p.fromDate, p.toDate, p.label],
      ['2026-10-19', '2026-10-25', '19 – 25 Oct 2026'],
    );
    expect(p.step(-3).label, '28 Sep – 4 Oct 2026');
  });

  test('a month, across the year end', () {
    final p = SteppedPeriod.of(PeriodKind.month, fri);
    expect(
      [p.fromDate, p.toDate, p.label],
      ['2026-10-01', '2026-10-31', 'October 2026'],
    );
    expect(p.step(3).toDate, '2027-01-31');
    expect(
      SteppedPeriod.of(PeriodKind.month, DateTime(2028, 2, 10)).toDate,
      '2028-02-29',
    );
  });

  test('chosen dates move by their length and keep their order', () {
    final p = SteppedPeriod.range(
      DateTime(2026, 10, 10),
      DateTime(2026, 10, 1),
    );
    expect([p.fromDate, p.toDate], ['2026-10-01', '2026-10-10']);
    expect(
      [p.step(1).fromDate, p.step(1).toDate],
      ['2026-10-11', '2026-10-20'],
    );
    expect(
      SteppedPeriod.range(DateTime(2026, 12, 28), DateTime(2027, 1, 3)).label,
      '28 Dec 2026 – 3 Jan 2027',
    );
  });

  test('no stepping into the future', () {
    final today = SteppedPeriod.of(PeriodKind.day, fri);
    expect(today.canStepForward(fri), isFalse);
    expect(today.step(-1).canStepForward(fri), isTrue);
    expect(
      SteppedPeriod.of(PeriodKind.month, fri).canStepForward(fri),
      isFalse,
    );
  });
}
