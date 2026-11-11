import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

/// One supplier: bills with what is left to pay, money taken from farmers
/// for them, and every payment.
class SupplierScreen extends ConsumerWidget {
  final String id;

  const SupplierScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRecord =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canRecordExpenses ??
        false;
    final detail = ref.watch(supplierProvider(id));
    final s = detail.valueOrNull?.supplier;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s?.name ?? 'Supplier',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canRecord && s != null)
            IconButton(
              tooltip: 'Change',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => SupplierFormSheet.show(context, existing: s),
            ),
        ],
      ),
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(supplierProvider(id).future),
          child: detail.when(
            loading: () => const ListSkeleton(rows: 5),
            error: (e, _) => ErrorView(
              message: errorText(e),
              onRetry: () => ref.invalidate(supplierProvider(id)),
            ),
            data: (d) => _Body(d: d, canRecord: canRecord),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final SupplierDetail d;
  final bool canRecord;

  const _Body({required this.d, required this.canRecord});

  static final _day = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = d.supplier;
    final service = ref.read(financeServiceProvider);
    final paysOver = s.isPayee || s.held != 0 || d.taken.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        FigureGrid(
          figures: [
            Figure(
              'Bills to pay',
              kes(s.billsOwed, cents: false),
              color: s.billsOwed > 0 ? AppColors.error : null,
            ),
            if (paysOver) Figure('To pay over', kes(s.held, cents: false)),
          ],
        ),
        if ((s.phone ?? '').isNotEmpty || (s.notes ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              [s.phone, s.notes].whereType<String>().join(' · '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        if (canRecord)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      BillFormSheet.show(context, supplierId: s.id),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Record a bill'),
                ),
                if (s.held > 0)
                  FilledButton.icon(
                    onPressed: () => SupplierPaymentSheet.payOver(context, s),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Pay over'),
                  ),
              ],
            ),
          ),
        if (paysOver) ...[
          const _Heading('Taken from farmers\' pay for them'),
          if (d.deductions.isNotEmpty)
            Text(
              'Deductions now: ${d.deductions.join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          if (d.taken.isEmpty)
            const _Empty(
              'Nothing taken yet: it is taken when a pay run is approved.',
            ),
          for (final t in d.taken)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(t.name),
              subtitle: Text(
                '${_day.format(t.date)} · ${t.farmers} ${t.farmers == 1 ? 'farmer' : 'farmers'}',
              ),
              trailing: Text(
                kes(t.amount, cents: false),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
        const _Heading('Bills'),
        if (d.bills.isEmpty) const _Empty('No bills.'),
        for (final b in d.bills)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: canRecord && !b.voided && b.unpaid > 0
                ? () => SupplierPaymentSheet.payBill(context, b)
                : null,
            onLongPress: canRecord && !b.voided
                ? () => voidWithReason(
                    context,
                    ref,
                    title: 'Void this bill?',
                    detail: '${b.category}: ${kes(b.amount)}',
                    run: (r) => service.voidBill(b.id, r),
                  )
                : null,
            title: Text(
              [
                b.category,
                if ((b.reference ?? '').isNotEmpty) b.reference!,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: b.voided ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              [
                _day.format(b.date),
                if (b.voided)
                  'voided'
                else if (b.unpaid <= 0)
                  'paid'
                else ...[
                  '${kes(b.unpaid, cents: false)} to pay',
                  if (b.dueDate != null) 'due ${_day.format(b.dueDate!)}',
                ],
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color:
                    !b.voided &&
                        b.unpaid > 0 &&
                        b.dueDate != null &&
                        b.dueDate!.isBefore(DateTime.now())
                    ? AppColors.error
                    : null,
              ),
            ),
            trailing: Text(
              kes(b.amount, cents: false),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        const _Heading('Payments'),
        if (d.payments.isEmpty) const _Empty('No payments yet.'),
        for (final p in d.payments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onLongPress: canRecord && !p.voided
                ? () => voidWithReason(
                    context,
                    ref,
                    title: 'Void this payment?',
                    detail: '${kes(p.amount)} from ${p.account}',
                    run: (r) => service.voidSupplierPayment(p.id, r),
                  )
                : null,
            title: Text(
              p.kind == 'PAY_OVER' ? 'Paid over' : 'Bill paid',
              style: TextStyle(
                decoration: p.voided ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              [
                _day.format(p.date),
                p.account,
                if ((p.reference ?? '').isNotEmpty) p.reference!,
                if (p.voided) 'voided',
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              kes(p.amount, cents: false),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        if (canRecord && (d.bills.isNotEmpty || d.payments.isNotEmpty))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tap a bill to pay it. Recorded by mistake? Hold it to void.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
  );
}
