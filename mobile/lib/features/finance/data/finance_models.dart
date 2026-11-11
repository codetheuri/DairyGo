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

/// Money the Sacco received besides milk sales (interest, rent, items sold).
class OtherIncome {
  final String id;
  final DateTime date;
  final double amount;
  final String payer;
  final String category;
  final String account;
  final String? reference;
  final String? description;
  final bool voided;

  const OtherIncome({
    required this.id,
    required this.date,
    required this.amount,
    required this.payer,
    required this.category,
    required this.account,
    this.reference,
    this.description,
    required this.voided,
  });

  factory OtherIncome.fromJson(Map<String, dynamic> j) => OtherIncome(
    id: j['id'] as String,
    date: _date(j['income_date']) ?? DateTime(2000),
    amount: toDouble(j['amount']),
    payer: j['payer'] as String? ?? '',
    category: j['category_name'] as String? ?? '',
    account: j['account_name'] as String? ?? '',
    reference: j['reference'] as String?,
    description: j['description'] as String?,
    voided: j['voided_at'] != null,
  );
}

/// Other income over a period with totals.
class IncomeList {
  final List<OtherIncome> items;
  final double total;
  final List<NamedAmount> byCategory;

  const IncomeList({
    required this.items,
    required this.total,
    required this.byCategory,
  });

  factory IncomeList.fromJson(Map<String, dynamic> j) => IncomeList(
    items: [
      for (final e in (j['items'] as List?) ?? const [])
        OtherIncome.fromJson(e as Map<String, dynamic>),
    ],
    total: toDouble(j['total']),
    byCategory: NamedAmount.list(j['by_category']),
  );
}

/// Someone the Sacco pays: for bills, and money taken from farmers' pay for
/// them (an insurer, a union), held until it is paid over.
class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final bool isActive;
  final double billsOwed;
  final double held;
  final bool isPayee;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.isActive,
    required this.billsOwed,
    required this.held,
    required this.isPayee,
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String?,
    notes: j['notes'] as String?,
    isActive: j['is_active'] as bool? ?? true,
    billsOwed: toDouble(j['bills_owed']),
    held: toDouble(j['held']),
    isPayee: j['is_payee'] as bool? ?? false,
  );
}

/// The suppliers with what is owed to them.
class SupplierList {
  final List<Supplier> suppliers;
  final double billsOwed;
  final double held;

  const SupplierList(this.suppliers, this.billsOwed, this.held);

  factory SupplierList.fromJson(Map<String, dynamic> j) => SupplierList(
    [
      for (final s in (j['suppliers'] as List?) ?? const [])
        Supplier.fromJson(s as Map<String, dynamic>),
    ],
    toDouble(j['bills_owed']),
    toDouble(j['held']),
  );

  List<Supplier> get active => [
    for (final s in suppliers)
      if (s.isActive) s,
  ];
}

/// Something bought from a supplier, paid later (in parts if need be).
class Bill {
  final String id;
  final String supplierId;
  final String supplier;
  final String category;
  final DateTime date;
  final DateTime? dueDate;
  final double amount;
  final double paid;
  final double unpaid;
  final String? reference;
  final String? description;
  final bool voided;

  const Bill({
    required this.id,
    required this.supplierId,
    required this.supplier,
    required this.category,
    required this.date,
    this.dueDate,
    required this.amount,
    required this.paid,
    required this.unpaid,
    this.reference,
    this.description,
    required this.voided,
  });

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
    id: j['id'] as String,
    supplierId: j['supplier_id'] as String? ?? '',
    supplier: j['supplier_name'] as String? ?? '',
    category: j['category_name'] as String? ?? '',
    date: _date(j['bill_date']) ?? DateTime(2000),
    dueDate: _date(j['due_date']),
    amount: toDouble(j['amount']),
    paid: toDouble(j['paid']),
    unpaid: toDouble(j['unpaid']),
    reference: j['reference'] as String?,
    description: j['description'] as String?,
    voided: j['voided_at'] != null,
  );
}

/// A payment to a supplier: for a bill, or money held paid over.
class SupplierPayment {
  final String id;
  final String kind; // BILL or PAY_OVER
  final String? billId;
  final DateTime date;
  final double amount;
  final String account;
  final String? reference;
  final bool voided;

  const SupplierPayment({
    required this.id,
    required this.kind,
    this.billId,
    required this.date,
    required this.amount,
    required this.account,
    this.reference,
    required this.voided,
  });

  factory SupplierPayment.fromJson(Map<String, dynamic> j) => SupplierPayment(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'BILL',
    billId: j['bill_id'] as String?,
    date: _date(j['payment_date']) ?? DateTime(2000),
    amount: toDouble(j['amount']),
    account: j['account_name'] as String? ?? '',
    reference: j['reference'] as String?,
    voided: j['voided_at'] != null,
  );
}

/// What one pay run took from farmers for a supplier.
class HeldLine {
  final DateTime date;
  final String name;
  final int farmers;
  final double amount;

  const HeldLine(this.date, this.name, this.farmers, this.amount);

  factory HeldLine.fromJson(Map<String, dynamic> j) => HeldLine(
    _date(j['date']) ?? DateTime(2000),
    j['name'] as String? ?? '',
    (j['farmers'] as num?)?.toInt() ?? 0,
    toDouble(j['amount']),
  );
}

/// A supplier with their bills, payments and what was held for them.
class SupplierDetail {
  final Supplier supplier;
  final List<Bill> bills;
  final List<SupplierPayment> payments;
  final List<HeldLine> taken;
  final List<String> deductions;

  const SupplierDetail({
    required this.supplier,
    required this.bills,
    required this.payments,
    required this.taken,
    required this.deductions,
  });

