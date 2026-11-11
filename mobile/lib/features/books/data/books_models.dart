// The Sacco's books as the API sends them (see backend docs/books.md):
// whether they have started and agree with the records, the chart of
// accounts, where records post, journals, the trial balance and account
// ledgers.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
DateTime _day(Object? v) => DateTime.parse('$v'.substring(0, 10));

/// The five kinds of account, in chart order.
const accountTypes = ['ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE'];

const accountTypeNames = {
  'ASSET': 'Assets',
  'LIABILITY': 'Liabilities',
  'EQUITY': 'Equity',
  'INCOME': 'Income',
  'EXPENSE': 'Expenses',
};

const accountTypeOne = {
  'ASSET': 'Asset',
  'LIABILITY': 'Liability',
  'EQUITY': 'Equity',
  'INCOME': 'Income',
  'EXPENSE': 'Expense',
};

/// One account kept from records compared with what the records say.
class BooksControl {
  final String name;
  final String accountId;
  final String code;
  final double books;
  final double records;
  final double difference;
  final bool ok;

  const BooksControl({
    required this.name,
    required this.accountId,
    required this.code,
    required this.books,
    required this.records,
    required this.difference,
    required this.ok,
  });

  factory BooksControl.fromJson(Map<String, dynamic> j) => BooksControl(
    name: '${j['name'] ?? ''}',
    accountId: '${j['account_id'] ?? ''}',
    code: '${j['code'] ?? ''}',
    books: _d(j['books']),
    records: _d(j['records']),
    difference: _d(j['difference']),
    ok: j['ok'] == true,
  );
}

/// The books at a glance.
class BooksStatus {
  final bool started;
  final DateTime? startDate;
  final int journals;
  final DateTime? checkedAt;
  final bool balanced;
  final bool agrees;
  final List<BooksControl> controls;
  final double notInAccount;

  const BooksStatus({
    required this.started,
    this.startDate,
    this.journals = 0,
    this.checkedAt,
    this.balanced = true,
    this.agrees = true,
    this.controls = const [],
    this.notInAccount = 0,
  });

  factory BooksStatus.fromJson(Map<String, dynamic> j) => BooksStatus(
    started: j['started'] == true,
    startDate: j['start_date'] == null ? null : _day(j['start_date']),
    journals: (j['journals'] as num?)?.toInt() ?? 0,
    checkedAt: j['checked_at'] == null
        ? null
        : DateTime.tryParse('${j['checked_at']}')?.toLocal(),
    balanced: j['balanced'] != false,
    agrees: j['agrees'] != false,
    controls: [
      for (final c in (j['controls'] as List?) ?? const [])
        BooksControl.fromJson(c as Map<String, dynamic>),
    ],
    notInAccount: _d(j['not_in_account']),
  );
}

/// An account in the chart.
class LedgerAccount {
  final String id;
  final String code;
  final String name;
  final String type;
  final String? description;
  final bool isActive;
  final double balance;
  final bool used;
  final bool kept;
  final String keptBy;

  const LedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.description,
    this.isActive = true,
    this.balance = 0,
    this.used = false,
    this.kept = false,
    this.keptBy = '',
  });

  String get label => '$code  $name';

  factory LedgerAccount.fromJson(Map<String, dynamic> j) => LedgerAccount(
    id: '${j['id'] ?? ''}',
    code: '${j['code'] ?? ''}',
    name: '${j['name'] ?? ''}',
    type: '${j['type'] ?? 'ASSET'}',
    description: j['description'] as String?,
    isActive: j['is_active'] != false,
    balance: _d(j['balance']),
    used: j['used'] == true,
    kept: j['kept_from_records'] == true,
    keptBy: '${j['kept_by'] ?? ''}',
  );
}

/// One kind of record and the account it posts to.
class BooksLink {
  final String key;
  final String group;
  final String name;
  final String detail;
  final String accountId;
  final String accountCode;
  final String accountName;
  final List<String> allowedTypes;

  const BooksLink({
    required this.key,
    required this.group,
    required this.name,
    required this.detail,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.allowedTypes,
  });

  factory BooksLink.fromJson(Map<String, dynamic> j) => BooksLink(
    key: '${j['key'] ?? ''}',
    group: '${j['group'] ?? ''}',
    name: '${j['name'] ?? ''}',
    detail: '${j['detail'] ?? ''}',
    accountId: '${j['account_id'] ?? ''}',
    accountCode: '${j['account_code'] ?? ''}',
    accountName: '${j['account_name'] ?? ''}',
    allowedTypes: [
      for (final t in (j['allowed_types'] as List?) ?? const []) '$t',
    ],
  );
}

const linkGroupNames = {
  'CASH_ACCOUNTS': 'Cash, bank and M-Pesa accounts',
  'EXPENSE_CATEGORIES': 'Expense categories',
  'DEDUCTIONS': 'Deductions from farmers\' pay',
  'RECORDS': 'Customers, farmers and milk',
};

