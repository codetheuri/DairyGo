import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/milk_collection_model.dart';
import '../controllers/collection_controller.dart';

class EditCollectionDialog extends ConsumerStatefulWidget {
  final MilkCollectionModel collection;

  const EditCollectionDialog({super.key, required this.collection});

  @override
  ConsumerState<EditCollectionDialog> createState() => _EditCollectionDialogState();
}

class _EditCollectionDialogState extends ConsumerState<EditCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _litresController;
  late TextEditingController _notesController;
  late String _shift;

  @override
  void initState() {
    super.initState();
    _litresController = TextEditingController(text: widget.collection.quantityLitres.toString());
    _notesController = TextEditingController(text: widget.collection.notes ?? '');
    _shift = widget.collection.shift;
  }

  @override
  void dispose() {
    _litresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final litres = double.tryParse(_litresController.text.trim());
    if (litres == null || litres <= 0) return;

    final request = UpdateCollectionRequestModel(
      quantityLitres: litres,
      shift: _shift,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await ref
        .read(updateMilkCollectionControllerProvider.notifier)
        .updateCollection(widget.collection.id, request);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Milk intake entry updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateMilkCollectionControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return AlertDialog(
      title: const Text('Edit Milk Intake Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null) ...[
                Text(errorMessage, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                const SizedBox(height: 10),
              ],
              AppTextField(
                label: 'Quantity (Litres) *',
                controller: _litresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.water_drop_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Litres is required';
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Text('Shift', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MORNING', label: Text('Morning', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'EVENING', label: Text('Evening', style: TextStyle(fontSize: 12))),
                ],
                selected: {_shift},
                onSelectionChanged: (set) => setState(() => _shift = set.first),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Notes / Reason for Edit',
                controller: _notesController,
                hint: 'e.g. Corrected scale entry',
                prefixIcon: Icons.edit_note_rounded,
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
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
