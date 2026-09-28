import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/customer_models.dart';
import '../controllers/customer_controller.dart';

/// Admin form to record money received from a customer. Pops with true on success.
class RecordPaymentDialog extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const RecordPaymentDialog({super.key, required this.customer});

  static Future<bool?> show(BuildContext context, CustomerModel customer) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RecordPaymentDialog(customer: customer),
    );
  }

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _method = 'MPESA';
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(customerActionsProvider.notifier)
        .recordPayment(
          widget.customer.id,
          RecordPaymentRequestModel(
            amount: double.parse(_amountController.text.trim()),
            method: _method,
            reference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(customerActionsProvider).isLoading;
    final balance = widget.customer.balance;

    return AlertDialog(
      title: Text(
        'Payment from ${widget.customer.name}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (balance != null)
                Text(
                  'Currently owes KES ${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Amount received (KES) *',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.payments_rounded,
                validator: (v) {
                  final d = double.tryParse(v?.trim() ?? '');
                  return (d == null || d <= 0)
                      ? 'Enter a positive amount'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'BANK_TRANSFER',
                    child: Text('Bank Transfer'),
                  ),
                  DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'CASH'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Reference (e.g. M-Pesa code)',
                controller: _referenceController,
                prefixIcon: Icons.tag_rounded,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: isLoading ? null : _submit,
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}

/// Asks for a reason before voiding something. Returns the reason, or null if cancelled.
Future<String?> askVoidReason(BuildContext context, {required String title}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Reason *',
          hintText: 'e.g. recorded twice',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.length >= 3) Navigator.of(ctx).pop(reason);
          },
          child: const Text('Void', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}
