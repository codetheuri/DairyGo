import '../../../core/utils/money.dart';

DateTime? _date(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

/// A rule for something taken from farmers' pay (shares, a fee…).
class DeductionType {
  final String id;
  final String name;
  final String? description;
  final String method; // FIXED, PERCENT, PER_LITRE, TIERED
  final String base; // GROSS, NET
  final double amount;
  final List<FeeBand> tiers;
  final String
  frequency; // EVERY_RUN, ONCE_PER_MEMBER, ONCE_PER_YEAR, UNTIL_TARGET
  final double? target;
  final String appliesTo; // ALL, ENROLLED
  final int priority;
  final bool isSavings;
  final bool isActive;

  const DeductionType({
    required this.id,
    required this.name,
    this.description,
    required this.method,
    required this.base,
    required this.amount,
    this.tiers = const [],
    required this.frequency,
    this.target,
    required this.appliesTo,
    required this.priority,
    required this.isSavings,
    required this.isActive,
  });

  factory DeductionType.fromJson(Map<String, dynamic> j) => DeductionType(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String?,
    method: j['method'] as String? ?? 'FIXED',
    base: j['base'] as String? ?? 'GROSS',
    amount: toDouble(j['amount']),
    tiers: [
      for (final t in (j['tiers'] as List?) ?? const [])
        FeeBand.fromJson(t as Map<String, dynamic>),
    ],
    frequency: j['frequency'] as String? ?? 'EVERY_RUN',
    target: j['target_amount'] == null ? null : toDouble(j['target_amount']),
    appliesTo: j['applies_to'] as String? ?? 'ALL',
    priority: (j['priority'] as num?)?.toInt() ?? 50,
    isSavings: j['is_savings'] as bool? ?? false,
    isActive: j['is_active'] as bool? ?? false,
  );

  /// "KES 500", "2% of milk", "KES 1.50 a litre", "By amount sent".
  String get howMuch => switch (method) {
    'PERCENT' =>
      '${thousands(amount)}% of ${base == 'NET' ? 'the pay' : 'the milk'}',
    'PER_LITRE' => '${kes(amount)} a litre',
    'TIERED' =>
      tiers.isEmpty
          ? 'Fee bands not set'
          : 'By amount sent (${tiers.length} bands)',
    _ => kes(amount, cents: amount != amount.roundToDouble()),
  };

  /// "Every pay run", "Once", "Once a year", "Until KES 5,000".
  String get howOften => switch (frequency) {
    'ONCE_PER_MEMBER' => 'Once per farmer',
    'ONCE_PER_YEAR' => 'Once a year',
    'UNTIL_TARGET' =>
      target == null
          ? 'Until a target (not set)'
          : 'Until ${kes(target!, cents: false)} is paid',
    _ => 'Every pay run',
  };
}

/// One band of a tiered fee: amounts up to [upTo] pay [fee].
class FeeBand {
  final double? upTo;
  final double fee;

  const FeeBand({this.upTo, required this.fee});

  factory FeeBand.fromJson(Map<String, dynamic> j) => FeeBand(
    upTo: j['up_to'] == null ? null : toDouble(j['up_to']),
    fee: toDouble(j['fee']),
  );

  Map<String, dynamic> toJson() => {
    if (upTo != null) 'up_to': upTo,
    'fee': fee,
  };
}

/// How a deduction applies to one farmer.
class FarmerDeduction {
  final DeductionType type;
  final bool applies;
  final double amount;
  final double? target;
  final double paidSoFar;
  final bool hasOwnSetting;

  const FarmerDeduction({
    required this.type,
    required this.applies,
    required this.amount,
    this.target,
    required this.paidSoFar,
    required this.hasOwnSetting,
  });

  factory FarmerDeduction.fromJson(Map<String, dynamic> j) => FarmerDeduction(
    type: DeductionType.fromJson(j['deduction'] as Map<String, dynamic>),
    applies: j['applies'] as bool? ?? false,
    amount: toDouble(j['amount']),
    target: j['target_amount'] == null ? null : toDouble(j['target_amount']),
    paidSoFar: toDouble(j['paid_so_far']),
    hasOwnSetting: j['farmer_setting'] != null,
  );
}

/// One entry on a farmer's account.
class AccountEntry {
  final String id;
  final String kind; // MILK, ADVANCE, CHARGE, ADJUSTMENT, DEDUCTION, PAYOUT
  final DateTime date;
  final double amount;
  final String description;
  final String? reference;
  final bool settled;
  final bool voided;
  final double balance;

  const AccountEntry({
    required this.id,
    required this.kind,
    required this.date,
    required this.amount,
    required this.description,
    this.reference,
    required this.settled,
    required this.voided,
    required this.balance,
  });

  factory AccountEntry.fromJson(Map<String, dynamic> j) => AccountEntry(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? '',
    date: _date(j['entry_date']) ?? DateTime(2000),
    amount: toDouble(j['amount']),
    description: j['description'] as String? ?? '',
    reference: j['reference'] as String?,
    settled: j['pay_run_id'] != null,
    voided: j['voided_at'] != null,
    balance: toDouble(j['balance']),
  );

  /// Advances, charges and adjustments a pay run has not settled can be voided.
  bool get canVoid =>
      !settled &&
      !voided &&
      (kind == 'ADVANCE' || kind == 'CHARGE' || kind == 'ADJUSTMENT');

  String get kindLabel => switch (kind) {
    'MILK' => 'Milk',
    'ADVANCE' => 'Advance',
    'CHARGE' => 'Charge',
    'ADJUSTMENT' => 'Adjustment',
    'DEDUCTION' => 'Deduction',
    'PAYOUT' => 'Paid',
    _ => kind,
  };
}

/// A farmer's account: statement and where it stands now.
class FarmerAccount {
  final double opening;
  final double closing;
  final List<AccountEntry> lines;
  final double balance;
  final double shares;
  final double openAdvances;

  const FarmerAccount({
    required this.opening,
    required this.closing,
    required this.lines,
    required this.balance,
    required this.shares,
    required this.openAdvances,
  });

  factory FarmerAccount.fromJson(Map<String, dynamic> j) => FarmerAccount(
    opening: toDouble(j['opening_balance']),
    closing: toDouble(j['closing_balance']),
    lines: [
      for (final l in (j['lines'] as List?) ?? const [])
        AccountEntry.fromJson(l as Map<String, dynamic>),
    ],
    balance: toDouble(j['balance']),
    shares: toDouble(j['share_balance']),
    openAdvances: toDouble(j['open_advances']),
  );
}

/// What an admin sees before giving an advance.
class AdvanceInfo {
  final double milkSoFar;
  final double litresSoFar;
  final double taken;
  final double? limit;
  final int? milkPercent;
  final double? milkAllows;
  final int? fromDay;

  /// Why no advance can be given today; null when advances are open.
  final String? closed;
  final double? available;
  final double balance;

  const AdvanceInfo({
    required this.milkSoFar,
    required this.litresSoFar,
    required this.taken,
    this.limit,
    this.milkPercent,
    this.milkAllows,
    this.fromDay,
    this.closed,
    this.available,
    required this.balance,
  });

  factory AdvanceInfo.fromJson(Map<String, dynamic> j) => AdvanceInfo(
    milkSoFar: toDouble(j['milk_value_so_far']),
    litresSoFar: toDouble(j['litres_so_far']),
    taken: toDouble(j['advances_taken']),
    limit: j['limit'] == null ? null : toDouble(j['limit']),
    milkPercent: (j['milk_percent'] as num?)?.toInt(),
    milkAllows: j['milk_allows'] == null ? null : toDouble(j['milk_allows']),
    fromDay: (j['from_day'] as num?)?.toInt(),
    closed: j['closed'] as String?,
    available: j['available'] == null ? null : toDouble(j['available']),
    balance: toDouble(j['balance']),
  );
}

/// A pay run: every farmer's pay for a period.
class PayRun {
  final String id;
  final DateTime from;
  final DateTime to;
  final String status; // DRAFT, APPROVED, PAID, CANCELLED
  final int farmers;
  final double litres;
  final double gross;
  final double deductions;
  final double net;
  final double paid;
  final int paidCount;

  const PayRun({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
    required this.farmers,
    required this.litres,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.paid,
    required this.paidCount,
  });

  factory PayRun.fromJson(Map<String, dynamic> j) => PayRun(
    id: j['id'] as String,
    from: _date(j['from_date']) ?? DateTime(2000),
    to: _date(j['to_date']) ?? DateTime(2000),
    status: j['status'] as String? ?? 'DRAFT',
    farmers: (j['farmers'] as num?)?.toInt() ?? 0,
    litres: toDouble(j['total_litres']),
    gross: toDouble(j['total_gross']),
    deductions: toDouble(j['total_deductions']),
    net: toDouble(j['total_net']),
    paid: toDouble(j['total_paid']),
    paidCount: (j['paid_count'] as num?)?.toInt() ?? 0,
  );

  bool get isDraft => status == 'DRAFT';
  bool get isApproved => status == 'APPROVED';
  bool get isPaid => status == 'PAID';

  String get statusLabel => switch (status) {
    'DRAFT' => 'Draft',
    'APPROVED' => 'Approved',
    'PAID' => 'Paid',
    'CANCELLED' => 'Cancelled',
    _ => status,
  };
}

/// One deduction on a farmer's pay.
class PayItem {
  final String name;
  final double amount;
  final bool savings;

  const PayItem({
    required this.name,
    required this.amount,
    required this.savings,
  });

  factory PayItem.fromJson(Map<String, dynamic> j) => PayItem(
    name: j['name'] as String? ?? '',
    amount: toDouble(j['amount']),
    savings: j['savings'] as bool? ?? false,
  );
}

/// One farmer's pay in a run.
class PayLine {
  final String id;
  final String memberId;
  final String number;
  final String name;
  final String phone;
  final String? mpesa;
  final String? bank;
  final String? bankAccount;
  final double litres;
  final double gross;
  final double opening;
  final double entries;
  final double deductions;
  final double net;
  final double closing;
  final List<PayItem> items;
  final DateTime? paidAt;
  final String? paidMethod;
  final String? paidReference;

  const PayLine({
    required this.id,
    required this.memberId,
    required this.number,
    required this.name,
    required this.phone,
    this.mpesa,
    this.bank,
    this.bankAccount,
    required this.litres,
    required this.gross,
    required this.opening,
    required this.entries,
    required this.deductions,
    required this.net,
    required this.closing,
    required this.items,
    this.paidAt,
    this.paidMethod,
    this.paidReference,
  });

  factory PayLine.fromJson(Map<String, dynamic> j) => PayLine(
    id: j['id'] as String,
    memberId: j['member_id'] as String? ?? '',
    number: j['membership_number'] as String? ?? '',
    name: j['farmer_name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    mpesa: j['mpesa_number'] as String?,
    bank: j['bank_name'] as String?,
    bankAccount: j['bank_account_number'] as String?,
    litres: toDouble(j['litres']),
    gross: toDouble(j['gross']),
    opening: toDouble(j['opening_balance']),
    entries: toDouble(j['advances_and_charges']),
    deductions: toDouble(j['total_deductions']),
    net: toDouble(j['net']),
    closing: toDouble(j['closing_balance']),
    items: [
      for (final i in (j['deductions'] as List?) ?? const [])
        PayItem.fromJson(i as Map<String, dynamic>),
    ],
    paidAt: _date(j['paid_at']),
    paidMethod: j['paid_method'] as String?,
    paidReference: j['paid_reference'] as String?,
  );

  bool get isPaid => paidAt != null;
  bool get toPay => !isPaid && net > 0;

  String get paidLabel => switch (paidMethod) {
    'MPESA' => 'M-Pesa',
    'BANK_TRANSFER' => 'Bank',
    'CHEQUE' => 'Cheque',
    'CASH' => 'Cash',
    _ => '',
  };
}

/// A pay run with its farmers.
class PayRunDetail {
  final PayRun run;
  final List<PayLine> lines;

  const PayRunDetail({required this.run, required this.lines});

  factory PayRunDetail.fromJson(Map<String, dynamic> j) => PayRunDetail(
    run: PayRun.fromJson(j['pay_run'] as Map<String, dynamic>),
    lines: [
      for (final l in (j['lines'] as List?) ?? const [])
        PayLine.fromJson(l as Map<String, dynamic>),
    ],
  );
}

/// The pay runs and the period the next one should cover.
class PayRunList {
  final List<PayRun> runs;
  final DateTime nextFrom;
  final DateTime nextTo;

  const PayRunList({
    required this.runs,
    required this.nextFrom,
    required this.nextTo,
  });

  factory PayRunList.fromJson(Map<String, dynamic> j) {
    final next = (j['next_period'] as Map?) ?? const {};
    return PayRunList(
      runs: [
        for (final r in (j['pay_runs'] as List?) ?? const [])
          PayRun.fromJson(r as Map<String, dynamic>),
      ],
      nextFrom: _date(next['from_date']) ?? DateTime.now(),
      nextTo: _date(next['to_date']) ?? DateTime.now(),
    );
  }
}
