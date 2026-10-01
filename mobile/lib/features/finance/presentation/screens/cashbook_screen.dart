import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/skeleton.dart';
import '../finance_providers.dart';

/// One account's money in and out, month by month, with the running balance.
class CashbookScreen extends ConsumerStatefulWidget {
  final String accountId;

  const CashbookScreen({super.key, required this.accountId});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  Month _month = monthOf(DateTime.now());

  void _shift(int months) {
    final next = monthOf(
      DateTime(_month.from.year, _month.from.month + months, 1),
    );
    if (!next.from.isAfter(DateTime.now())) setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final query = (accountId: widget.accountId, month: _month);
    final book = ref.watch(cashbookProvider(query));
    final isThisMonth = monthOf(DateTime.now()).from == _month.from;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          book.valueOrNull?.account.name ?? 'Cashbook',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
              child: book.when(
                loading: () => const ListSkeleton(rows: 6),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () => ref.invalidate(cashbookProvider(query)),
                ),
                data: (b) => RefreshIndicator(
                  onRefresh: () => ref.refresh(cashbookProvider(query).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      FigureGrid(
                        figures: [
                          Figure('Opening', kes(b.opening, cents: false)),
                          Figure('Closing', kes(b.closing, cents: false)),
                          Figure(
                            'Money in',
                            kes(b.totalIn, cents: false),
                            color: AppColors.success,
                          ),
                          Figure(
                            'Money out',
                            kes(b.totalOut, cents: false),
                            color: AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (b.lines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No money in or out this month.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final l in b.lines.reversed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              DateFormat('d MMM').format(l.date),
                              if ((l.reference ?? '').isNotEmpty) l.reference!,
                            ].join(' · '),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l.moneyIn > 0
                                    ? '+${thousands(l.moneyIn, decimals: 0)}'
                                    : '-${thousands(l.moneyOut, decimals: 0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: l.moneyIn > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              Text(
                                thousands(l.balance, decimals: 0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
