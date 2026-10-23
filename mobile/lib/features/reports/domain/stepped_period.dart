import '../../report_downloads/data/report_spec.dart';

/// How a report period steps: a day, a week (Monday to Sunday), a month, or
/// dates chosen on a calendar.
enum PeriodKind {
  day('Day'),
  week('Week'),
  month('Month'),
  range('Dates');

  final String label;
  const PeriodKind(this.label);
}

/// The dates the Reports screen covers, both inclusive, and how the arrows
/// step through them.
class SteppedPeriod {
  final PeriodKind kind;
  final DateTime from;
  final DateTime to;

  const SteppedPeriod._(this.kind, this.from, this.to);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The [kind] of period that holds [anchor]. A range starts as that one day.
  factory SteppedPeriod.of(PeriodKind kind, DateTime anchor) {
    final d = _day(anchor);
    switch (kind) {
      case PeriodKind.day:
      case PeriodKind.range:
        return SteppedPeriod._(kind, d, d);
      case PeriodKind.week:
        final monday = d.subtract(Duration(days: d.weekday - 1));
        return SteppedPeriod._(
          kind,
          monday,
          monday.add(const Duration(days: 6)),
        );
      case PeriodKind.month:
        return SteppedPeriod._(
          kind,
          DateTime(d.year, d.month, 1),
          DateTime(d.year, d.month + 1, 0),
        );
    }
  }

  /// Chosen dates, in either order.
  factory SteppedPeriod.range(DateTime a, DateTime b) {
    final x = _day(a), y = _day(b);
    return x.isAfter(y)
        ? SteppedPeriod._(PeriodKind.range, y, x)
        : SteppedPeriod._(PeriodKind.range, x, y);
  }

  /// This month, as the screen opens.
  factory SteppedPeriod.thisMonth([DateTime? now]) =>
      SteppedPeriod.of(PeriodKind.month, now ?? DateTime.now());

  /// The period [n] steps later (earlier when negative). Chosen dates move by
  /// their own length.
  SteppedPeriod step(int n) {
    switch (kind) {
      case PeriodKind.day:
        return SteppedPeriod.of(
          kind,
          DateTime(from.year, from.month, from.day + n),
        );
      case PeriodKind.week:
        return SteppedPeriod.of(
          kind,
          DateTime(from.year, from.month, from.day + 7 * n),
        );
      case PeriodKind.month:
        return SteppedPeriod.of(kind, DateTime(from.year, from.month + n, 1));
      case PeriodKind.range:
        final days = to.difference(from).inDays + 1;
        return SteppedPeriod._(
          kind,
          DateTime(from.year, from.month, from.day + days * n),
          DateTime(to.year, to.month, to.day + days * n),
        );
    }
  }

  /// Whether the next period has begun by [now]; the future holds no milk.
  bool canStepForward([DateTime? now]) =>
      !step(1).from.isAfter(_day(now ?? DateTime.now()));

  /// One day only.
  bool get isOneDay => from == to;

  String get fromDate => ReportPeriod.iso(from);
  String get toDate => ReportPeriod.iso(to);

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _short(DateTime d) =>
      '${d.day} ${_months[d.month - 1].substring(0, 3)}';

  /// "Fri 24 Oct 2026", "20 – 26 Oct 2026", "October 2026", "3 Sep – 18 Oct 2026".
  String get label {
    if (kind == PeriodKind.month) {
      return '${_months[from.month - 1]} ${from.year}';
    }
    if (isOneDay) {
      return '${_weekdays[from.weekday - 1]} ${_short(from)} ${from.year}';
    }
    if (from.year != to.year) {
      return '${_short(from)} ${from.year} – ${_short(to)} ${to.year}';
    }
    if (from.month == to.month) {
      return '${from.day} – ${_short(to)} ${to.year}';
    }
    return '${_short(from)} – ${_short(to)} ${to.year}';
  }

  @override
  bool operator ==(Object other) =>
      other is SteppedPeriod &&
      other.kind == kind &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, from, to);
}
