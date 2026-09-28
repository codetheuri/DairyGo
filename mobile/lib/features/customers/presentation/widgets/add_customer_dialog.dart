import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/customer_models.dart';
import '../controllers/customer_controller.dart';

/// Quick form to add a customer. Pops with the created [CustomerModel].
class AddCustomerDialog extends ConsumerStatefulWidget {
  /// Prefills the name, e.g. with what the collector typed in the search box.
  final String initialName;

  const AddCustomerDialog({super.key, this.initialName = ''});

  static Future<CustomerModel?> show(
    BuildContext context, {
    String initialName = '',
  }) {
    return showDialog<CustomerModel>(
      context: context,
      builder: (_) => AddCustomerDialog(initialName: initialName),
    );
  }

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  String _type = 'INDIVIDUAL';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceController.text.trim());
    final customer = await ref
        .read(customerActionsProvider.notifier)
        .create(
          CreateCustomerRequestModel(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            customerType: _type,
            defaultPricePerLitre: price != null && price > 0 ? price : null,
          ),
        );
    if (customer != null && mounted) Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerActionsProvider);
    final error = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return AlertDialog(
      title: const Text(
        'Add Customer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Text(
                  error,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
                const SizedBox(height: 10),
              ],
              AppTextField(
                label: 'Customer / Business Name *',
                controller: _nameController,
                hint: 'e.g. Kiambu Cooler',
                prefixIcon: Icons.storefront_rounded,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Phone (optional)',
                controller: _phoneController,
                hint: 'e.g. 0722000001',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Customer type'),
                items: [
                  for (final t in customerTypes)
                    DropdownMenuItem(
                      value: t,
                      child: Text(customerTypeLabel(t)),
                    ),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Agreed price per litre (optional)',
                controller: _priceController,
                hint: 'Prefilled on sales to this customer',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.payments_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v.trim());
                  return (d == null || d < 0) ? 'Invalid price' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Add Customer'),
        ),
      ],
    );
  }
}
