import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/shell/app_destinations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/cache/keep_fresh.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../books/presentation/books_providers.dart';
import '../finance_providers.dart';
import '../widgets/finance_sheets.dart';
import 'finance_screen.dart';

/// The accountant's home: where the Sacco's money stands today and how this
/// month is going, with no milk entries. Everything comes from the income and
/// expenditure the Money tab shows, so the two always agree.
class MoneyHomeScreen extends ConsumerWidget {
  const MoneyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final month = monthOf(DateTime.now());
    final summary = ref.watch(financeSummaryProvider(month));
    return RefreshOnShow(
      providers: [financeSummaryProvider(month)],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Hello, ${user?.fullName.split(' ').first ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(financeSummaryProvider(month).future),
            child: summary.when(
              loading: () => const ListSkeleton(rows: 6),
              error: (e, _) => ErrorView(
                message: errorText(e),
                onRetry: () => ref.invalidate(financeSummaryProvider(month)),
              ),
              data: (s) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  const _Heading('Today'),
                  if (s.notInAccount > 0) NotInAccountNote(summary: s),
                  FigureGrid(
                    figures: [
                      Figure('Cash in all accounts', kes(s.cash, cents: false)),
                      Figure('Customers owe', kes(s.receivables, cents: false)),
                      Figure(
                        'Farmers\' pay to send',
                        kes(s.farmerPayDue, cents: false),
                      ),
                      Figure('Farmers owe', kes(s.farmersOwe, cents: false)),
                    ],
                  ),
                  _Heading(DateFormat('MMMM y').format(month.from)),
                  FigureGrid(
                    figures: [
                      Figure('Income', kes(s.income, cents: false)),
                      Figure('Spending', kes(s.spending, cents: false)),
                      Figure(
                        s.surplus < 0 ? 'Deficit' : 'Surplus',
                        kes(s.surplus.abs(), cents: false),
                        color: s.surplus < 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (user?.seesBooks ?? false) const _BooksTile(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Suppliers & bills'),
                    subtitle: Text(
                      s.owedBills == 0 && s.heldToPayOver == 0
                          ? 'Bills to pay and money to pay over'
                          : [
                              if (s.owedBills != 0)
                                'Bills ${kes(s.owedBills, cents: false)}',
                              if (s.heldToPayOver != 0)
                                'to pay over ${kes(s.heldToPayOver, cents: false)}',
                            ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/finance/suppliers'),
                  ),
                  if (user?.seesCustomerBalances ?? false)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.handshake_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Customers'),
                      subtitle: const Text(
                        'What each customer owes, payments and statements',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => StatefulNavigationShell.maybeOf(
                        context,
                      )?.goBranch(AppSection.customers.branch),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Download reports'),
                    subtitle: const Text(
                      'Income and expenditure, cashbooks, expenses, farmer and customer balances',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.reportDownloads),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the books agree with the records: a difference shows here first.
class _BooksTile extends ConsumerWidget {
  const _BooksTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(booksStatusProvider).valueOrNull;
    final wrong = st != null && st.started && !(st.agrees && st.balanced);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        wrong ? Icons.error_outline_rounded : Icons.menu_book_outlined,
        color: wrong ? AppColors.error : AppColors.primary,
      ),
      title: const Text('Books'),
      subtitle: Text(
        st == null
            ? 'Journals, trial balance and chart of accounts'
            : !st.started
            ? 'Not started yet'
            : wrong
            ? 'The books differ from the records: open to see why'
            : 'The books agree with the records',
        style: TextStyle(color: wrong ? AppColors.error : null),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        final shell = StatefulNavigationShell.maybeOf(context);
        if (shell != null) {
          shell.goBranch(AppSection.books.branch);
        } else {
          context.push(AppRoutes.books);
        }
      },
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  );
}
