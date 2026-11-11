import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/finance_models.dart';
import '../finance_providers.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// The month the Sacco's financial year starts. Those who keep the books
/// change it; it only groups dates for reports, so no record changes.
class FinancialYearCard extends ConsumerWidget {
  const FinancialYearCard({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, int current) async {
    var month = current;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Financial year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The month the Sacco\'s year starts. Reports offer "this financial year" '
                  'and "last financial year" from it. No record changes.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: month,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Starts in'),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text(_months[m - 1])),
                  ],
                  onChanged: (v) => setState(() => month = v ?? month),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, month),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !context.mounted) return;
    try {
      await ref.read(financeServiceProvider).setFinancialYear(picked);
      ref.invalidate(financialYearProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The financial year now starts in ${_months[picked - 1]}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(financialYearProvider);
    final canEdit =
        ref.watch(authControllerProvider).valueOrNull?.user?.canManageBooks ??
        false;
    final fy = year.valueOrNull;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.event_note_rounded, color: AppColors.primary),
        title: const Text(
          'Financial year',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          fy == null
              ? (year.hasError ? errorText(year.error!) : 'Loading…')
              : 'Starts in ${_months[fy.startMonth - 1]}. This year: ${FinancialYear.label(fy.thisFrom, fy.thisTo).replaceFirst('Financial year ', '')}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: canEdit ? const Icon(Icons.edit_outlined, size: 18) : null,
        onTap: canEdit && fy != null
            ? () => _edit(context, ref, fy.startMonth)
            : null,
      ),
    );
  }
}
