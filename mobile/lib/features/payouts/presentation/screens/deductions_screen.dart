import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';
import '../widgets/deduction_form_sheet.dart';

/// The Sacco's deductions: what is taken from farmers' pay, how much and how
/// often, in the order it is taken.
class DeductionsScreen extends ConsumerWidget {
  const DeductionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canManageDeductions ??
        false;
    final list = ref.watch(deductionTypesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deductions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => DeductionFormSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add deduction'),
            )
          : null,
      body: ReadableWidth(
        child: list.when(
          loading: () => const ListSkeleton(rows: 4),
          error: (e, _) => ErrorView(
            message: errorText(e),
            onRetry: () => ref.invalidate(deductionTypesProvider),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              const Text(
                'Taken from every pay run, top to bottom. Advances and charges are recovered first; '
                'a cost on the money sent (like M-Pesa charges) is taken last.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No deductions yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final d in items) _DeductionCard(d: d, canManage: canManage),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeductionCard extends StatelessWidget {
  final DeductionType d;
  final bool canManage;

  const _DeductionCard({required this.d, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        onTap: canManage
            ? () => DeductionFormSheet.show(context, existing: d)
            : null,
        title: Text(
          d.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${d.howMuch} · ${d.howOften}'),
            Text(
              [
                d.appliesTo == 'ALL' ? 'Every farmer' : 'Chosen farmers',
                if (d.isSavings) 'savings (shares)',
              ].join(' · '),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          d.isActive ? 'On' : 'Off',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: d.isActive ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
