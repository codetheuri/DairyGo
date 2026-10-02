import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audit_history_list.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/models/milk_collection_model.dart';
import '../controllers/collection_controller.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/late_entry_note.dart';

/// Bottom sheet showing a collection's current status and its audit history:
/// who recorded it, every edit and status change, with reasons.
class CollectionHistorySheet extends ConsumerWidget {
  final MilkCollectionModel collection;

  const CollectionHistorySheet({super.key, required this.collection});

  static Future<void> show(
    BuildContext context,
    MilkCollectionModel collection,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CollectionHistorySheet(collection: collection),
    );
  }

  static const _fieldLabels = {
    'quantity_litres': 'Litres',
    'total_amount': 'Total (KES)',
    'shift': 'Shift',
    'status': 'Status',
    'notes': 'Notes',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(collectionHistoryProvider(collection.id));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                      collection.memberName ?? 'Milk intake entry',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  StatusPill.fromStatusString(collection.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${collection.quantityLitres.toStringAsFixed(1)} L • ${collection.shift} • ${collection.collectionDate.split('T').first}'
                ' • KES ${collection.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              LateEntryNote(reason: collection.lateReason),
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
                        'Litres: ${v['quantity_litres']}',
                      if (v['price_per_litre'] != null)
                        'Rate: KES ${v['price_per_litre']}/L',
                    ],
                  ),
                  loading: () => const ListSkeleton(),
                  error: (err, _) => Text(
                    err.toString().replaceAll('Exception: ', ''),
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
