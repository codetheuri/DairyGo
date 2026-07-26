import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/field_ops_models.dart';
import '../controllers/field_ops_controller.dart';

class RecordSpoilageScreen extends ConsumerStatefulWidget {
  const RecordSpoilageScreen({super.key});

  @override
  ConsumerState<RecordSpoilageScreen> createState() => _RecordSpoilageScreenState();
}

class _RecordSpoilageScreenState extends ConsumerState<RecordSpoilageScreen> {
  final _formKey = GlobalKey<FormState>();

  final _litresController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedReason = 'Acidic Quality Failure';

  final List<String> _reasonsList = const [
    'Acidic Quality Failure',
    'Transit Container Leak',
    'Accidental Spillage',
    'Bacterial Contamination',
    'Temperature Deterioration',
    'Other / Unspecified Loss',
  ];

  @override
  void dispose() {
    _litresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final litres = double.parse(_litresController.text.trim());

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final request = RecordSpoilageRequestModel(
      spoilageDate: todayStr,
      quantityLitres: litres,
      reason: _selectedReason,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await ref
        .read(recordSpoilageControllerProvider.notifier)
        .recordSpoilage(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${litres.toStringAsFixed(1)}L spoilage loss successfully!',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordSpoilageControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transit Spoilage / Loss', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    label: 'Spoiled / Lost Quantity (Litres) *',
                    controller: _litresController,
                    hint: 'e.g. 2.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.warning_amber_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Litres required';
                      final d = double.tryParse(val.trim());
                      if (d == null || d <= 0) return 'Enter a valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Spoilage / Loss Reason *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.report_problem_outlined, color: AppColors.warning),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    items: _reasonsList.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val!),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Notes / Incident Details (Optional)',
                    controller: _notesController,
                    hint: 'e.g. Container lid popped open on bumpy road',
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Log Spoilage Loss',
                    icon: Icons.check_circle_rounded,
                    onPressed: isLoading ? null : _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(message: 'Logging spoilage...'),
        ],
      ),
    );
  }
}
