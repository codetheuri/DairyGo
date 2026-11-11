import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/finance_models.dart';
import '../data/finance_service.dart';

final financeServiceProvider = Provider<FinanceService>(
  (ref) => FinanceService(ref.watch(dioClientProvider)),
);

final cashAccountsProvider = FutureProvider.autoDispose<CashAccounts>(
  (ref) => ref.watch(financeServiceProvider).accounts(),
);

final accountChoicesProvider = FutureProvider.autoDispose<AccountChoices>(
  (ref) => ref.watch(financeServiceProvider).accountChoices(),
);

final financialYearProvider = FutureProvider.autoDispose<FinancialYear>(
  (ref) => ref.watch(financeServiceProvider).financialYear(),
);

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>(
      (ref) => ref.watch(financeServiceProvider).categories(),
    );

/// A month: the first day and the last day (or today for this month).
typedef Month = ({DateTime from, DateTime to});

Month monthOf(DateTime day) {
  final from = DateTime(day.year, day.month, 1);
  final end = DateTime(day.year, day.month + 1, 0);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return (from: from, to: end.isAfter(today) ? today : end);
}

final expensesProvider = FutureProvider.autoDispose
    .family<ExpenseList, ({Month month, String? categoryId})>(
      (ref, q) => ref
          .watch(financeServiceProvider)
          .expenses(q.month.from, q.month.to, categoryId: q.categoryId),
    );

final cashbookProvider = FutureProvider.autoDispose
    .family<Cashbook, ({String accountId, Month month})>(
      (ref, q) => ref
          .watch(financeServiceProvider)
          .cashbook(q.accountId, q.month.from, q.month.to),
    );

final financeSummaryProvider = FutureProvider.autoDispose
    .family<FinanceSummary, Month>(
      (ref, m) => ref.watch(financeServiceProvider).summary(m.from, m.to),
    );

final incomeCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>(
      (ref) => ref.watch(financeServiceProvider).incomeCategories(),
    );

final otherIncomeProvider = FutureProvider.autoDispose
    .family<IncomeList, Month>(
      (ref, m) => ref.watch(financeServiceProvider).otherIncome(m.from, m.to),
    );

final suppliersProvider = FutureProvider.autoDispose<SupplierList>(
  (ref) => ref.watch(financeServiceProvider).suppliers(),
);

final supplierProvider = FutureProvider.autoDispose
    .family<SupplierDetail, String>(
      (ref, id) => ref.watch(financeServiceProvider).supplier(id),
    );

/// After money moves: everything that shows it.
void refreshMoney(WidgetRef ref) {
  ref.invalidate(cashAccountsProvider);
  ref.invalidate(cashbookProvider);
  ref.invalidate(financeSummaryProvider);
  ref.invalidate(expensesProvider);
  ref.invalidate(otherIncomeProvider);
  ref.invalidate(suppliersProvider);
  ref.invalidate(supplierProvider);
}
