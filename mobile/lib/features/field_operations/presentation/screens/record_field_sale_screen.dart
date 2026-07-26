import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/field_ops_models.dart';
import '../controllers/field_ops_controller.dart';

class RecordFieldSaleScreen extends ConsumerStatefulWidget {
  const RecordFieldSaleScreen({super.key});

  @override
  ConsumerState<RecordFieldSaleScreen> createState() => _RecordFieldSaleScreenState();
}

class _RecordFieldSaleScreenState extends ConsumerState<RecordFieldSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _litresController = TextEditingController();
  final _unitPriceController = TextEditingController(text: '60.00');
  final _notesController = TextEditingController();

  String _paymentStatus = 'PAID';
  String _paymentMethod = 'CASH';
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _litresController.addListener(_recalculateTotal);
    _unitPriceController.addListener(_recalculateTotal);
  }

  @override
  void dispose() {
    _litresController.removeListener(_recalculateTotal);
    _unitPriceController.removeListener(_recalculateTotal);
    _litresController.dispose();
    _unitPriceController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    final litres = double.tryParse(_litresController.text.trim()) ?? 0.0;
    final price = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    setState(() {
      _totalRevenue = litres * price;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final litres = double.parse(_litresController.text.trim());
    final price = double.parse(_unitPriceController.text.trim());

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final request = RecordSaleRequestModel(
      saleDate: todayStr,
      buyerName: _buyerNameController.text.trim(),
      buyerPhone: _buyerPhoneController.text.trim().isNotEmpty
          ? _buyerPhoneController.text.trim()
          : null,
      quantityLitres: litres,
      unitPrice: price,
      paymentStatus: _paymentStatus,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await ref
        .read(recordSaleControllerProvider.notifier)
        .recordSale(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Direct Sale of ${litres.toStringAsFixed(1)}L to ${_buyerNameController.text} recorded!',
          ),
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
    final errorMessage = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Direct Field Sale', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    label: 'Buyer / Establishment Name *',
                    controller: _buyerNameController,
                    hint: 'e.g. Hotel Safari / Local Dairy Processor',
                    prefixIcon: Icons.storefront_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Buyer name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Buyer Phone Number (Optional)',
                    controller: _buyerPhoneController,
                    hint: 'e.g. 0711223344',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 14),

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
                            if (val == null || val.trim().isEmpty) return 'Litres required';
                            final d = double.tryParse(val.trim());
                            if (d == null || d <= 0) return 'Invalid litres';
                            return null;
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
                            if (val == null || val.trim().isEmpty) return 'Price required';
                            final d = double.tryParse(val.trim());
                            if (d == null || d <= 0) return 'Invalid price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Revenue Card
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
                        const Text(
                          'Total Sales Revenue:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        Text(
                          'KES ${_totalRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method & Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                                DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                                DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
                              ],
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Status',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentStatus,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.cardBorder),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                                DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                              ],
                              onChanged: (val) => setState(() => _paymentStatus = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Notes / Remarks (Optional)',
                    controller: _notesController,
                    hint: 'e.g. Receipt #1042 issued',
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Record Direct Field Sale',
                    icon: Icons.check_circle_rounded,
                    onPressed: isLoading ? null : _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(message: 'Recording direct sale...'),
        ],
      ),
    );
  }
}
