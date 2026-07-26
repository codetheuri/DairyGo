import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../members/data/models/member_model.dart';
import '../../../members/presentation/controllers/member_controller.dart';
import '../../data/models/milk_collection_model.dart';
import '../controllers/collection_controller.dart';

class RecordMilkIntakeScreen extends ConsumerStatefulWidget {
  final String? initialMemberId;

  const RecordMilkIntakeScreen({super.key, this.initialMemberId});

  @override
  ConsumerState<RecordMilkIntakeScreen> createState() => _RecordMilkIntakeScreenState();
}

class _RecordMilkIntakeScreenState extends ConsumerState<RecordMilkIntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMemberId;
  String _selectedShift = 'MORNING';
  final _litresController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.initialMemberId;
  }

  @override
  void dispose() {
    _litresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null || _selectedMemberId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer member')),
      );
      return;
    }

    final litres = double.tryParse(_litresController.text.trim());
    if (litres == null || litres <= 0) return;

    final request = RecordCollectionRequestModel(
      memberId: _selectedMemberId!,
      shift: _selectedShift,
      quantityLitres: litres,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await ref
        .read(recordMilkCollectionControllerProvider.notifier)
        .recordCollection(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully recorded ${litres.toStringAsFixed(1)} Litres milk intake!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  void _showSearchableFarmerPicker(List<MemberModel> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SearchableFarmerPickerBottomSheet(
          members: members,
          selectedMemberId: _selectedMemberId,
          onSelected: (member) {
            setState(() {
              _selectedMemberId = member.id;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePriceAsync = ref.watch(activeMilkPriceProvider);
    final membersAsync = ref.watch(membersListProvider);
    final recordState = ref.watch(recordMilkCollectionControllerProvider);

    final isLoading = recordState.isLoading;
    final errorMessage = recordState.hasError
        ? recordState.error.toString().replaceAll('Exception: ', '')
        : null;

    final activePrice = activePriceAsync.valueOrNull?.pricePerLitre ?? 50.0;
    final membersList = membersAsync.valueOrNull ?? [];
    final selectedMember = membersList.firstWhere(
      (m) => m.id == _selectedMemberId,
      orElse: () => const MemberModel(id: '', firstName: '', lastName: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Milk Intake', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Sacco Buying Rate',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'KES ${activePrice.toStringAsFixed(2)} / Litre',
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
                      onTap: membersList.isNotEmpty
                          ? () => _showSearchableFarmerPicker(membersList)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedMemberId != null && _selectedMemberId!.isNotEmpty
                                ? AppColors.primary
                                : AppColors.cardBorder,
                            width: _selectedMemberId != null && _selectedMemberId!.isNotEmpty ? 1.5 : 1,
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
                                selectedMember.id.isNotEmpty
                                    ? Icons.person_rounded
                                    : Icons.person_search_rounded,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: selectedMember.id.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      'Search and select farmer member...',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                            const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary, size: 22),
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
                    onSelectionChanged: (set) => setState(() => _selectedShift = set.first),
                  ),
                  const SizedBox(height: 20),

                  // Litres Input Field
                  AppTextField(
                    label: 'Milk Quantity (Litres) *',
                    controller: _litresController,
                    hint: 'e.g. 15.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.water_drop_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Litres is required';
                      final d = double.tryParse(val.trim());
                      if (d == null || d <= 0) return 'Enter a valid milk quantity in litres';
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
          if (isLoading) const LoadingOverlay(message: 'Recording milk intake...'),
        ],
      ),
    );
  }
}

class _SearchableFarmerPickerBottomSheet extends StatefulWidget {
  final List<MemberModel> members;
  final String? selectedMemberId;
  final ValueChanged<MemberModel> onSelected;

  const _SearchableFarmerPickerBottomSheet({
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
  });

  @override
  State<_SearchableFarmerPickerBottomSheet> createState() =>
      __SearchableFarmerPickerBottomSheetState();
}

class __SearchableFarmerPickerBottomSheetState
    extends State<_SearchableFarmerPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.members.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          m.membershipNumber.toLowerCase().contains(q) ||
          m.phone.toLowerCase().contains(q) ||
          (m.nationalId?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Farmer Member',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val.trim()),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by Name, Phone, or ID (e.g. M-0001)...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Farmers List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No farmer matching "$_query"',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                    itemBuilder: (ctx, index) {
                      final member = filtered[index];
                      final isSelected = member.id == widget.selectedMemberId;

                      return ListTile(
                        onTap: () => widget.onSelected(member),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.accentMint,
                          foregroundColor: isSelected ? Colors.white : AppColors.primary,
                          child: Text(
                            member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'F',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          member.fullName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${member.membershipNumber} • ${member.phone}${member.location != null && member.location!.isNotEmpty ? " • ${member.location}" : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
