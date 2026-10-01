/// A report that can be downloaded, as GET /sacco/exports lists it. Only the
/// reports the user's permissions allow are listed.
class ReportSpec {
  final String key;
  final String title;
  final String description;

  /// 'farmer' or 'customer' when one must be chosen; null otherwise.
  final String? needs;

  /// Shows the position today: no period to choose.
  final bool asAt;

  /// Can be limited to farmers of one status (the farmer register).
  final bool statusFilter;

  const ReportSpec({
    required this.key,
    required this.title,
    required this.description,
    this.needs,
    this.asAt = false,
    this.statusFilter = false,
  });

  factory ReportSpec.fromJson(Map<String, dynamic> json) => ReportSpec(
    key: json['key'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    needs: (json['needs'] as String?)?.isEmpty ?? true
        ? null
        : json['needs'] as String,
    asAt: json['as_at'] as bool? ?? false,
    statusFilter: json['status_filter'] as bool? ?? false,
  );

  bool get needsFarmer => needs == 'farmer';
  bool get needsCustomer => needs == 'customer';
}

/// A file format a report comes in.
enum ReportFormat {
  pdf('PDF', 'pdf'),
  excel('Excel', 'xlsx');

  final String label;
  final String query;
  const ReportFormat(this.label, this.query);
}

/// The dates a report covers, both inclusive.
class ReportPeriod {
  final String label;
  final DateTime from;
  final DateTime to;

  const ReportPeriod(this.label, this.from, this.to);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The quick choices, as of [now].
  static List<ReportPeriod> presets(DateTime now) {
    final today = _day(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final lastMonthEnd = DateTime(today.year, today.month, 0);
    return [
      ReportPeriod('This month', DateTime(today.year, today.month, 1), today),
      ReportPeriod(
        'Last month',
        DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
        lastMonthEnd,
      ),
      ReportPeriod('This week', monday, today),
      ReportPeriod('Today', today, today),
    ];
  }

  /// YYYY-MM-DD, as the server takes dates.
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _short(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "1 Oct 2026 – 15 Oct 2026", or one date.
  String get dates =>
      from == to ? _short(from) : '${_short(from)} – ${_short(to)}';
}
