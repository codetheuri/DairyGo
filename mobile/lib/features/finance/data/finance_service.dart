import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'finance_models.dart';

/// Talks to the finance API: accounts, expenses, transfers, cashbooks and
/// the income and expenditure.
class FinanceService {
  final Dio _dio;

  FinanceService(this._dio);

  static const _base = '/api/v1/sacco';

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _period(DateTime from, DateTime to) => {
    'from': iso(from),
    'to': iso(to),
  };

  /// The accounts to choose from when recording money, with the default for
  /// each kind. Open to anyone who records money (no balances).
  Future<AccountChoices> accountChoices() async {
    final data = await apiData(
      () => _dio.get('$_base/cash-accounts/choices'),
      'Could not load the accounts',
    );
    return AccountChoices.fromJson(data);
  }

  Future<FinancialYear> financialYear() async {
    final data = await apiData(
      () => _dio.get('$_base/financial-year'),
      'Could not load the financial year',
    );
    return FinancialYear.fromJson(
      data['financial_year'] as Map<String, dynamic>,
    );
  }

  Future<FinancialYear> setFinancialYear(int startMonth) async {
    final data = await apiData(
      () =>
          _dio.put('$_base/financial-year', data: {'start_month': startMonth}),
      'The financial year could not be changed',
    );
    return FinancialYear.fromJson(
      data['financial_year'] as Map<String, dynamic>,
    );
  }

  Future<CashAccounts> accounts() async {
    final data = await apiData(
      () => _dio.get('$_base/cash-accounts'),
      'Could not load the accounts',
    );
    return CashAccounts([
      for (final a in (data['accounts'] as List?) ?? const [])
        CashAccount.fromJson(a as Map<String, dynamic>),
    ], (data['total'] as num?)?.toDouble() ?? 0);
  }

  /// Creates (id null) or changes an account.
  Future<void> saveAccount(String? id, Map<String, dynamic> body) => apiData(
    () => id == null
        ? _dio.post('$_base/cash-accounts', data: body)
        : _dio.put('$_base/cash-accounts/$id', data: body),
    'The account could not be saved',
  );

