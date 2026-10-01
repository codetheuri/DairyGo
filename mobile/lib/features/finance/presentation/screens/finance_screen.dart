import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/fitted_tab.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/finance_models.dart';
import '../finance_providers.dart';
import '../widgets/finance_sheets.dart';

/// The Sacco's own money: expenses, accounts (petty cash, bank, M-Pesa) and
/// the income and expenditure, month by month.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  Month _month = monthOf(DateTime.now());
  String? _categoryId;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _shift(int months) {
    final next = monthOf(
      DateTime(_month.from.year, _month.from.month + months, 1),
    );
    if (next.from.isAfter(DateTime.now())) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isThisMonth = monthOf(DateTime.now()).from == _month.from;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expenses & Money',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            FittedTab(icon: Icons.receipt_long_rounded, label: 'Expenses'),
            FittedTab(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Accounts',
            ),
            FittedTab(icon: Icons.insights_rounded, label: 'Income & spending'),
          ],
        ),
      ),
      floatingActionButton: (user?.canRecordExpenses ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => ExpenseFormSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Expense'),
            )
          : null,
      body: ReadableWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Month before',
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM y').format(_month.from),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Month after',
                    onPressed: isThisMonth ? null : () => _shift(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ExpensesTab(
                    month: _month,
                    categoryId: _categoryId,
                    onCategory: (id) => setState(() => _categoryId = id),
                  ),
                  _AccountsTab(month: _month),
                  _SummaryTab(month: _month),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final Month month;
  final String? categoryId;
  final ValueChanged<String?> onCategory;

  const _ExpensesTab({
    required this.month,
    required this.categoryId,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (month: month, categoryId: categoryId);
    final list = ref.watch(expensesProvider(query));
    final categories =
        ref.watch(expenseCategoriesProvider).valueOrNull ?? const [];
    final canVoid =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canRecordExpenses ??
        false;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(expensesProvider(query).future),
      child: list.when(
        loading: () => const ListSkeleton(rows: 5),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(expensesProvider(query)),
        ),
        data: (l) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            FigureGrid(
              figures: [
                Figure(
                  'Spent',
                  kes(l.total, cents: false),
                  color: AppColors.error,
                ),
                Figure('Expenses', '${l.expenses.length}'),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onCategory,
            ),
            if (categoryId == null && l.byCategory.length > 1) ...[
              const SizedBox(height: 12),
              for (final c in l.byCategory)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        kes(c.amount, cents: false),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            if (l.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No expenses this month.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final e in l.expenses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onLongPress: canVoid
                    ? () => VoidExpenseDialog.show(context, ref, e, query)
                    : null,
                title: Text(
                  e.payee,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    DateFormat('d MMM').format(e.date),
                    e.category,
                    e.account,
                    if ((e.reference ?? '').isNotEmpty) e.reference!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  kes(e.amount, cents: false),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (l.expenses.isNotEmpty && canVoid)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Recorded by mistake? Hold it to void.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountsTab extends ConsumerWidget {
  final Month month;

  const _AccountsTab({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final accounts = ref.watch(cashAccountsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(cashAccountsProvider.future),
      child: accounts.when(
        loading: () => const ListSkeleton(rows: 3),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(cashAccountsProvider),
        ),
        data: (all) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            FigureGrid(
              figures: [
                Figure('In all accounts now', kes(all.total, cents: false)),
              ],
            ),
            const SizedBox(height: 12),
            if (user?.canManageAccounts ?? false)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => AccountFormSheet.show(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add account'),
                  ),
                  if (all.active.length > 1)
                    OutlinedButton.icon(
                      onPressed: () => TransferSheet.show(context, all.active),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Move money'),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            if (all.accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No accounts yet. Add where the Sacco keeps money: petty cash, the bank, M-Pesa. '
                  'Then every payment in or out shows in that account\'s cashbook.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final a in all.accounts)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: ListTile(
                  onTap: () => context.push('/finance/accounts/${a.id}'),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentMint,
                    foregroundColor: AppColors.primary,
                    child: Icon(switch (a.kind) {
                      'BANK' => Icons.account_balance_outlined,
                      'MPESA' => Icons.phone_android_rounded,
                      _ => Icons.payments_outlined,
                    }),
                  ),
                  title: Text(
                    a.name,
                    style: TextStyle(
                      color: a.isActive ? null : AppColors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    [
                      a.kindLabel,
                      if ((a.number ?? '').isNotEmpty) a.number!,
                      if (!a.isActive) 'closed',
                    ].join(' · '),
                  ),
                  trailing: Text(
                    kes(a.balance, cents: false),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  final Month month;

  const _SummaryTab({required this.month});

  Widget _row(String label, double v, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
              ),
            ),
            Text(
              kes(v, cents: false),
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sum = ref.watch(financeSummaryProvider(month));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(financeSummaryProvider(month).future),
      child: sum.when(
        loading: () => const ListSkeleton(rows: 6),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(financeSummaryProvider(month)),
        ),
        data: (FinanceSummary s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            FigureGrid(
              figures: [
                Figure('Income', kes(s.income, cents: false)),
                Figure('Spending', kes(s.spending, cents: false)),
                Figure(
                  s.surplus < 0 ? 'Deficit' : 'Surplus',
                  kes(s.surplus.abs(), cents: false),
                  color: s.surplus < 0 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
            _heading('Income'),
            _row('Milk sales', s.milkSales),
            for (final f in s.fees) _row(f.name, f.amount),
            if (s.farmerCharges != 0)
              _row('Charges to farmers', s.farmerCharges),
            _heading('Spending'),
            _row('Milk bought from farmers', s.milkPurchases),
            for (final e in s.expenses) _row(e.name, e.amount),
            const Divider(height: 24),
            _row(
              s.surplus < 0 ? 'Deficit' : 'Surplus',
              s.surplus,
              bold: true,
              color: s.surplus < 0 ? AppColors.error : AppColors.success,
            ),
            for (final sh in s.sharesRaised)
              Text(
                '${sh.name} raised: ${kes(sh.amount, cents: false)} (farmers\' savings, not income)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            _heading('Today'),
            _row('Cash in all accounts', s.cash),
            _row('Customers owe the Sacco', s.receivables),
            _row('Farmers owe the Sacco', s.farmersOwe),
            _row('Farmers\' pay still to send', s.farmerPayDue),
            _row('Farmers\' shares', s.shareCapital),
          ],
        ),
      ),
    );
  }
}
