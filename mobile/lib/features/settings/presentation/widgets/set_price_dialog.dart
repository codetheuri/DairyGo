import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../data/models/settings_models.dart';
import '../controllers/settings_controller.dart';

class SetPriceDialog extends ConsumerStatefulWidget {
  final double? currentPrice;

  const SetPriceDialog({super.key, this.currentPrice});

  @override
  ConsumerState<SetPriceDialog> createState() => _SetPriceDialogState();
}

class _SetPriceDialogState extends ConsumerState<SetPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  final _reasonController = TextEditingController();
  late String _effectiveDate;

  /// What this price changes, once checked. Changing the price or the date
  /// clears it, so the person never saves what they did not see.
  SaccoPriceCheck? _check;
  String? _checkedPrice;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice != null
          ? widget.currentPrice!.toStringAsFixed(2)
          : '50.00',
    );
    _effectiveDate = getTodayDateString();
    _priceController.addListener(() {
      if (_check != null && _priceController.text != _checkedPrice) {
        setState(() => _check = null);
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newPrice = double.parse(_priceController.text.trim());
    final request = SetPriceRequestModel(
      pricePerLitre: newPrice,
      effectiveDate: _effectiveDate,
    );
    final controller = ref.read(setMilkPriceControllerProvider.notifier);

    // First see what it changes; when it touches recorded milk or a paid
    // month, show that and wait for the second tap.
    if (_check == null) {
      final check = await controller.check(request);
      if (check == null || !mounted) return;
      if (check.worthShowing) {
        setState(() {
          _check = check;
          _checkedPrice = _priceController.text;
        });
        return;
      }
    }

    final reason = _reasonController.text.trim();
    final saved = await controller.setMilkPrice(
      request,
      reason: reason.isEmpty ? null : reason,
    );
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved.repriced > 0
              ? 'Buying price set to KES ${newPrice.toStringAsFixed(2)}/L. ${_records(saved.repriced)} repriced.'
              : 'Active buying price set to KES ${newPrice.toStringAsFixed(2)}/L!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  static String _records(int n) =>
      '${thousands(n, decimals: 0)} milk ${n == 1 ? 'record' : 'records'}';

  /// What the checked price changes, line by line.
  List<String> _checkLines(SaccoPriceCheck check) {
    // Paid milk stays, so the first day to change may be after the date typed.
    final paid = check.paidThrough;
    final first = paid == null
        ? DateTime.parse(_effectiveDate)
        : DateTime(paid.year, paid.month, paid.day + 1);
    final from = DateFormat('d MMM y').format(first);
    final price = kes(double.parse(_priceController.text.trim()));
    final change = check.valueChange;
    return [
      if (check.repriced > 0)
        '${_records(check.repriced)} from $from go to $price/L'
            '${change == 0 ? '' : ': ${kes(change.abs())} ${change > 0 ? 'more' : 'less'} for ${check.farmers} ${check.farmers == 1 ? 'farmer' : 'farmers'}'}.',
      if (check.ownPriceFarmers > 0)
        '${check.ownPriceFarmers} ${check.ownPriceFarmers == 1 ? 'farmer' : 'farmers'} on their own price stay on it.',
      if (check.paidThrough != null)
        'Milk up to ${DateFormat('d MMM y').format(check.paidThrough!)} is in an approved pay run and keeps its price. '
            'To change it, cancel that pay run first. That is possible only before anyone is paid.',
      if (check.repriced > 0)
        'If a pay run is a draft, open it and tap Work out again before approving.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setMilkPriceControllerProvider);
    final isLoading = state.isLoading;
    final check = _check;
    final errorMsg = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.currentPrice != null
                            ? 'Configure Buying Price'
                            : 'Set Initial Milk Price',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
                    child: Text(
                      errorMsg,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                AppTextField(
                  label: 'Price per Litre (KES) *',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.payments_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Price is required';
                    }
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
                        _check = null;
                        _effectiveDate =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Effective Date:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _effectiveDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (check != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in _checkLines(check))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              line,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (check.repriced > 0) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Why? (kept in each record\'s history) *',
                      controller: _reasonController,
                      hint: 'e.g. Board agreed 45 from October',
                      validator: (val) => (val ?? '').trim().length < 3
                          ? 'Say why the price is changing'
                          : null,
                    ),
                  ],
                ],
                const SizedBox(height: 22),

                PrimaryButton(
                  label: isLoading
                      ? 'Please wait...'
                      : check == null
                      ? 'Set Active Price Rate'
                      : check.repriced > 0
                      ? 'Save and reprice'
                      : 'Save price',
                  icon: Icons.check_circle_rounded,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
