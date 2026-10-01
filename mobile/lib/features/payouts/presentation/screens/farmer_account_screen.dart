import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../members/presentation/controllers/member_controller.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';
import '../widgets/account_entry_sheet.dart';
import '../widgets/farmer_deduction_sheet.dart';

/// A farmer's account: what the Sacco owes them (or they owe), their shares,
/// advances to recover, their deductions and the statement.
class FarmerAccountScreen extends ConsumerWidget {
  final String memberId;

  const FarmerAccountScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final member = ref.watch(memberDetailsProvider(memberId)).valueOrNull;
    final account = ref.watch(farmerAccountProvider(memberId));
    final name = member == null
        ? 'Farmer'
        : '${member.firstName} ${member.lastName}';

    Future<void> add(EntryKind kind) async {
      final done = await AccountEntrySheet.show(
        context,
        memberId: memberId,
        farmer: name,
        kind: kind,
      );
      if (done == true && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${kind.label} saved')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$name: account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: account.when(
          loading: () => const ListSkeleton(rows: 6),
          error: (e, _) => ErrorView(
            message: errorText(e),
            onRetry: () => ref.invalidate(farmerAccountProvider(memberId)),
          ),
          data: (a) => RefreshIndicator(
            onRefresh: () {
              ref.invalidate(farmerDeductionsProvider(memberId));
              return ref.refresh(farmerAccountProvider(memberId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                FigureGrid(
                  figures: [
                    Figure(
                      a.balance < 0 ? 'Owes the Sacco' : 'Sacco owes',
                      kes(a.balance.abs()),
                      color: a.balance < 0
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    Figure('Shares', kes(a.shares)),
                    Figure('Advances to recover', kes(a.openAdvances)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (user?.canGiveAdvances ?? false)
                      FilledButton.icon(
                        onPressed: () => add(EntryKind.advance),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Give advance'),
                      ),
                    if (user?.canRecordCharges ?? false) ...[
                      OutlinedButton.icon(
                        onPressed: () => add(EntryKind.charge),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Add charge'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => add(EntryKind.adjustment),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Adjust'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _Deductions(
                  memberId: memberId,
                  canChange: user?.canManageDeductions ?? false,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Statement',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Text(
                  'The last 12 months. Positive amounts add to what the farmer is owed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (a.lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nothing on this account yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final e in a.lines.reversed)
                  _EntryTile(
                    entry: e,
                    memberId: memberId,
                    canVoid: user?.canRecordCharges ?? false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Deductions extends ConsumerWidget {
  final String memberId;
  final bool canChange;

  const _Deductions({required this.memberId, required this.canChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(farmerDeductionsProvider(memberId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Deductions',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        list.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            errorText(e),
            style: const TextStyle(color: AppColors.error),
          ),
          data: (items) {
            final shown = [
              for (final d in items)
                if (d.type.isActive || d.applies) d,
            ];
            if (shown.isEmpty) {
              return const Text(
                'No deductions are switched on.',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: [
                for (final d in shown)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: canChange
                        ? () => FarmerDeductionSheet.show(
                            context,
                            memberId: memberId,
                            deduction: d,
                          )
                        : null,
                    leading: Icon(
                      d.applies
                          ? Icons.check_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: d.applies
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    title: Text(d.type.name),
                    subtitle: Text(
                      d.applies
                          ? [
                              _amount(d),
                              // Their own target, when they have one.
                              d.type.frequency == 'UNTIL_TARGET' &&
                                      d.target != null
                                  ? 'until ${kes(d.target!, cents: false)}'
                                  : d.type.howOften,
                              if (d.paidSoFar > 0)
                                'paid ${kes(d.paidSoFar, cents: false)} so far',
                            ].join(' · ')
                          : 'Does not pay this',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: canChange
                        ? const Icon(Icons.chevron_right_rounded)
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _amount(FarmerDeduction d) => switch (d.type.method) {
    'PERCENT' => '${thousands(d.amount)}%',
    'PER_LITRE' => '${kes(d.amount)} a litre',
    'TIERED' => 'By amount sent',
    _ => kes(d.amount, cents: false),
  };
}

class _EntryTile extends ConsumerWidget {
  final AccountEntry entry;
  final String memberId;
  final bool canVoid;

  const _EntryTile({
    required this.entry,
    required this.memberId,
    required this.canVoid,
  });

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Void this ${entry.kindLabel.toLowerCase()}?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(payoutServiceProvider).voidEntry(entry.id, reason);
      ref.invalidate(farmerAccountProvider(memberId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entry;
    final positive = e.amount >= 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onLongPress: canVoid && e.canVoid ? () => _void(context, ref) : null,
      title: Text(
        e.description.isEmpty ? e.kindLabel : e.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: e.voided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          shortDate(e.date),
          e.kindLabel,
          if ((e.reference ?? '').isNotEmpty) e.reference!,
          if (e.voided) 'voided',
          if (e.canVoid && canVoid) 'hold to void',
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${positive ? '+' : ''}${thousands(e.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: positive ? AppColors.success : AppColors.error,
            ),
          ),
          Text(
            thousands(e.balance),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
