import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/member_controller.dart';
import '../widgets/farmer_details_fields.dart';

class RegisterFarmerScreen extends ConsumerStatefulWidget {
  const RegisterFarmerScreen({super.key});

  @override
  ConsumerState<RegisterFarmerScreen> createState() =>
      _RegisterFarmerScreenState();
}

class _RegisterFarmerScreenState extends ConsumerState<RegisterFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _data = FarmerFormData();

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(registerMemberControllerProvider.notifier)
        .registerMember(_data.toCreateRequest());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Farmer ${_data.firstName.text.trim()} registered successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      // Opened from a link there may be nothing to go back to.
      context.canPop() ? context.pop() : context.go(AppRoutes.members);
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
        title: const Text(
          'Register New Farmer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      FormErrorBanner(message: errorMessage),
                      const SizedBox(height: 16),
                    ],
                    FarmerDetailsFields(data: _data),
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
            if (isLoading)
              const LoadingOverlay(message: 'Registering farmer member...'),
          ],
        ),
      ),
    );
  }
}

/// The server's reason a save failed, shown above the form.
class FormErrorBanner extends StatelessWidget {
  final String message;

  const FormErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.error, fontSize: 13),
    ),
  );
}
