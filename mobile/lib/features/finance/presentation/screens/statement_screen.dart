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
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/finance_models.dart';
import '../finance_providers.dart';

/// One imported statement against the cashbook: what is matched, what the
/// bank shows that DairyGo does not, and what DairyGo has that the bank has
/// not shown.
class StatementScreen extends ConsumerWidget {
  final String id;

  const StatementScreen({super.key, required this.id});

  static final _day = DateFormat('d MMM');

  void _say(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<String?> Function() action,
  ) async {
    try {
      final msg = await action();
      ref.invalidate(reconciliationProvider(id));
      ref.invalidate(statementsProvider);
      ref.invalidate(cashbookProvider);
      if (msg != null && context.mounted) _say(context, msg);
    } catch (e) {
      if (context.mounted) _say(context, errorText(e));
    }
  }

  /// Chooses the cashbook movement for a line in the bank only.
  Future<void> _match(BuildContext context, WidgetRef ref, BankLine l) async {
    final service = ref.read(financeServiceProvider);
    List<BookMovement> options;
    try {
      options = await service.candidates(l.id);
    } catch (e) {
      if (context.mounted) _say(context, errorText(e));
      return;
    }
    if (!context.mounted) return;
    final key = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              '${l.description} · ${_day.format(l.date)} · ${_signed(l.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (options.isEmpty)
              const Text(
                'Nothing in the cashbook has this amount within a week. Record it '
                '(an expense for bank charges, other income for interest), then match it.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            for (final m in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.pop(ctx, m.key),
                title: Text(m.description),
                subtitle: Text(
                  [
                    _day.format(m.date),
                    if ((m.reference ?? '').isNotEmpty) m.reference!,
                  ].join(' · '),
                ),
                trailing: Text(
                  _signed(m.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
    if (key == null || !context.mounted) return;
    await _run(context, ref, () async {
      await service.matchLine(l.id, key);
      return 'Matched';
    });
  }

  static String _signed(double v) =>
      '${v < 0 ? '−' : '+'}${thousands(v.abs(), decimals: 0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canManageAccounts ??
        false;
    final rec = ref.watch(reconciliationProvider(id));
    final service = ref.read(financeServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          rec.valueOrNull?.account.name ?? 'Statement',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canManage && rec.hasValue)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove this statement?'),
                    content: const Text(
                      'Its lines and matches go. The cashbook is not touched; import it again any time.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                try {
                  await service.deleteStatement(id);
                  ref.invalidate(statementsProvider);
                  ref.invalidate(cashbookProvider);
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) _say(context, errorText(e));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Remove statement')),
              ],
            ),
        ],
      ),
      body: ReadableWidth(
        child: rec.when(
          loading: () => const ListSkeleton(rows: 6),
          error: (e, _) => ErrorView(
            message: errorText(e),
            onRetry: () => ref.invalidate(reconciliationProvider(id)),
          ),
          data: (r) {
            final bankOnly = [
              for (final l in r.lines)
                if (!l.matched) l,
            ];
            final matched = [
              for (final l in r.lines)
                if (l.matched) l,
            ];
            return RefreshIndicator(
              onRefresh: () => ref.refresh(reconciliationProvider(id).future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    '${DateFormat('d MMM y').format(r.statement.from)} – '
                    '${DateFormat('d MMM y').format(r.statement.to)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  FigureGrid(
                    figures: [
                      Figure('Matched', '${r.matched} of ${r.lines.length}'),
                      Figure(
                        'In the bank only',
                        '${r.bankOnly}',
                        color: r.bankOnly > 0 ? AppColors.warning : null,
                      ),
                      Figure(
                        'In DairyGo only',
                        '${r.bookOnly.length}',
                        color: r.bookOnly.isNotEmpty ? AppColors.warning : null,
                      ),
                      Figure(
                        'Cashbook balance',
                        kes(r.bookBalance, cents: false),
                      ),
                    ],
                  ),
                  if (r.statement.closingBalance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'The statement ends at ${kes(r.statement.closingBalance!)}; '
                        'the cashbook at ${kes(r.bookBalance)} on the same day'
                        '${(r.difference ?? 0) == 0 ? ': they agree.' : ' (a difference of ${kes(r.difference!)}).'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: (r.difference ?? 0) == 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (canManage && bankOnly.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _run(context, ref, () async {
                            final n = await service.autoMatch(id);
                            return n == 0
                                ? 'Nothing more could be matched for sure'
                                : 'Matched $n';
                          }),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Match automatically'),
                        ),
                      ),
                    ),
                  _Heading(
                    'In the bank, not in DairyGo',
                    total: r.bankOnlyTotal,
                  ),
                  if (bankOnly.isEmpty) const _Empty('Every line is matched.'),
                  for (final l in bankOnly)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: canManage ? () => _match(context, ref, l) : null,
                      title: Text(
                        l.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          _day.format(l.date),
                          if ((l.reference ?? '').isNotEmpty) l.reference!,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        _signed(l.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  _Heading(
                    'In DairyGo, not in the bank',
                    total: r.bookOnlyTotal,
                  ),
                  if (r.bookOnly.isEmpty)
                    const _Empty('The bank shows everything in the cashbook.'),
                  for (final m in r.bookOnly)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        m.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          _day.format(m.date),
                          if ((m.reference ?? '').isNotEmpty) m.reference!,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        _signed(m.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  const _Heading('Matched'),
                  if (matched.isEmpty) const _Empty('Nothing matched yet.'),
                  for (final l in matched)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onLongPress: canManage
                          ? () => _run(context, ref, () async {
                              await service.unmatchLine(l.id);
                              return 'Unmatched';
                            })
                          : null,
                      leading: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      title: Text(
                        l.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_day.format(l.date)} · ${l.movement?.description ?? 'in the cashbook'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _signed(l.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (canManage && matched.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Tap a line in the bank only to match it. Matched the wrong one? Hold it to unmatch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final double? total;

  const _Heading(this.text, {this.total});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        if (total != null && total != 0)
          Text(
            kes(total!, cents: false),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
  );
}
