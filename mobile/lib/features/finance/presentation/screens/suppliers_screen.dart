import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../widgets/money_flow_sheets.dart';

/// Who the Sacco pays: bills still to pay, and money taken from farmers'
/// pay for someone else, waiting to be paid over.
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRecord =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canRecordExpenses ??
        false;
    final list = ref.watch(suppliersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suppliers & bills',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canRecord
          ? FloatingActionButton.extended(
              onPressed: () => BillFormSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Bill'),
            )
          : null,
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(suppliersProvider.future),
          child: list.when(
            loading: () => const ListSkeleton(rows: 5),
            error: (e, _) => ErrorView(
              message: errorText(e),
              onRetry: () => ref.invalidate(suppliersProvider),
            ),
            data: (l) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                FigureGrid(
                  figures: [
                    Figure(
                      'Bills to pay',
                      kes(l.billsOwed, cents: false),
                      color: l.billsOwed > 0 ? AppColors.error : null,
                    ),
                    Figure('To pay over', kes(l.held, cents: false)),
                  ],
                ),
                const SizedBox(height: 8),
                if (canRecord)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => SupplierFormSheet.show(context),
                      icon: const Icon(Icons.person_add_alt_rounded),
                      label: const Text('Add supplier'),
                    ),
                  ),
                const SizedBox(height: 8),
                if (l.suppliers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No suppliers yet. Add the businesses the Sacco buys from on credit, '
                      'and anyone a deduction collects money for (an insurer, a union).',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final s in l.suppliers) _SupplierTile(s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Supplier s;

  const _SupplierTile(this.s);

  @override
  Widget build(BuildContext context) {
    final owed = [
      if (s.billsOwed != 0) 'Bills ${kes(s.billsOwed, cents: false)}',
      if (s.held != 0) 'To pay over ${kes(s.held, cents: false)}',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/finance/suppliers/${s.id}'),
      leading: CircleAvatar(
        backgroundColor: AppColors.accentMint,
        foregroundColor: AppColors.primary,
        child: Icon(
          s.isPayee ? Icons.volunteer_activism_outlined : Icons.store_outlined,
        ),
      ),
      title: Text(
        s.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: s.isActive ? null : AppColors.textSecondary),
      ),
      subtitle: Text(
        [
          if (owed.isEmpty) 'Nothing owed' else ...owed,
          if (!s.isActive) 'not in use',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
