import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/models/milk_collection_model.dart';
import '../controllers/collection_controller.dart';

/// Bottom sheet showing a collection's current status and its audit history:
/// who recorded it, every edit and status change, with reasons.
class CollectionHistorySheet extends ConsumerWidget {
  final MilkCollectionModel collection;

  const CollectionHistorySheet({super.key, required this.collection});

  static Future<void> show(BuildContext context, MilkCollectionModel collection) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CollectionHistorySheet(collection: collection),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(collectionHistoryProvider(collection.id));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  StatusPill.fromStatusString(collection.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${collection.quantityLitres.toStringAsFixed(1)} L • ${collection.shift} • ${collection.collectionDate.split('T').first}'
                ' • KES ${collection.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Flexible(
                child: historyAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Text(
                        'No history recorded for this entry.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.cardBorder),
                      itemBuilder: (_, i) => _HistoryTile(entry: entries[i]),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (err, _) => Text(
                    err.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
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

class _HistoryTile extends StatelessWidget {
  final CollectionHistoryEntryModel entry;

  const _HistoryTile({required this.entry});

  static const _fieldLabels = {
    'quantity_litres': 'Litres',
    'total_amount': 'Total (KES)',
    'shift': 'Shift',
    'status': 'Status',
    'notes': 'Notes',
  };

  String get _title {
    switch (entry.action) {
      case 'CREATE':
        return 'Recorded';
      case 'UPDATE':
        return 'Edited';
      case 'STATUS':
        return 'Status changed';
      case 'VOID':
        return 'Voided';
      default:
        return entry.action;
    }
  }

  IconData get _icon {
    switch (entry.action) {
      case 'CREATE':
        return Icons.add_circle_outline_rounded;
      case 'STATUS':
        return Icons.verified_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  String _formatTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '')?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  Map<String, dynamic> _decode(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Human-readable "Field: old → new" lines for the fields that changed.
  List<String> _changes() {
    final before = _decode(entry.oldValues);
    final after = _decode(entry.newValues);
    if (entry.action == 'CREATE') {
      return [
        if (after['quantity_litres'] != null) 'Litres: ${after['quantity_litres']}',
        if (after['price_per_litre'] != null) 'Rate: KES ${after['price_per_litre']}/L',
      ];
    }
    final lines = <String>[];
    _fieldLabels.forEach((key, label) {
      final oldValue = before[key];
      final newValue = after[key];
      if (oldValue != newValue) {
        lines.add('$label: ${oldValue ?? '—'} → ${newValue ?? '—'}');
      }
    });
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final changes = _changes();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_title by ${entry.actorName ?? 'unknown'}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                _formatTime(entry.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              for (final line in changes)
                Text(line, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (entry.reason != null && entry.reason!.isNotEmpty)
                Text(
                  'Reason: ${entry.reason}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
