import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audit_history_list.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../customers/presentation/widgets/record_payment_dialog.dart';
import '../../data/models/field_ops_models.dart';
import '../controllers/field_ops_controller.dart';
import '../../../../core/widgets/skeleton.dart';

/// Bottom sheet with a sale's details and change history. Admins can void it.
class SaleDetailSheet extends ConsumerWidget {
  final MilkSaleModel sale;

  const SaleDetailSheet({super.key, required this.sale});

  static Future<void> show(BuildContext context, MilkSaleModel sale) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SaleDetailSheet(sale: sale),
    );
  }

  static const _fieldLabels = {
    'buyer_name': 'Customer',
    'quantity_litres': 'Litres',
    'unit_price': 'Price/L',
    'total_amount': 'Total (KES)',
    'amount_paid': 'Paid at sale',
    'payment_status': 'Payment',
    'notes': 'Notes',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider).valueOrNull?.user?.isSaccoAdmin ??
        false;
    final historyAsync = ref.watch(saleHistoryProvider(sale.id));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sale.buyerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  sale.isVoided
                      ? const StatusPill(
                          status: 'VOIDED',
                          type: StatusType.error,
                        )
                      : StatusPill.fromStatusString(sale.paymentStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${sale.quantityLitres.toStringAsFixed(1)} L @ KES ${sale.unitPrice.toStringAsFixed(2)} = '
                'KES ${sale.totalAmount.toStringAsFixed(2)} • paid ${sale.amountPaid.toStringAsFixed(2)} (${sale.paymentMethod})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (sale.isVoided && sale.voidReason != null)
                Text(
                  'Voided: ${sale.voidReason}',
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              if (isAdmin && !sale.isVoided) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Void this sale'),
                  onPressed: () async {
                    final reason = await askVoidReason(
                      context,
                      title: 'Void sale to ${sale.buyerName}?',
                    );
                    if (reason == null || !context.mounted) return;
                    final error = await voidSale(ref, sale.id, reason);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Sale voided'),
                        backgroundColor: error == null
                            ? AppColors.success
                            : null,
                      ),
                    );
                    if (error == null) Navigator.of(context).pop();
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'History',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: historyAsync.when(
                  data: (entries) => AuditHistoryList(
                    entries: entries,
                    fieldLabels: _fieldLabels,
                    createdSummary: (v) => [
                      if (v['quantity_litres'] != null)
                        'Litres: ${v['quantity_litres']} @ KES ${v['unit_price']}/L',
                      if (v['amount_paid'] != null)
                        'Paid at sale: KES ${v['amount_paid']}',
                    ],
                  ),
                  loading: () => const ListSkeleton(rows: 4),
                  error: (e, _) => Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