/// One debit or credit in a journal.
class JournalLine {
  final String accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String? memo;

  const JournalLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
    this.memo,
  });

  factory JournalLine.fromJson(Map<String, dynamic> j) => JournalLine(
    accountId: '${j['account_id'] ?? ''}',
    accountCode: '${j['account_code'] ?? ''}',
    accountName: '${j['account_name'] ?? ''}',
    debit: _d(j['debit']),
    credit: _d(j['credit']),
    memo: j['memo'] as String?,
  );
}

/// A journal: from a record (AUTO) or the accountant's own (MANUAL).
class Journal {
  final String id;
  final int number;
  final DateTime date;
  final String kind;
  final String? sourceType;
  final String memo;
  final String? reference;
  final double total;
  final String? reversesId;
  final String? reversedById;
  final int? reversesNumber;
  final int? reversedByNumber;
  final String? reason;
  final String? createdBy;
  final List<JournalLine> lines;

  const Journal({
    required this.id,
    required this.number,
    required this.date,
    required this.kind,
    this.sourceType,
    required this.memo,
    this.reference,
    required this.total,
    this.reversesId,
    this.reversedById,
    this.reversesNumber,
    this.reversedByNumber,
    this.reason,
    this.createdBy,
    this.lines = const [],
  });

  bool get isManual => kind == 'MANUAL';
  String get label => 'J-$number';

  factory Journal.fromJson(Map<String, dynamic> j) => Journal(
    id: '${j['id'] ?? ''}',
    number: (j['number'] as num?)?.toInt() ?? 0,
    date: _day(j['date']),
    kind: '${j['kind'] ?? 'AUTO'}',
    sourceType: j['source_type'] as String?,
    memo: '${j['memo'] ?? ''}',
    reference: j['reference'] as String?,
    total: _d(j['total']),
    reversesId: j['reverses_id'] as String?,
    reversedById: j['reversed_by_id'] as String?,
    reversesNumber: (j['reverses_number'] as num?)?.toInt(),
    reversedByNumber: (j['reversed_by_number'] as num?)?.toInt(),
    reason: j['reason'] as String?,
    createdBy: j['created_by'] as String?,
    lines: [
      for (final l in (j['lines'] as List?) ?? const [])
        JournalLine.fromJson(l as Map<String, dynamic>),
    ],
  );
}

/// Where a journal came from, for people.
const journalSources = {
  'sale': 'Milk sale',
  'customer_payment': 'Customer payment',
  'expense': 'Expense',
  'transfer': 'Money moved between accounts',
  'farmer_entry': 'Farmer\'s account',
  'pay_run': 'Farmers\' pay',
  'cash_account': 'Account opening balance',
  'books': 'Opening balances',
};

/// A page of journals.
class JournalPage {
  final List<Journal> journals;
  final int total;
  final int page;
  final int limit;

  const JournalPage(this.journals, this.total, this.page, this.limit);

  bool get hasMore => page * limit < total;

  factory JournalPage.fromJson(Map<String, dynamic> j) => JournalPage(
    [
      for (final r in (j['journals'] as List?) ?? const [])
        Journal.fromJson(r as Map<String, dynamic>),
    ],
    (j['total'] as num?)?.toInt() ?? 0,
    (j['page'] as num?)?.toInt() ?? 1,
    (j['limit'] as num?)?.toInt() ?? 50,
  );
}

/// One account's line on the trial balance.
class TrialRow {
  final String accountId;
  final String code;
  final String name;
  final String type;
  final double debit;
  final double credit;

  const TrialRow(
    this.accountId,
    this.code,
    this.name,
    this.type,
    this.debit,
    this.credit,
  );

  factory TrialRow.fromJson(Map<String, dynamic> j) => TrialRow(
    '${j['account_id'] ?? ''}',
    '${j['code'] ?? ''}',
    '${j['name'] ?? ''}',
    '${j['type'] ?? ''}',
    _d(j['debit']),
    _d(j['credit']),
  );
}

class TrialBalance {
  final DateTime date;
  final List<TrialRow> rows;
  final double totalDebit;
  final double totalCredit;
  final bool balanced;

  const TrialBalance(
    this.date,
    this.rows,
    this.totalDebit,
    this.totalCredit,
    this.balanced,
  );

  factory TrialBalance.fromJson(Map<String, dynamic> j) => TrialBalance(
    _day(j['date']),
    [
      for (final r in (j['rows'] as List?) ?? const [])
        TrialRow.fromJson(r as Map<String, dynamic>),
    ],
    _d(j['total_debit']),
    _d(j['total_credit']),
    j['balanced'] != false,
  );
}

/// An entry on an account with the balance after it.
class LedgerLine {
  final String journalId;
  final int number;
  final DateTime date;
  final String memo;
  final String? lineMemo;
  final double debit;
  final double credit;
  final double balance;

