import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// Every account with a balance at the end of a day, debits and credits in
/// their columns, grouped by kind; the totals must be equal.
class TrialBalanceScreen extends ConsumerStatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  ConsumerState<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends ConsumerState<TrialBalanceScreen> {
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
      helpText: 'Balances at the end of',
    );
    if (day != null) setState(() => _day = day);
  }

  @override
  Widget build(BuildContext context) {
    final tb = ref.watch(trialBalanceProvider(_day));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trial balance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              child: tb.when(
                loading: () => const ListSkeleton(rows: 8),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () => ref.invalidate(trialBalanceProvider(_day)),
                ),
                data: (t) => RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(trialBalanceProvider(_day).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (t.rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nothing posted by this day.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final type in accountTypes)
                        ..._group(
                          context,
                          type,
                          t.rows.where((r) => r.type == type).toList(),
                        ),
                      if (t.rows.isNotEmpty) _Totals(t),
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

  List<Widget> _group(BuildContext context, String type, List<TrialRow> rows) {
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
        child: Text(
          accountTypeNames[type]!.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      for (final r in rows)
        InkWell(
          onTap: () => context.push('/books/accounts/${r.accountId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    r.code,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(child: Text(r.name)),
                const SizedBox(width: 8),
                Text(
                  drCr(r.debit, r.credit),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _Totals extends StatelessWidget {
  final TrialBalance t;

  const _Totals(this.t);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: BooksCard(
      border: t.balanced ? AppColors.cardBorder : AppColors.error,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _line('Total debits', thousands(t.totalDebit)),
            const SizedBox(height: 4),
            _line('Total credits', thousands(t.totalCredit)),
            const SizedBox(height: 8),
            Text(
              t.balanced ? 'Debits equal credits' : 'Debits and credits differ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.balanced ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _line(String label, String value) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