  Future<Cashbook> cashbook(String id, DateTime from, DateTime to) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/cash-accounts/$id/cashbook',
        queryParameters: _period(from, to),
      ),
      'Could not load the cashbook',
    );
    return Cashbook.fromJson(data['cashbook'] as Map<String, dynamic>);
  }

  Future<List<ExpenseCategory>> categories() async {
    final data = await apiData(
      () => _dio.get('$_base/expense-categories'),
      'Could not load the categories',
    );
    return [
      for (final c in (data['categories'] as List?) ?? const [])
        ExpenseCategory.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<void> saveCategory(String? id, Map<String, dynamic> body) => apiData(
    () => id == null
        ? _dio.post('$_base/expense-categories', data: body)
        : _dio.put('$_base/expense-categories/$id', data: body),
    'The category could not be saved',
  );

  Future<ExpenseList> expenses(
    DateTime from,
    DateTime to, {
    String? categoryId,
  }) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/expenses',
        queryParameters: {..._period(from, to), 'category_id': ?categoryId},
      ),
      'Could not load the expenses',
    );
    return ExpenseList.fromJson(data);
  }

  Future<void> recordExpense(Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/expenses', data: body),
    'The expense could not be saved',
  );

  Future<void> voidExpense(String id, String reason) => apiData(
    () => _dio.post('$_base/expenses/$id/void', data: {'reason': reason}),
    'The expense could not be voided',
  );

  Future<void> recordTransfer(Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/account-transfers', data: body),
    'The money could not be moved',
  );

  Future<FinanceSummary> summary(DateTime from, DateTime to) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/finance/summary',
        queryParameters: _period(from, to),
      ),
      'Could not load the income and expenditure',
    );
    return FinanceSummary.fromJson(data['summary'] as Map<String, dynamic>);
  }

  // --- other income ---

  Future<List<ExpenseCategory>> incomeCategories() async {
    final data = await apiData(
      () => _dio.get('$_base/income-categories'),
      'Could not load the income categories',
    );
    return [
      for (final c in (data['categories'] as List?) ?? const [])
        ExpenseCategory.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<IncomeList> otherIncome(DateTime from, DateTime to) async {
    final data = await apiData(
      () => _dio.get('$_base/other-income', queryParameters: _period(from, to)),
      'Could not load the other income',
    );
    return IncomeList.fromJson(data);
  }

  Future<void> recordIncome(Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/other-income', data: body),
    'The income could not be saved',
  );

  Future<void> voidIncome(String id, String reason) => apiData(
    () => _dio.post('$_base/other-income/$id/void', data: {'reason': reason}),
    'The income could not be voided',
  );

  // --- suppliers, bills and paying over ---

  Future<SupplierList> suppliers() async {
    final data = await apiData(
      () => _dio.get('$_base/suppliers'),
      'Could not load the suppliers',
    );
    return SupplierList.fromJson(data);
  }

  Future<SupplierDetail> supplier(String id) async {
    final data = await apiData(
      () => _dio.get('$_base/suppliers/$id'),
      'Could not load the supplier',
    );
    return SupplierDetail.fromJson(data);
  }

  /// Creates (id null) or changes a supplier; returns it.
  Future<Supplier> saveSupplier(String? id, Map<String, dynamic> body) async {
    final data = await apiData(
      () => id == null
          ? _dio.post('$_base/suppliers', data: body)
          : _dio.put('$_base/suppliers/$id', data: body),
      'The supplier could not be saved',
    );
    return Supplier.fromJson(data['supplier'] as Map<String, dynamic>);
  }

  Future<void> recordBill(Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/bills', data: body),
    'The bill could not be saved',
  );

  Future<void> voidBill(String id, String reason) => apiData(
    () => _dio.post('$_base/bills/$id/void', data: {'reason': reason}),
    'The bill could not be voided',
  );

  Future<void> payBill(String id, Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/bills/$id/pay', data: body),
    'The payment could not be saved',
  );

  Future<void> payOver(String supplierId, Map<String, dynamic> body) => apiData(
    () => _dio.post('$_base/suppliers/$supplierId/pay-over', data: body),
    'The payment could not be saved',
  );

  Future<void> voidSupplierPayment(String id, String reason) => apiData(
    () => _dio.post(
      '$_base/supplier-payments/$id/void',
      data: {'reason': reason},
    ),
    'The payment could not be voided',
  );

  // --- bank reconciliation ---

  Future<List<BankStatement>> statements(String accountId) async {
    final data = await apiData(
      () => _dio.get('$_base/cash-accounts/$accountId/statements'),
      'Could not load the statements',
    );
    return [
      for (final s in (data['statements'] as List?) ?? const [])
        BankStatement.fromJson(s as Map<String, dynamic>),
    ];
  }

  /// Reads (preview) or imports a statement file.
  Future<StatementImport> importStatement(
    String accountId, {
    required String fileBase64,
    required String fileName,
    bool preview = false,
  }) async {
    final data = await apiData(
      () => _dio.post(
        '$_base/cash-accounts/$accountId/statements',
        data: {'file': fileBase64, 'file_name': fileName, 'preview': preview},
      ),
      'The statement could not be imported',
    );
    return StatementImport.fromJson(data);
  }

  Future<Reconciliation> reconciliation(String statementId) async {
    final data = await apiData(
      () => _dio.get('$_base/bank-statements/$statementId'),
      'Could not load the statement',
    );
    return Reconciliation.fromJson(
      data['reconciliation'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteStatement(String id) => apiData(
    () => _dio.delete('$_base/bank-statements/$id'),
    'The statement could not be removed',
  );

  Future<int> autoMatch(String statementId) async {
    final data = await apiData(
      () => _dio.post('$_base/bank-statements/$statementId/auto-match'),
      'Could not match the statement',
    );
    return (data['matched'] as num?)?.toInt() ?? 0;
  }

  Future<List<BookMovement>> candidates(String lineId) async {
    final data = await apiData(
      () => _dio.get('$_base/bank-statement-lines/$lineId/candidates'),
      'Could not load the cashbook',
    );
    return [
      for (final m in (data['movements'] as List?) ?? const [])
        BookMovement.fromJson(m as Map<String, dynamic>),
    ];
  }

  Future<void> matchLine(String lineId, String key) => apiData(
    () => _dio.post(
      '$_base/bank-statement-lines/$lineId/match',
      data: {'match_key': key},
    ),
    'The line could not be matched',
  );

  Future<void> unmatchLine(String lineId) => apiData(
    () => _dio.post('$_base/bank-statement-lines/$lineId/unmatch'),
    'The line could not be unmatched',
  );
}
