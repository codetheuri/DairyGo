import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../../customers/presentation/widgets/customer_picker_sheet.dart';
import '../../data/models/field_ops_models.dart';
import '../controllers/field_ops_controller.dart';

/// How the customer settled the sale at the time of sale.
enum _Settlement { full, partial, credit }

/// Records milk sold to a customer. Every litre leaving the collector is a sale,
/// including deliveries to coolers. The collector picks the customer (or adds a
/// new one), and anything not paid now goes on the customer's balance.
class RecordFieldSaleScreen extends ConsumerStatefulWidget {
  /// Preselects the customer, e.g. when opened from a customer's page.
  final CustomerModel? initialCustomer;

  const RecordFieldSaleScreen({super.key, this.initialCustomer});

  @override
  ConsumerState<RecordFieldSaleScreen> createState() => _RecordFieldSaleScreenState();
}

class _RecordFieldSaleScreenState extends ConsumerState<RecordFieldSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _litresController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerModel? _customer;
  String? _customerError;
  _Settlement _settlement = _Settlement.full;
  String _paymentMethod = 'CASH';
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _litresController.addListener(_recalculateTotal);
    _unitPriceController.addListener(_recalculateTotal);
    if (widget.initialCustomer != null) _selectCustomer(widget.initialCustomer!);
  }

  @override
  void dispose() {
    _litresController.dispose();
    _unitPriceController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    final litres = double.tryParse(_litresController.text.trim()) ?? 0.0;
    final price = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    setState(() => _total = litres * price);
  }

  void _selectCustomer(CustomerModel customer) {
    _customer = customer;
    _customerError = null;
    if (customer.defaultPricePerLitre != null) {
      _unitPriceController.text = customer.defaultPricePerLitre!.toStringAsFixed(2);
    }
    // Coolers and processors usually buy on credit and settle later.
    if (customer.customerType == 'COOLER' || customer.customerType == 'PROCESSOR') {
      _settlement = _Settlement.credit;
    }
    _recalculateTotal();
  }

  Future<void> _pickCustomer() async {
    final picked = await CustomerPickerSheet.show(context);
    if (picked != null) setState(() => _selectCustomer(picked));
  }

  double get _amountPaid {
    switch (_settlement) {
      case _Settlement.full:
        return double.parse(_total.toStringAsFixed(2));
      case _Settlement.partial:
        return double.tryParse(_amountPaidController.text.trim()) ?? 0;
      case _Settlement.credit:
        return 0;
    }
  }

  Future<void> _submitForm() async {
    final formOk = _formKey.currentState!.validate();
    if (_customer == null) {
      setState(() => _customerError = 'Select or add the customer');
      return;
    }
    if (!formOk) return;

    final request = RecordSaleRequestModel(
      customerId: _customer!.id,
      quantityLitres: double.parse(_litresController.text.trim()),
      unitPrice: double.parse(_unitPriceController.text.trim()),
      amountPaid: _amountPaid,
      paymentMethod: _settlement == _Settlement.credit ? 'CREDIT' : _paymentMethod,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await ref.read(recordSaleControllerProvider.notifier).recordSale(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale of ${request.quantityLitres.toStringAsFixed(1)}L to ${_customer!.name} recorded!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordSaleControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError ? state.error.toString().replaceAll('Exception: ', '') : null;
    final onCredit = (_total - _amountPaid).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Milk Sale', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(errorMessage, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Customer
                  Text('Customer *', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickCustomer,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _customerError != null ? AppColors.error : AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _customer?.customerType == 'COOLER' ? Icons.ac_unit_rounded : Icons.storefront_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _customer == null
                                ? const Text('Search or add customer (cooler, hotel, buyer…)',
                                    style: TextStyle(color: AppColors.textMuted))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_customer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        [
                                          customerTypeLabel(_customer!.customerType),
                                          if (_customer!.phone != null) _customer!.phone!,
                                        ].join(' • '),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  if (_customerError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_customerError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Quantity (Litres) *',
                          controller: _litresController,
                          hint: 'e.g. 20.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.water_drop_rounded,
                          validator: (val) {
                            final d = double.tryParse(val?.trim() ?? '');
                            return (d == null || d <= 0) ? 'Invalid litres' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Unit Price (KES/L) *',
                          controller: _unitPriceController,
                          hint: 'e.g. 60.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.payments_outlined,
                          validator: (val) {
                            final d = double.tryParse(val?.trim() ?? '');
                            return (d == null || d <= 0) ? 'Invalid price' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sale Total:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text(
                          'KES ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Settlement
                  Text('Payment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<_Settlement>(
                    segments: const [
                      ButtonSegment(value: _Settlement.full, label: Text('Paid in full', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: _Settlement.partial, label: Text('Part paid', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: _Settlement.credit, label: Text('Credit', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {_settlement},
                    onSelectionChanged: (s) => setState(() => _settlement = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (_settlement == _Settlement.partial) ...[
                    AppTextField(
                      label: 'Amount paid now (KES) *',
                      controller: _amountPaidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        final d = double.tryParse(val?.trim() ?? '');
                        if (d == null || d <= 0) return 'Enter the amount paid';
                        if (d >= _total) return 'Less than the total, or choose "Paid in full"';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_settlement != _Settlement.credit)
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                        DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                      ],
                      onChanged: (val) => setState(() => _paymentMethod = val ?? 'CASH'),
                    ),
                  if (onCredit > 0 && _total > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'KES ${onCredit.toStringAsFixed(2)} will be added to ${_customer?.name ?? 'the customer'}\'s balance.',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Notes / Remarks (Optional)',
                    controller: _notesController,
                    hint: 'e.g. Delivery note #1042',
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Record Sale',
                    icon: Icons.check_circle_rounded,
                    onPressed: isLoading ? null : _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(message: 'Recording sale...'),
        ],
      ),
    );
  }
}
