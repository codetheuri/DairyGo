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
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../finance/presentation/finance_providers.dart'
    show Month, monthOf;
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';
import 'chart_screen.dart' show showAccountDialog;

/// One account's entries month by month with the running balance, in the
/// account's usual direction (debits for assets and expenses).
class AccountLedgerScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountLedgerScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountLedgerScreen> createState() =>
      _AccountLedgerScreenState();
}

class _AccountLedgerScreenState extends ConsumerState<AccountLedgerScreen> {
  Month _month = monthOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final query = (accountId: widget.accountId, month: _month);
    final ledger = ref.watch(accountLedgerProvider(query));
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    final account = ledger.valueOrNull?.account;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          account == null ? 'Account' : '${account.code} ${account.name}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canManage && account != null)
            IconButton(
              tooltip: 'Change the account',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showAccountDialog(context, ref, account: _withUse(account)),
            ),
        ],
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: MonthSwitcher(
                month: _month,
                onChanged: (m) => setState(() => _month = m),
              ),
            ),
            Expanded(
              child: ledger.when(
                loading: () => const ListSkeleton(rows: 6),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () => ref.invalidate(accountLedgerProvider(query)),
                ),
                data: (l) => RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(accountLedgerProvider(query).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      FigureGrid(
                        figures: [
                          Figure('Opening', thousands(l.opening)),
                          Figure('Closing', thousands(l.closing)),
                          Figure('Debits', thousands(l.totalDebit)),
                          Figure('Credits', thousands(l.totalCredit)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${accountTypeOne[l.account.type]} account: balances are '
                        '${l.account.type == 'ASSET' || l.account.type == 'EXPENSE' ? 'debits less credits' : 'credits less debits'}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (l.lines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nothing posted this month.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final line in l.lines.reversed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () =>
                              context.push('/books/journals/${line.journalId}'),
                          title: Text(
                            line.lineMemo == null || line.lineMemo!.isEmpty
                                ? line.memo
                                : '${line.memo} (${line.lineMemo})',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'J-${line.number} · ${DateFormat('d MMM').format(line.date)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                drCr(line.debit, line.credit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                thousands(line.balance),
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

  /// The ledger's account doesn't say whether it was used; the chart does.
  LedgerAccount _withUse(LedgerAccount a) {
    final fromChart = ref
        .read(ledgerAccountsProvider)
        .valueOrNull
        ?.where((c) => c.id == a.id)
        .firstOrNull;
    return fromChart ??
        LedgerAccount(
          id: a.id,
          code: a.code,
          name: a.name,
          type: a.type,
          description: a.description,
          isActive: a.isActive,
          used: true,
        );
  }
}
