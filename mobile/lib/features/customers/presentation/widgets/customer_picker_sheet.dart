import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/customer_models.dart';
import '../controllers/customer_controller.dart';
import 'add_customer_dialog.dart';

/// Search-as-you-type picker for the customer of a sale. If the customer does
/// not exist yet, "Add customer" creates it and returns it selected.
class CustomerPickerSheet extends ConsumerStatefulWidget {
  const CustomerPickerSheet({super.key});

  static Future<CustomerModel?> show(BuildContext context) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const CustomerPickerSheet(),
    );
  }

  @override
  ConsumerState<CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<CustomerPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _addNew() async {
    final created = await AddCustomerDialog.show(
      context,
      initialName: _searchController.text.trim(),
    );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(customerPickerResultsProvider(_query));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Customer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addNew,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                _searchController.text.trim().isEmpty
                    ? 'Add new customer'
                    : 'Add "${_searchController.text.trim()}" as new customer',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching customers. Add a new one above.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (_, i) {
                      final c = customers[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentMint,
                          foregroundColor: AppColors.primary,
                          child: Icon(
                            c.customerType == 'COOLER'
                                ? Icons.ac_unit_rounded
                                : Icons.storefront_rounded,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            customerTypeLabel(c.customerType),
                            if (c.phone != null) c.phone!,
                            if (c.defaultPricePerLitre != null)
                              'KES ${c.defaultPricePerLitre!.toStringAsFixed(2)}/L',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
