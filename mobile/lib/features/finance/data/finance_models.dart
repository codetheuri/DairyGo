import '../../../core/utils/money.dart';

DateTime? _date(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

/// A place the Sacco keeps money: petty cash, a bank account, M-Pesa.
class CashAccount {
  final String id;
  final String name;
  final String kind; // CASH, BANK, MPESA
  final String? number;
  final double openingBalance;
  final DateTime openingDate;
  final bool isActive;
  final double balance;

  const CashAccount({
    required this.id,
    required this.name,
    required this.kind,
    this.number,
    required this.openingBalance,
    required this.openingDate,
    required this.isActive,
    required this.balance,
  });

  factory CashAccount.fromJson(Map<String, dynamic> j) => CashAccount(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    kind: j['kind'] as String? ?? 'CASH',
    number: j['account_number'] as String?,
    openingBalance: toDouble(j['opening_balance']),
    openingDate: _date(j['opening_date']) ?? DateTime.now(),
    isActive: j['is_active'] as bool? ?? true,
    balance: toDouble(j['balance']),
  );

  String get kindLabel => switch (kind) {
    'BANK' => 'Bank',
    'MPESA' => 'M-Pesa',
    _ => 'Cash',
  };
}

/// The Sacco's accounts and the money in all of them.
class CashAccounts {
  final List<CashAccount> accounts;
  final double total;

  const CashAccounts(this.accounts, this.total);

  List<CashAccount> get active => [
    for (final a in accounts)
      if (a.isActive) a,
  ];
}

/// A group of expenses.
class ExpenseCategory {
  final String id;
  final String name;
  final bool isActive;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    isActive: j['is_active'] as bool? ?? true,
  );
}

/// Money the Sacco spent.
class Expense {
  final String id;
  final DateTime date;
  final double amount;
  final String payee;
  final String category;
  final String account;
  final String? reference;
  final String? description;
  final bool voided;

  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.payee,
    required this.category,
    required this.account,
    this.reference,
    this.description,
    required this.voided,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    date: _date(j['expense_date']) ?? DateTime(2000),
    amount: toDouble(j['amount']),
    payee: j['payee'] as String? ?? '',
    category: j['category_name'] as String? ?? '',
    account: j['account_name'] as String? ?? '',
    reference: j['reference'] as String?,
    description: j['description'] as String?,
    voided: j['voided_at'] != null,
  );
}

/// An amount with a label.
class NamedAmount {
  final String name;
  final double amount;

  const NamedAmount(this.name, this.amount);

  factory NamedAmount.fromJson(Map<String, dynamic> j) =>
      NamedAmount(j['name'] as String? ?? '', toDouble(j['amount']));

  static List<NamedAmount> list(Object? v) => [
    for (final e in (v as List?) ?? const [])
      NamedAmount.fromJson(e as Map<String, dynamic>),
  ];
}

/// Expenses over a period with totals.
class ExpenseList {
  final List<Expense> expenses;
  final double total;
  final List<NamedAmount> byCategory;

  const ExpenseList({
    required this.expenses,
    required this.total,
    required this.byCategory,
  });

  factory ExpenseList.fromJson(Map<String, dynamic> j) => ExpenseList(
    expenses: [
      for (final e in (j['expenses'] as List?) ?? const [])
        Expense.fromJson(e as Map<String, dynamic>),
    ],
    total: toDouble(j['total']),
    byCategory: NamedAmount.list(j['by_category']),
  );
}

/// One movement in an account's cashbook.
class CashbookLine {
  final String source;
  final DateTime date;
  final String description;
  final String? reference;
  final double moneyIn;
  final double moneyOut;
  final double balance;

  const CashbookLine({
    required this.source,
    required this.date,
    required this.description,
    this.reference,
    required this.moneyIn,
    required this.moneyOut,
    required this.balance,
  });

  factory CashbookLine.fromJson(Map<String, dynamic> j) => CashbookLine(
    source: j['source'] as String? ?? '',
    date: _date(j['date']) ?? DateTime(2000),
    description: j['description'] as String? ?? '',
    reference: j['reference'] as String?,
    moneyIn: toDouble(j['in']),
    moneyOut: toDouble(j['out']),
    balance: toDouble(j['balance']),
  );
}

/// An account's money in and out over a period.
class Cashbook {
  final CashAccount account;
  final double opening;
  final double totalIn;
  final double totalOut;
  final double closing;
  final List<CashbookLine> lines;

  const Cashbook({
    required this.account,
    required this.opening,
    required this.totalIn,
    required this.totalOut,
    required this.closing,
    required this.lines,
  });

  factory Cashbook.fromJson(Map<String, dynamic> j) => Cashbook(
    account: CashAccount.fromJson(j['account'] as Map<String, dynamic>),
    opening: toDouble(j['opening_balance']),
    totalIn: toDouble(j['total_in']),
    totalOut: toDouble(j['total_out']),
    closing: toDouble(j['closing_balance']),
    lines: [
      for (final l in (j['lines'] as List?) ?? const [])
        CashbookLine.fromJson(l as Map<String, dynamic>),
    ],
  );
}

/// Income and expenditure for a period, and where the Sacco stands now.
class FinanceSummary {
  final double milkSales;
  final double milkPurchases;
  final double grossMargin;
  final List<NamedAmount> fees;
  final double farmerCharges;
  final List<NamedAmount> expenses;
  final double expensesTotal;
  final double surplus;
  final List<NamedAmount> sharesRaised;
  final double cash;
  final double receivables;
  final double farmerPayDue;
  final double farmersOwe;
  final double shareCapital;

  const FinanceSummary({
    required this.milkSales,
    required this.milkPurchases,
    required this.grossMargin,
    required this.fees,
    required this.farmerCharges,
    required this.expenses,
    required this.expensesTotal,
    required this.surplus,
    required this.sharesRaised,
    required this.cash,
    required this.receivables,
    required this.farmerPayDue,
    required this.farmersOwe,
    required this.shareCapital,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> j) => FinanceSummary(
    milkSales: toDouble(j['milk_sales']),
    milkPurchases: toDouble(j['milk_purchases']),
    grossMargin: toDouble(j['gross_margin']),
    fees: NamedAmount.list(j['fees']),
    farmerCharges: toDouble(j['farmer_charges']),
    expenses: NamedAmount.list(j['expenses']),
    expensesTotal: toDouble(j['expenses_total']),
    surplus: toDouble(j['surplus']),
    sharesRaised: NamedAmount.list(j['shares_raised']),
    cash: toDouble(j['cash']),
    receivables: toDouble(j['receivables']),
    farmerPayDue: toDouble(j['farmer_pay_due']),
    farmersOwe: toDouble(j['farmers_owe']),
    shareCapital: toDouble(j['share_capital']),
  );

  double get income =>
      milkSales + fees.fold(0.0, (s, f) => s + f.amount) + farmerCharges;
  double get spending => milkPurchases + expensesTotal;
}
