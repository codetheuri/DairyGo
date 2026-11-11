import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../finance/data/finance_models.dart' show FinancialYear;
import '../../../finance/presentation/finance_providers.dart';
import '../books_providers.dart';
import '../widgets/statement_section.dart';

/// Income less expenses for a month or a financial year, from the books,
/// beside the period before it.
class IncomeStatementScreen extends ConsumerStatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  ConsumerState<IncomeStatementScreen> createState() =>
      _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends ConsumerState<IncomeStatementScreen> {
  DateTime _anchor = DateTime.now();
  bool _byYear = false;

  Month _periodFor(DateTime day, int startMonth) {
    if (!_byYear) return monthOf(day);
    final fy = FinancialYear.of(day, startMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (from: fy.from, to: fy.to.isAfter(today) ? today : fy.to);
  }

  void _shift(int step, int startMonth) {
    final next = _byYear
        ? DateTime(_anchor.year + step, _anchor.month, 1)
        : DateTime(_anchor.year, _anchor.month + step, 1);
    if (_periodFor(next, startMonth).from.isAfter(DateTime.now())) return;
    setState(() => _anchor = next);
  }

  static String _name(DateTime from, DateTime to) {
    final wholeMonth =
        from.day == 1 &&
        from.month == to.month &&
        from.year == to.year &&
        DateTime(to.year, to.month, to.day + 1).day == 1;
    if (wholeMonth) return DateFormat('MMM y').format(from);
    if (from.year == to.year && from.month == to.month) {
      return '${from.day}–${DateFormat('d MMM y').format(to)}';
    }
    return '${DateFormat('MMM y').format(from)} – ${DateFormat('MMM y').format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final startMonth =
        ref.watch(financialYearProvider).valueOrNull?.startMonth ?? 1;
    final period = _periodFor(_anchor, startMonth);
    final st = ref.watch(incomeStatementProvider(period));
    final closed = ref.watch(booksStatusProvider).valueOrNull?.closedThrough;
    final isClosed = closed != null && !period.to.isAfter(closed);
    final label = _byYear
        ? FinancialYear.label(
            period.from,
            FinancialYear.of(_anchor, startMonth).to,
          )
        : DateFormat('MMMM y').format(period.from);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Income statement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => context.push(AppRoutes.reportDownloads),
          ),
        ],
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Before',
                    onPressed: () => _shift(-1, startMonth),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: PopupMenuButton<bool>(
                      tooltip: 'Month or financial year',
                      initialValue: _byYear,
                      onSelected: (v) => setState(() => _byYear = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: false, child: Text('Month')),
                        PopupMenuItem(
                          value: true,
                          child: Text('Financial year'),
                        ),
                      ],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'After',
                    onPressed: () => _shift(1, startMonth),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: st.when(
                loading: () => const ListSkeleton(rows: 6),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () =>
                      ref.invalidate(incomeStatementProvider(period)),
                ),
                data: (s) {
                  final prev = _name(s.previousFrom, s.previousTo);
                  final word = s.surplus < 0 ? 'Deficit' : 'Surplus';
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(incomeStatementProvider(period).future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        FigureGrid(
                          figures: [
                            Figure('Income', kes(s.income.total, cents: false)),
                            Figure(
                              'Expenses',
                              kes(s.expenses.total, cents: false),
                            ),
                            Figure(
                              word,
                              kes(s.surplus.abs(), cents: false),
                              color: s.surplus < 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ],
                        ),
                        StatementSectionCard(
                          section: s.income,
                          previousLabel: prev,
                          totalLabel: 'Total income',
                        ),
                        StatementSectionCard(
                          section: s.expenses,
                          previousLabel: prev,
                          totalLabel: 'Total expenses',
                        ),
                        const SizedBox(height: 14),
                        StatementRow(
                          label: 'Income less expenses',
                          amount: s.surplus,
                          previous: s.previousSurplus,
                          previousLabel: prev,
                          bold: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          [
                            'Milk bought is counted when its pay run is approved, on the pay run\'s last day.',
                            if (isClosed)
                              'This period is closed: its figures will not change.',
                            if (period.from.isBefore(s.startDate))
                              'The books start on ${DateFormat('d MMM y').format(s.startDate)}; '
                                  'what came before is in the opening balances.',
                          ].join(' '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
