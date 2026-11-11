import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// The books' opening journal on the start date: worked out from every
/// record before it (cash accounts, customers, farmers, shares, bills), plus
/// the accountant's own balances for what no record holds (fixed assets,
/// loans). Opening balances takes the other side of each.
class OpeningBalancesScreen extends ConsumerWidget {
  const OpeningBalancesScreen({super.key});

  static final _day = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opening = ref.watch(openingBalancesProvider);
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Opening balances',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'new-opening',
              onPressed: () => showOpeningDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Balance'),
            )
          : null,
      body: opening.when(
        loading: () => const ListSkeleton(rows: 6),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(openingBalancesProvider),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () => ref.refresh(openingBalancesProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'On ${_day.format(o.startDate)}, the day the books start. '
                      'Cash, what customers and farmers owed, shares and bills come from '
                      'the records dated before it; correct those records to change them.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const _Heading('Added by you'),
                    BooksCard(
                      child: Column(
                        children: [
                          if (o.own.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'None. Add what no record holds: buildings, coolers, '
                                'a bank loan, money owed from before DairyGo.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          for (final l in o.own) ...[
                            ListTile(
                              onTap: canManage
                                  ? () => showOpeningDialog(
                                      context,
                                      ref,
                                      existing: l,
                                    )
                                  : null,
                              title: Text(
                                '${l.accountCode}  ${l.accountName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: (l.memo ?? '').isEmpty
                                  ? null
                                  : Text(
                                      l.memo!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                              trailing: Text(
                                drCr(l.debit, l.credit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                    const _Heading('The opening journal'),
                    BooksCard(
                      child: o.journal == null
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'Nothing came before the start.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : Column(
                              children: [
                                for (final l in o.journal!.lines) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${l.accountCode}  ${l.accountName}',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          drCr(l.debit, l.credit),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                ],
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '${o.journal!.label} · debits equal credits',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

/// Sets (or changes, or removes) one account's opening balance.
Future<void> showOpeningDialog(
  BuildContext context,
  WidgetRef ref, {
  OpeningLine? existing,
}) async {
  final all = await ref.read(ledgerAccountsProvider.future);
  if (!context.mounted) return;
  // Balance sheet accounts no record keeps; the server refuses Opening
  // balances itself with a reason.
  final choices = [
    for (final a in all)
      if (a.isActive &&
          !a.kept &&
          (a.type == 'ASSET' || a.type == 'LIABILITY' || a.type == 'EQUITY'))
        a,
  ];
  await showDialog<void>(
    context: context,
    builder: (_) => _OpeningDialog(choices: choices, existing: existing),
  );
}

class _OpeningDialog extends ConsumerStatefulWidget {
  final List<LedgerAccount> choices;
  final OpeningLine? existing;

  const _OpeningDialog({required this.choices, this.existing});

  @override
  ConsumerState<_OpeningDialog> createState() => _OpeningDialogState();
}

class _OpeningDialogState extends ConsumerState<_OpeningDialog> {
  late String? _accountId = widget.existing?.accountId;
  late bool _debit = widget.existing == null || widget.existing!.debit > 0;
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.debit + widget.existing!.credit).toStringAsFixed(2),
  );
  late final _memo = TextEditingController(text: widget.existing?.memo);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save({bool remove = false}) async {
    final amount = remove ? 0.0 : double.tryParse(_amount.text.trim());
    if (_accountId == null || amount == null || amount < 0) {
      setState(() => _error = 'Choose the account and give the amount.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(booksServiceProvider)
          .setOpening(
            _accountId!,
            debit: _debit ? amount : 0,
            credit: _debit ? 0 : amount,
            memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
          );
      refreshBooks(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null ? 'Add an opening balance' : 'Opening balance',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              for (final a in widget.choices)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(a.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: widget.existing != null
                ? null
                : (v) => setState(() {
                    _accountId = v;
                    final t = widget.choices.firstWhere((a) => a.id == v).type;
                    _debit = t == 'ASSET';
                  }),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Debit')),
              ButtonSegment(value: false, label: Text('Credit')),
            ],
            selected: {_debit},
            onSelectionChanged: (v) => setState(() => _debit = v.first),
          ),
          const SizedBox(height: 4),
          const Text(
            'Debit for what the Sacco owns; credit for what it owes.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(labelText: 'Amount (KES)'),
          ),
          TextField(
            controller: _memo,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Cooler, at cost',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
    ),
    actions: [
      if (widget.existing != null)
        TextButton(
          onPressed: _busy ? null : () => _save(remove: true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Remove'),
        ),
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
    ],
  );
}
