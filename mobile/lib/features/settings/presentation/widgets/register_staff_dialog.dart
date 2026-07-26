import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/data/models/register_request.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class RegisterStaffDialog extends ConsumerStatefulWidget {
  const RegisterStaffDialog({super.key});

  @override
  ConsumerState<RegisterStaffDialog> createState() => _RegisterStaffDialogState();
}

class _RegisterStaffDialogState extends ConsumerState<RegisterStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Milk Collector';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      int roleId = 2; // Default to Milk Collector (Role ID 2)
      if (_selectedRole == 'Sacco Administrator') {
        roleId = 1;
      } else if (_selectedRole == 'Board Member / Executive') {
        roleId = 3;
      }

      final request = RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        roleId: roleId,
      );

      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff member "${user.fullName}" registered successfully as $_selectedRole!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
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
                    'Add Sacco Staff Member',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],

              // Role Selector Dropdown
              const Text('Staff Role *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: InputDecoration(
                  fillColor: AppColors.background,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Milk Collector',
                    child: Text('🥛 Milk Collector (Field Intake)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Board Member / Executive',
                    child: Text('📊 Board Member / Executive', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Sacco Administrator',
                    child: Text('👑 Sacco Administrator', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'First Name *',
                      controller: _firstNameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Last Name *',
                      controller: _lastNameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Username *',
                hint: 'e.g. collector_john',
                controller: _usernameController,
                prefixIcon: Icons.badge_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a username' : null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Email Address *',
                hint: 'john@sacco.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter email address';
                  if (!val.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Phone Number (Optional)',
                hint: '0712345678',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Password (PIN) *',
                hint: 'e.g. 1234 or pass',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (val) {
                  if (val == null || val.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Confirm Password *',
                hint: '••••',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (val) {
                  if (val != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              PrimaryButton(
                label: _isLoading ? 'Creating Staff Account...' : 'Register Staff Member',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
