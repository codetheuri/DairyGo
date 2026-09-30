import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/transfer_models.dart';

/// Time of day a record was saved, e.g. 7:05 AM, or '' when unknown.
String transferTime(String? createdAt) {
  final parsed = createdAt == null ? null : DateTime.tryParse(createdAt);
  if (parsed == null) return '';
  final t = parsed.toLocal();
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';
}

String litresText(double v) =>
    '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} L';

/// One transfer in a list, as seen by [viewerId]: "To Bob −20 L" for the
/// sender, "From Alice +20 L" for the receiver, "Alice → Bob 20 L" for
/// anyone else (admins, board members).
class TransferTile extends StatelessWidget {
  final MilkTransferModel transfer;
  final int viewerId;
  final VoidCallback? onTap;

  /// Show the date too (lists spanning several days).
  final bool showDate;

  const TransferTile({
    super.key,
    required this.transfer,
    required this.viewerId,
    this.onTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = transfer;
    final sent = t.sentBy(viewerId);
    final (icon, color, title, amount) = switch (sent) {
      true => (
        Icons.call_made_rounded,
        AppColors.accentAmber,
        'To ${t.toCollectorName}',
        '−${litresText(t.quantityLitres)}',
      ),
      false => (
        Icons.call_received_rounded,
        AppColors.success,
        'From ${t.fromCollectorName}',
        '+${litresText(t.quantityLitres)}',
      ),
      null => (
        Icons.swap_horiz_rounded,
        AppColors.info,
        '${t.fromCollectorName} → ${t.toCollectorName}',
        litresText(t.quantityLitres),
      ),
    };
    final when = [
      if (showDate) t.day,
      transferTime(t.createdAt),
    ].where((s) => s.isNotEmpty).join(' • ');

    return Opacity(
      opacity: t.isCancelled ? 0.55 : 1,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  child: Icon(icon, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          decoration: t.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (when.isNotEmpty) when,
                          if (t.isCancelled) 'Cancelled',
                          if (t.notes != null && t.notes!.isNotEmpty) t.notes!,
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Received 20 L · Given 5 L" for report cards.
class TransferSummaryLine extends StatelessWidget {
  final double received;
  final double given;

  const TransferSummaryLine({
    super.key,
    required this.received,
    required this.given,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.info),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Transfers: received ${litresText(received)} · given ${litresText(given)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
