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
import '../books_providers.dart';
import '../widgets/books_widgets.dart';
import '../widgets/statement_section.dart';

/// What the Sacco owns and owes at the end of a day, beside the end of the
/// last financial year.
class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'The position at the end of',
    );
    if (day != null) setState(() => _day = day);
  }

  @override
  Widget build(BuildContext context) {
    final bs = ref.watch(balanceSheetProvider(_day));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Balance sheet',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  'At the end of ${DateFormat('d MMM y').format(_day)}',
                ),
              ),
            ),
            Expanded(
              child: bs.when(
                loading: () => const ListSkeleton(rows: 6),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () => ref.invalidate(balanceSheetProvider(_day)),
                ),
                data: (b) {
                  final prev = DateFormat('d MMM y').format(b.previousDate);
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(balanceSheetProvider(_day).future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        FigureGrid(
                          figures: [
                            Figure('Assets', kes(b.assets.total, cents: false)),
                            Figure(
                              'Liabilities',
                              kes(b.liabilities.total, cents: false),
                            ),
                            Figure('Equity', kes(b.equity.total, cents: false)),
                          ],
                        ),
                        StatementSectionCard(
                          section: b.assets,
                          previousLabel: prev,
                          totalLabel: 'Total assets',
                        ),
                        StatementSectionCard(
                          section: b.liabilities,
                          previousLabel: prev,
                          totalLabel: 'Total liabilities',
                        ),
                        StatementSectionCard(
                          section: b.equity,
                          previousLabel: prev,
                          totalLabel: 'Total equity',
                        ),
                        const SizedBox(height: 14),
                        BooksCard(
                          border: b.balanced
                              ? AppColors.cardBorder
                              : AppColors.error,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StatementRow(
                                label: 'Liabilities plus equity',
                                amount: b.liabilitiesAndEquity,
                                previous: b.previousLiabilitiesAndEquity,
                                previousLabel: prev,
                                bold: true,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  12,
                                ),
                                child: Text(
                                  b.balanced
                                      ? 'Assets equal liabilities plus equity'
                                      : 'Assets and liabilities plus equity differ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: b.balanced
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Until a year is closed, its income and expenses show as the '
                          'surplus lines under equity.',
                          style: TextStyle(
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