  factory SupplierDetail.fromJson(Map<String, dynamic> j) => SupplierDetail(
    supplier: Supplier.fromJson(j['supplier'] as Map<String, dynamic>),
    bills: [
      for (final b in (j['bills'] as List?) ?? const [])
        Bill.fromJson(b as Map<String, dynamic>),
    ],
    payments: [
      for (final p in (j['payments'] as List?) ?? const [])
        SupplierPayment.fromJson(p as Map<String, dynamic>),
    ],
    taken: [
      for (final t in (j['taken'] as List?) ?? const [])
        HeldLine.fromJson(t as Map<String, dynamic>),
    ],
    deductions: [
      for (final d in (j['deductions'] as List?) ?? const []) d as String,
    ],
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
  final List<NamedAmount> otherIncome;
  final double otherIncomeTotal;

  /// Deductions taken for suppliers in the period: owed to them, not income.
  final List<NamedAmount> heldForOthers;
  final double cash;
  final double receivables;
  final double farmerPayDue;
  final double farmersOwe;
  final double shareCapital;
  final double owedBills;
  final double heldToPayOver;

  /// Payments in or out in the period that name no account, so are in no
  /// cashbook (recorded before every payment named its account).
  final int notInAccount;
  final double notInAccountAmount;

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
    this.otherIncome = const [],
    this.otherIncomeTotal = 0,
    this.heldForOthers = const [],
    required this.cash,
    required this.receivables,
    required this.farmerPayDue,
    required this.farmersOwe,
    required this.shareCapital,
    this.owedBills = 0,
    this.heldToPayOver = 0,
    this.notInAccount = 0,
    this.notInAccountAmount = 0,
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
    otherIncome: NamedAmount.list(j['other_income']),
    otherIncomeTotal: toDouble(j['other_income_total']),
    heldForOthers: NamedAmount.list(j['held_for_others']),
    cash: toDouble(j['cash']),
    receivables: toDouble(j['receivables']),
    farmerPayDue: toDouble(j['farmer_pay_due']),
    farmersOwe: toDouble(j['farmers_owe']),
    shareCapital: toDouble(j['share_capital']),
    owedBills: toDouble(j['owed_bills']),
    heldToPayOver: toDouble(j['held_to_pay_over']),
    notInAccount: (j['not_in_account'] as num?)?.toInt() ?? 0,
    notInAccountAmount: toDouble(j['not_in_account_amount']),
  );

  double get income =>
      milkSales +
      fees.fold(0.0, (s, f) => s + f.amount) +
      farmerCharges +
      otherIncomeTotal;
  double get spending => milkPurchases + expensesTotal;
}

/// An account someone recording money may choose (no balance).
class AccountChoice {
  final String id;
  final String name;
  final String kind;

  const AccountChoice({
    required this.id,
    required this.name,
    required this.kind,
  });

  factory AccountChoice.fromJson(Map<String, dynamic> j) => AccountChoice(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    kind: j['kind'] as String? ?? 'CASH',
  );

  String get kindLabel => switch (kind) {
    'BANK' => 'Bank',
    'MPESA' => 'M-Pesa',
    _ => 'Cash',
  };
}

/// The accounts to choose from and, for each kind, the one money paid that
/// way goes to when none is chosen. The server applies the same default, so
/// leaving it as shown and choosing it give the same result.
class AccountChoices {
  final List<AccountChoice> accounts;
  final Map<String, String> defaults;

  const AccountChoices(this.accounts, this.defaults);

  factory AccountChoices.fromJson(Map<String, dynamic> j) => AccountChoices(
    [
      for (final a in (j['accounts'] as List?) ?? const [])
        AccountChoice.fromJson(a as Map<String, dynamic>),
    ],
    {
      for (final e in ((j['defaults'] as Map?) ?? const {}).entries)
        e.key as String: e.value as String,
    },
  );

  /// The kind of account money paid by [method] goes through.
  static String kindFor(String method) => switch (method.toUpperCase()) {
    'MPESA' => 'MPESA',
    'BANK' || 'BANK_TRANSFER' || 'CHEQUE' => 'BANK',
    _ => 'CASH',
  };

  String? defaultFor(String method) => defaults[kindFor(method)];
}

/// The Sacco's financial year and this and last year's dates.
class FinancialYear {
  final int startMonth;
  final DateTime thisFrom;
  final DateTime thisTo;
  final DateTime lastFrom;
  final DateTime lastTo;

  const FinancialYear({
    required this.startMonth,
    required this.thisFrom,
    required this.thisTo,
    required this.lastFrom,
    required this.lastTo,
  });

  factory FinancialYear.fromJson(Map<String, dynamic> j) => FinancialYear(
    startMonth: (j['start_month'] as num?)?.toInt() ?? 1,
    thisFrom: DateTime.parse(j['this_from'] as String),
    thisTo: DateTime.parse(j['this_to'] as String),
    lastFrom: DateTime.parse(j['last_from'] as String),
    lastTo: DateTime.parse(j['last_to'] as String),
  );

  /// The financial year [day] falls in.
  static ({DateTime from, DateTime to}) of(DateTime day, int startMonth) {
    final year = day.month < startMonth ? day.year - 1 : day.year;
    final from = DateTime(year, startMonth, 1);
    return (from: from, to: DateTime(year + 1, startMonth, 0));
  }

  /// "2026" for a calendar year, else "Jul 2026 – Jun 2027".
  static String label(DateTime from, DateTime to) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (from.month == 1) return 'Financial year ${from.year}';
    return '${m[from.month - 1]} ${from.year} – ${m[to.month - 1]} ${to.year}';
  }
}
