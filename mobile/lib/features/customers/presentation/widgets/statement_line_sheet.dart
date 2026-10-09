import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/late_entry_note.dart';
import '../../data/models/customer_models.dart';

/// One customer statement line in full: what it was, the rate, how it was
/// paid, and who recorded it and when.
class StatementLineSheet extends StatelessWidget {
  final StatementLineModel line;

  const StatementLineSheet({super.key, required this.line});

  static Future<void> show(BuildContext context, StatementLineModel line) =>
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => StatementLineSheet(line: line),
      );

  static String _kes(double v) => 'KES ${v.toStringAsFixed(2)}';

  static String _method(String? m) => switch (m) {
    'MPESA' => 'M-Pesa',
    'CASH' => 'Cash',
    'BANK_TRANSFER' => 'Bank',
    'CHEQUE' => 'Cheque',
    'CREDIT' => 'Credit (not paid)',
    null || '' => '',
    _ => m,
  };

  /// "5 Oct 2026, 10:42" from the server's time.
  static String _when(String? at) {
    final t = DateTime.tryParse(at ?? '')?.toLocal();
    if (t == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.day} ${months[t.month - 1]} ${t.year}, ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final sale = line.kind != 'PAYMENT';
    final rows = <(String, String)>[
      ('Date', line.date.split('T').first),
      if (sale && line.litres > 0)
        (
          'Milk',
          '${line.litres.toStringAsFixed(1)} L'
              '${line.rate > 0 ? ' @ ${_kes(line.rate)}' : ''}',
        ),
      if (sale) ('Sale total', _kes(line.debit)),
      if (sale && line.credit > 0) ('Paid at the sale', _kes(line.credit)),
      if (!sale) ('Amount paid', _kes(line.credit)),
      if (_method(line.method).isNotEmpty) ('Paid by', _method(line.method)),
      if ((line.reference ?? '').isNotEmpty) ('Reference', line.reference!),
      ('Balance after', _kes(line.balance)),
      (sale ? 'Sold by' : 'Recorded by', line.recordedBy ?? 'Not known'),
      if (_when(line.recordedAt).isNotEmpty)
        ('Entered on', _when(line.recordedAt)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sale ? 'Milk sale' : 'Payment',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          LateEntryNote(reason: line.lateReason),
        ],
      ),
    );
  }
}
