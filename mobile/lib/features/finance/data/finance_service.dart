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
}
