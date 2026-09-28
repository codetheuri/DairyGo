import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/customer_models.dart';
import '../controllers/customer_controller.dart';
import '../widgets/record_payment_dialog.dart';

/// A customer's details and, for admins and board members, their monthly
/// statement. Admins can record and void payments and (de)activate the customer.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  StatementQuery get _query {
    final today = DateTime.now();
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final to = lastDay.isAfter(today) ? today : lastDay;
    return (
      customerId: widget.customerId,
      fromDate: _date(_month),
      toDate: _date(to),
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  Future<void> _toggleStatus(CustomerModel c) async {
    final error = await ref
        .read(customerActionsProvider.notifier)
        .setStatus(c.id, c.isActive ? 'INACTIVE' : 'ACTIVE');
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _voidPayment(StatementLineModel line) async {
    final reason = await askVoidReason(
      context,
      title: 'Void payment of KES ${line.credit.toStringAsFixed(2)}?',
    );
    if (reason == null) return;
    final error = await ref
        .read(customerActionsProvider.notifier)
        .voidPayment(line.referenceId, reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Payment voided'),
          backgroundColor: error == null ? AppColors.success : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdmin = user?.isSaccoAdmin ?? false;
    final seesStatement =
        user?.isExecutive ?? false; // admins and board members
    final canSell = isAdmin || !(user?.isExecutive ?? false); // not board
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: customerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ErrorView(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.refresh(customerDetailProvider(widget.customerId)),
        ),
        data: (customer) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customerDetailProvider(widget.customerId));
            ref.invalidate(customerStatementProvider(_query));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(customer),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canSell && customer.isActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 18,
                      ),
                      label: const Text('Record Sale'),
                      onPressed: () =>
                          context.push(AppRoutes.recordSale, extra: customer),
                    ),
                  if (isAdmin)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text('Record Payment'),
                      onPressed: () async {
                        final ok = await RecordPaymentDialog.show(
                          context,
                          customer,
                        );
                        if (ok == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment recorded'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  if (isAdmin)
                    TextButton(
                      onPressed: () => _toggleStatus(customer),
                      child: Text(
                        customer.isActive ? 'Deactivate' : 'Reactivate',
                      ),
                    ),
                ],
              ),
              if (seesStatement) ...[
                const SizedBox(height: 20),
                _monthSelector(),
                const SizedBox(height: 8),
                _statement(isAdmin),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(CustomerModel c) {
    final balance = c.balance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              StatusPill(
                status: c.status,
                type: c.isActive ? StatusType.success : StatusType.warning,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              customerTypeLabel(c.customerType),
              if (c.phone != null) c.phone!,
              if (c.defaultPricePerLitre != null)
                'Agreed price KES ${c.defaultPricePerLitre!.toStringAsFixed(2)}/L',
            ].join(' • '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (balance != null) ...[
            const SizedBox(height: 12),
            Text(
              balance > 0
                  ? 'Owes KES ${balance.toStringAsFixed(2)}'
                  : balance < 0
                  ? 'In credit KES ${(-balance).toStringAsFixed(2)}'
                  : 'Fully settled',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: balance > 0 ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthSelector() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Statement',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () =>
              setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Text(
          '${_monthNames[_month.month - 1]} ${_month.year}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _isCurrentMonth
              ? null
              : () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
        ),
      ],
    );
  }

  Widget _statement(bool isAdmin) {
    final statementAsync = ref.watch(customerStatementProvider(_query));
    return statementAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Text(
        e.toString().replaceAll('Exception: ', ''),
        style: const TextStyle(color: AppColors.error),
      ),
      data: (st) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            _summaryRow('Opening balance', st.openingBalance, bold: true),
            const Divider(height: 1, color: AppColors.cardBorder),
            if (st.lines.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No sales or payments in this period.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            for (final line in st.lines) ...[
              ListTile(
                dense: true,
                leading: Icon(
                  line.kind == 'PAYMENT'
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: line.kind == 'PAYMENT'
                      ? AppColors.success
                      : AppColors.primary,
                  size: 20,
                ),
                title: Text(
                  line.description,
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  '${line.date}  •  '
                  '${line.debit > 0 ? '+${line.debit.toStringAsFixed(2)}  ' : ''}'
                  '${line.credit > 0 ? '−${line.credit.toStringAsFixed(2)}' : ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  line.balance.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onLongPress: isAdmin && line.kind == 'PAYMENT'
                    ? () => _voidPayment(line)
                    : null,
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
            ],
            _summaryRow('Sales in period', st.totalDebit),
            _summaryRow('Paid in period', -st.totalCredit),
            _summaryRow('Closing balance', st.closingBalance, bold: true),
            if (isAdmin && st.lines.any((l) => l.kind == 'PAYMENT'))
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Long-press a payment to void it.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('KES ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
