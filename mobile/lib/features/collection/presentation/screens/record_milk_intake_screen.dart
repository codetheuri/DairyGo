import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../members/data/models/member_model.dart';
import '../../../members/presentation/controllers/member_controller.dart';
import '../../../members/presentation/widgets/farmer_picker_sheet.dart';
import '../../data/models/milk_collection_model.dart';
import '../controllers/collection_controller.dart';

class RecordMilkIntakeScreen extends ConsumerStatefulWidget {
  final String? initialMemberId;

  const RecordMilkIntakeScreen({super.key, this.initialMemberId});

  @override
  ConsumerState<RecordMilkIntakeScreen> createState() =>
      _RecordMilkIntakeScreenState();
}

class _RecordMilkIntakeScreenState
    extends ConsumerState<RecordMilkIntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  MemberModel? _selectedMember;
  String _selectedShift = 'MORNING';
  final _litresController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _litresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final member = _selectedMember ?? _initialMember();
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer member')),
      );
      return;
    }

    final litres = double.tryParse(_litresController.text.trim());
    if (litres == null || litres <= 0) return;

    final request = RecordCollectionRequestModel(
      memberId: member.id,
      shift: _selectedShift,
      quantityLitres: litres,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final success = await ref
        .read(recordMilkCollectionControllerProvider.notifier)
        .recordCollection(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully recorded ${litres.toStringAsFixed(1)} Litres milk intake!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  /// The farmer passed in from their profile ("Record milk"), once loaded.
  MemberModel? _initialMember() {
    final id = widget.initialMemberId;
    if (id == null || id.isEmpty) return null;
    return ref.watch(memberDetailsProvider(id)).valueOrNull;
  }

  Future<void> _pickFarmer() async {
    final picked = await FarmerPickerSheet.show(
      context,
      selectedMemberId: (_selectedMember ?? _initialMember())?.id,
    );
    if (picked != null && mounted) setState(() => _selectedMember = picked);
  }

  @override
  Widget build(BuildContext context) {
    final activePriceAsync = ref.watch(activeMilkPriceProvider);
    final recordState = ref.watch(recordMilkCollectionControllerProvider);

    final isLoading = recordState.isLoading;
    final errorMessage = recordState.hasError
        ? recordState.error.toString().replaceAll('Exception: ', '')
        : null;

    final priceText = activePriceAsync.when(
      data: (p) => 'KES ${p.pricePerLitre.toStringAsFixed(2)} / Litre',
      loading: () => 'Loading…',
      error: (_, __) => 'No price set for today',
    );
    final selectedMember = _selectedMember ?? _initialMember();
    final hasMember = selectedMember != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Record Milk Intake',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Buying Price Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Sacco Buying Rate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Searchable Farmer Selector Field
                  Text(
                    'Farmer Member *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _pickFarmer,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasMember
                                ? AppColors.primary
                                : AppColors.cardBorder,
                            width: hasMember ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accentMint,
                              foregroundColor: AppColors.primary,
                              child: Icon(
                                hasMember
                                    ? Icons.person_rounded
                                    : Icons.person_search_rounded,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: selectedMember != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedMember.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${selectedMember.membershipNumber} • ${selectedMember.phone}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Tap to search or register a farmer',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_circle_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shift Selection
                  Text(
                    'Collection Shift',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'MORNING',
                        label: Text('Morning Shift'),
                        icon: Icon(Icons.wb_sunny_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'EVENING',
                        label: Text('Evening Shift'),
                        icon: Icon(Icons.nights_stay_outlined, size: 18),
                      ),
                    ],
                    selected: {_selectedShift},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedShift = set.first),
                  ),
                  const SizedBox(height: 20),

                  // Litres Input Field
                  AppTextField(
                    label: 'Milk Quantity (Litres) *',
                    controller: _litresController,
                    hint: 'e.g. 15.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: Icons.water_drop_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Litres is required';
                      }
                      final d = double.tryParse(val.trim());
                      if (d == null || d <= 0) {
                        return 'Enter a valid milk quantity in litres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes Input
                  AppTextField(
                    label: 'Notes / Remarks (Optional)',
                    controller: _notesController,
                    hint: 'e.g. Quality verified',
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Record Milk Intake',
                    icon: Icons.check_circle_rounded,
                    onPressed: isLoading ? null : _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const LoadingOverlay(message: 'Recording milk intake...'),
        ],
      ),
    );
  }
}
