import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../report_downloads/presentation/widgets/file_download_sheet.dart';
import '../../data/payout_models.dart';
import '../../data/payout_service.dart';
import '../payout_providers.dart';
import 'mark_paid_sheet.dart';

/// One farmer's pay in a run, line by line, with their payslip.
class PayslipSheet extends ConsumerWidget {
  final PayRun run;
  final PayLine line;

  const PayslipSheet({super.key, required this.run, required this.line});

  static Future<void> show(
    BuildContext context, {
    required PayRun run,
    required PayLine line,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => PayslipSheet(run: run, line: line),
  );

  Widget _row(String label, double amount, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kes(amount),
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final l = line;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l.name} · ${l.number}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            periodLabel(run.from, run.to),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _row('Milk (${litres(l.litres)})', l.gross),
          if (l.opening != 0)
            _row(
              l.opening < 0 ? 'Owed from last pay' : 'Brought forward',
              l.opening,
            ),
          if (l.entries != 0)
            _row('Advances, charges and adjustments', l.entries),
          for (final i in l.items)
            _row(i.savings ? '${i.name} (savings)' : i.name, -i.amount),
          const Divider(),
          _row('Net pay', l.net, bold: true, color: AppColors.primary),
          if (l.closing < 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${l.name.split(' ').first} owes ${kes(-l.closing)}, taken from the next pay.',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (l.isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Paid ${shortDate(l.paidAt!)} · ${l.paidLabel} ${l.paidReference ?? ''}'
                    .trim(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            [
              if ((l.mpesa ?? '').isNotEmpty) 'M-Pesa ${l.mpesa}',
              if ((l.bankAccount ?? '').isNotEmpty)
                '${l.bank ?? 'Bank'} ${l.bankAccount}',
              if ((l.mpesa ?? '').isEmpty && (l.bankAccount ?? '').isEmpty)
                'Phone ${l.phone}',
            ].join(' · '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => FileDownloadSheet.show(
                    context,
                    title: 'Payslip: ${l.name}',
                    path: PayoutService.payslipPath(run.id, l.memberId),
                    fallbackName: 'payslip-${l.number}.pdf',
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Payslip'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/members/${l.memberId}/account');
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Account'),
                ),
              ),
            ],
          ),
          if (run.isApproved && l.toPay && (user?.canPayFarmers ?? false)) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final done = await MarkPaidSheet.show(
                  context,
                  runId: run.id,
                  lineId: l.id,
                  farmer: l.name,
                  amount: l.net,
                );
                if (done == true) {
                  ref.invalidate(payRunProvider(run.id));
                  ref.invalidate(payRunsProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.done_rounded),
              label: const Text('Mark paid'),
            ),
          ],
        ],
      ),
    );
  }
}