  const LedgerLine({
    required this.journalId,
    required this.number,
    required this.date,
    required this.memo,
    this.lineMemo,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory LedgerLine.fromJson(Map<String, dynamic> j) => LedgerLine(
    journalId: '${j['journal_id'] ?? ''}',
    number: (j['number'] as num?)?.toInt() ?? 0,
    date: _day(j['date']),
    memo: '${j['memo'] ?? ''}',
    lineMemo: j['line_memo'] as String?,
    debit: _d(j['debit']),
    credit: _d(j['credit']),
    balance: _d(j['balance']),
  );
}

class AccountLedger {
  final LedgerAccount account;
  final double opening;
  final double totalDebit;
  final double totalCredit;
  final double closing;
  final List<LedgerLine> lines;

  const AccountLedger({
    required this.account,
    required this.opening,
    required this.totalDebit,
    required this.totalCredit,
    required this.closing,
    required this.lines,
  });

  factory AccountLedger.fromJson(Map<String, dynamic> j) => AccountLedger(
    account: LedgerAccount.fromJson(j['account'] as Map<String, dynamic>),
    opening: _d(j['opening_balance']),
    totalDebit: _d(j['total_debit']),
    totalCredit: _d(j['total_credit']),
    closing: _d(j['closing_balance']),
    lines: [
      for (final l in (j['lines'] as List?) ?? const [])
        LedgerLine.fromJson(l as Map<String, dynamic>),
    ],
  );
}

/// One account on a statement, in its usual direction, with the earlier
/// period's amount.
class StatementLine {
  final String? accountId;
  final String code;
  final String name;
  final double amount;
  final double previous;

  const StatementLine({
    this.accountId,
    required this.code,
    required this.name,
    required this.amount,
    required this.previous,
  });

  String get label => code.isEmpty ? name : '$code  $name';

  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
    accountId: (j['account_id'] as String?)?.isEmpty ?? true
        ? null
        : j['account_id'] as String,
    code: '${j['code'] ?? ''}',
    name: '${j['name'] ?? ''}',
    amount: _d(j['amount']),
    previous: _d(j['previous']),
  );
}

class StatementSection {
  final String title;
  final List<StatementLine> lines;
  final double total;
  final double previousTotal;

  const StatementSection(
    this.title,
    this.lines,
    this.total,
    this.previousTotal,
  );

  factory StatementSection.fromJson(Map<String, dynamic> j) => StatementSection(
    '${j['title'] ?? ''}',
    [
      for (final l in (j['lines'] as List?) ?? const [])
        StatementLine.fromJson(l as Map<String, dynamic>),
    ],
    _d(j['total']),
    _d(j['previous_total']),
  );
}

/// Income less expenses over a period, beside the period before.
class IncomeStatement {
  final DateTime from;
  final DateTime to;
  final DateTime previousFrom;
  final DateTime previousTo;
  final DateTime startDate;
  final StatementSection income;
  final StatementSection expenses;
  final double surplus;
  final double previousSurplus;

  const IncomeStatement({
    required this.from,
    required this.to,
    required this.previousFrom,
    required this.previousTo,
    required this.startDate,
    required this.income,
    required this.expenses,
    required this.surplus,
    required this.previousSurplus,
  });

  factory IncomeStatement.fromJson(Map<String, dynamic> j) => IncomeStatement(
    from: _day(j['from_date']),
    to: _day(j['to_date']),
    previousFrom: _day(j['previous_from']),
    previousTo: _day(j['previous_to']),
    startDate: _day(j['books_start_date']),
    income: StatementSection.fromJson(j['income'] as Map<String, dynamic>),
    expenses: StatementSection.fromJson(j['expenses'] as Map<String, dynamic>),
    surplus: _d(j['surplus']),
    previousSurplus: _d(j['previous_surplus']),
  );
}

/// What the Sacco owns and owes on a day, beside another day.
class BalanceSheet {
  final DateTime date;
  final DateTime previousDate;
  final StatementSection assets;
  final StatementSection liabilities;
  final StatementSection equity;
  final double liabilitiesAndEquity;
  final double previousLiabilitiesAndEquity;
  final bool balanced;

  const BalanceSheet({
    required this.date,
    required this.previousDate,
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.liabilitiesAndEquity,
    required this.previousLiabilitiesAndEquity,
    required this.balanced,
  });

  factory BalanceSheet.fromJson(Map<String, dynamic> j) => BalanceSheet(
    date: _day(j['date']),
    previousDate: _day(j['previous_date']),
    assets: StatementSection.fromJson(j['assets'] as Map<String, dynamic>),
    liabilities: StatementSection.fromJson(
      j['liabilities'] as Map<String, dynamic>,
    ),
    equity: StatementSection.fromJson(j['equity'] as Map<String, dynamic>),
    liabilitiesAndEquity: _d(j['liabilities_and_equity']),
    previousLiabilitiesAndEquity: _d(j['previous_liabilities_and_equity']),
    balanced: j['balanced'] != false,
  );
}
