import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audit_history_list.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../data/transfer_models.dart';
import '../transfer_controller.dart';
import 'transfer_tile.dart';

/// A transfer's details and history. The sender (on the day it was recorded)
/// and admins can correct the litres or cancel it; the server applies the
/// same rule.
class TransferDetailSheet extends ConsumerWidget {
  final MilkTransferModel transfer;

  const TransferDetailSheet({super.key, required this.transfer});

  static Future<void> show(BuildContext context, MilkTransferModel transfer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => TransferDetailSheet(transfer: transfer),
    );
  }

  static const _fieldLabels = {
    'quantity_litres': 'Litres',
    'to_collector_id': 'Receiver',
    'notes': 'Note',
  };

  /// Whether the signed-in user may correct or cancel [t] now.
  static bool canChange(
    MilkTransferModel t, {
    required int userId,
    required bool isAdmin,
  }) {
    if (t.isCancelled) return false;
    if (isAdmin) return true;
    final recordedDay = t.createdAt == null
        ? t.day
        : DateTime.tryParse(
            t.createdAt!,
          )?.toLocal().toString().split(' ').first;
    return t.fromCollectorId == userId && recordedDay == getTodayDateString();
  }

  Future<void> _correct(
    BuildContext context,
    WidgetRef ref,
    bool needsReason,
  ) async {
    final litres = TextEditingController(
      text: transfer.quantityLitres.toString(),
    );
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Correct the litres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: litres,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Litres',
                suffixText: 'L',
              ),
            ),
            if (needsReason)
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Reason *'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final value = double.tryParse(litres.text.trim());
    if (value == null || value <= 0) {
      _tell(context, 'Enter the litres, more than 0', error: true);
      return;
    }
    final error = await ref
        .read(transferActionsProvider)
        .correct(
          transfer.id,
          litres: value,
          reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
        );
    if (!context.mounted) return;
    _tell(
      context,
      error ?? 'Transfer corrected to ${litresText(value)}',
      error: error != null,
    );
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this transfer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${litresText(transfer.quantityLitres)} go back from '
              '${transfer.toCollectorName} to ${transfer.fromCollectorName}. '
              'It stays in the history.',
            ),
            TextField(
              controller: reason,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                hintText: 'e.g. recorded twice',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () {
              if (reason.text.trim().length >= 3) {
                Navigator.of(ctx).pop(reason.text.trim());
              }
            },
            child: const Text(
              'Cancel transfer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (text == null || !context.mounted) return;
    final error = await ref
        .read(transferActionsProvider)
        .cancel(transfer.id, text);
    if (!context.mounted) return;
    _tell(context, error ?? 'Transfer cancelled', error: error != null);
    if (error == null) Navigator.of(context).pop();
  }

  static void _tell(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? null : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdmin = user?.canManageTransfers ?? false;
    final userId = user?.id ?? 0;
    final changeable = canChange(transfer, userId: userId, isAdmin: isAdmin);
    final historyAsync = ref.watch(transferHistoryProvider(transfer.id));
    final t = transfer;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    '${litresText(t.quantityLitres)} transferred',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (t.isCancelled)
                  const StatusPill(status: 'CANCELLED', type: StatusType.error),
              ],
            ),
            const SizedBox(height: 12),
            _Row(
              icon: Icons.call_made_rounded,
              label: 'From',
              value: t.fromCollectorName,
            ),
            _Row(
              icon: Icons.call_received_rounded,
              label: 'To',
              value: t.toCollectorName,
            ),
            _Row(
              icon: Icons.event_rounded,
              label: 'Day',
              value: [
                t.day,
                if (transferTime(t.createdAt).isNotEmpty)
                  'saved ${transferTime(t.createdAt)}',
              ].join(' · '),
            ),
            if (t.notes != null && t.notes!.isNotEmpty)
              _Row(icon: Icons.notes_rounded, label: 'Note', value: t.notes!),
            if (t.isCancelled && t.voidReason != null)
              _Row(
                icon: Icons.block_rounded,
                label: 'Cancelled',
                value: t.voidReason!,
                color: AppColors.error,
              ),
            if (changeable) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Correct litres'),
                    onPressed: () => _correct(
                      context,
                      ref,
                      isAdmin && t.fromCollectorId != userId,
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Cancel transfer'),
                    onPressed: () => _cancel(context, ref),
                  ),
                ],
              ),
            ] else if (!t.isCancelled && t.toCollectorId == userId) ...[
              const SizedBox(height: 12),
              const Text(
                'If this is wrong, ask the sender or an admin to correct it.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                      'Litres: ${v['quantity_litres']}',
                  ],
                ),
                loading: () => const ListSkeleton(rows: 3),
                error: (e, _) => Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    ),
  );
}
