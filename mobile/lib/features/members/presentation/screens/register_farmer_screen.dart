import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/member_model.dart';
import '../controllers/member_controller.dart';

class RegisterFarmerScreen extends ConsumerStatefulWidget {
  const RegisterFarmerScreen({super.key});

  @override
  ConsumerState<RegisterFarmerScreen> createState() => _RegisterFarmerScreenState();
}

class _RegisterFarmerScreenState extends ConsumerState<RegisterFarmerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _membershipNoController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _mpesaNoController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _membershipNoController.dispose();
    _nationalIdController.dispose();
    _locationController.dispose();
    _mpesaNoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateMemberRequestModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      membershipNumber: _membershipNoController.text.trim().isNotEmpty
          ? _membershipNoController.text.trim()
          : null,
      nationalId: _nationalIdController.text.trim().isNotEmpty
          ? _nationalIdController.text.trim()
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      gender: _selectedGender,
      mpesaNumber: _mpesaNoController.text.trim().isNotEmpty
          ? _mpesaNoController.text.trim()
          : null,
    );

    final success = await ref
        .read(registerMemberControllerProvider.notifier)
        .registerMember(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farmer ${_firstNameController.text} registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerMemberControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? state.error.toString().replaceAll('Exception: ', '')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Farmer', style: TextStyle(fontWeight: FontWeight.bold)),
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

                  Text(
                    'Farmer Identity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'First Name *',
                          controller: _firstNameController,
                          hint: 'e.g. John',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Last Name *',
                          controller: _lastNameController,
                          hint: 'e.g. Doe',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Phone Number *',
                    controller: _phoneController,
                    hint: 'e.g. 0712345678 or +254712345678',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (val.trim().length < 10) {
                        return 'Enter a valid phone number (min 10 digits)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Membership Number',
                          controller: _membershipNoController,
                          hint: 'Auto if blank (M-XXXX)',
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'National ID / Passport',
                          controller: _nationalIdController,
                          hint: 'e.g. 12345678',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.credit_card_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Location & Payment Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    label: 'Collection Route / Village Location',
                    controller: _locationController,
                    hint: 'e.g. Nyeri Route A / Station B',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'M-Pesa Payout Number',
                    controller: _mpesaNoController,
                    hint: 'Optional M-Pesa phone number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 14),

                  // Gender Selection Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender (Optional)',
                      prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('Male')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    label: 'Register Farmer Member',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: isLoading ? null : _submitForm,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(message: 'Registering farmer member...'),
        ],
      ),
    );
  }
}
