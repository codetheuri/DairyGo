import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../data/models/settings_models.dart';
import '../controllers/settings_controller.dart';

class SetPriceDialog extends ConsumerStatefulWidget {
  final double currentPrice;

  const SetPriceDialog({super.key, required this.currentPrice});

  @override
  ConsumerState<SetPriceDialog> createState() => _SetPriceDialogState();
}

class _SetPriceDialogState extends ConsumerState<SetPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late String _effectiveDate;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.currentPrice.toStringAsFixed(2));
    _effectiveDate = getTodayDateString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newPrice = double.parse(_priceController.text.trim());
    final request = SetPriceRequestModel(
      pricePerLitre: newPrice,
      effectiveDate: _effectiveDate,
    );

    final success = await ref
        .read(setMilkPriceControllerProvider.notifier)
        .setMilkPrice(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active buying price updated to KES ${newPrice.toStringAsFixed(2)}/L!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setMilkPriceControllerProvider);
    final isLoading = state.isLoading;
    final errorMsg = state.hasError ? state.error.toString().replaceAll('Exception: ', '') : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Buying Price',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(errorMsg, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],

              AppTextField(
                label: 'New Price per Litre (KES) *',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.payments_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Price is required';
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _effectiveDate =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Effective Date:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      Text(
                        _effectiveDate,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              PrimaryButton(
                label: isLoading ? 'Saving New Rate...' : 'Set Active Price Rate',
                icon: Icons.check_circle_rounded,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
