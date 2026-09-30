import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/member_model.dart';
import 'next_of_kin_fields.dart';

/// What the farmer form holds while it is being filled in, for registering a
/// farmer or editing one. Call [dispose] when the screen closes.
class FarmerFormData {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final membershipNumber = TextEditingController();
  final nationalId = TextEditingController();
  final location = TextEditingController();
  final mpesaNumber = TextEditingController();
  final mpesaName = TextEditingController();
  final bankName = TextEditingController();
  final bankAccount = TextEditingController();
  final bankBranch = TextEditingController();
  final kinName = TextEditingController();
  final kinPhone = TextEditingController();
  String? gender;
  String? kinRelationship;

  FarmerFormData();

  /// The form filled with [m]'s current details.
  factory FarmerFormData.of(MemberModel m) {
    final d = FarmerFormData();
    d.firstName.text = m.firstName;
    d.lastName.text = m.lastName;
    d.phone.text = m.phone;
    d.membershipNumber.text = m.membershipNumber;
    d.nationalId.text = m.nationalId ?? '';
    d.location.text = m.location ?? '';
    d.mpesaNumber.text = m.mpesaNumber ?? '';
    d.mpesaName.text = m.mpesaName ?? '';
    d.bankName.text = m.bankName ?? '';
    d.bankAccount.text = m.bankAccountNumber ?? '';
    d.bankBranch.text = m.bankBranch ?? '';
    d.kinName.text = m.nextOfKinName ?? '';
    d.kinPhone.text = m.nextOfKinPhone ?? '';
    const genders = ['MALE', 'FEMALE', 'OTHER'];
    d.gender = genders.contains(m.gender?.toUpperCase())
        ? m.gender!.toUpperCase()
        : null;
    d.kinRelationship = (m.nextOfKinRelationship ?? '').isEmpty
        ? null
        : m.nextOfKinRelationship;
    return d;
  }

  static String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  CreateMemberRequestModel toCreateRequest() => CreateMemberRequestModel(
    firstName: firstName.text.trim(),
    lastName: lastName.text.trim(),
    phone: phone.text.trim(),
    membershipNumber: _optional(membershipNumber),
    nationalId: _optional(nationalId),
    location: _optional(location),
    gender: gender,
    mpesaNumber: _optional(mpesaNumber),
    mpesaName: _optional(mpesaName),
    bankName: _optional(bankName),
    bankAccountNumber: _optional(bankAccount),
    bankBranch: _optional(bankBranch),
    nextOfKinName: kinName.text.trim(),
    nextOfKinRelationship: kinRelationship ?? '',
    nextOfKinPhone: kinPhone.text.trim(),
  );

  /// Every editable detail, for PUT /sacco/members/{id}. An empty optional
  /// field is sent empty, which clears it on the server.
  Map<String, dynamic> toUpdate() => {
    'first_name': firstName.text.trim(),
    'last_name': lastName.text.trim(),
    'phone': phone.text.trim(),
    'national_id': nationalId.text.trim(),
    'location': location.text.trim(),
    if (gender != null) 'gender': gender,
    'mpesa_number': mpesaNumber.text.trim(),
    'mpesa_name': mpesaName.text.trim(),
    'bank_name': bankName.text.trim(),
    'bank_account_number': bankAccount.text.trim(),
    'bank_branch': bankBranch.text.trim(),
    'next_of_kin_name': kinName.text.trim(),
    'next_of_kin_relationship': kinRelationship ?? '',
    'next_of_kin_phone': kinPhone.text.trim(),
  };

  void dispose() {
    for (final c in [
      firstName,
      lastName,
      phone,
      membershipNumber,
      nationalId,
      location,
      mpesaNumber,
      mpesaName,
      bankName,
      bankAccount,
      bankBranch,
      kinName,
      kinPhone,
    ]) {
      c.dispose();
    }
  }
}

/// A farmer's details in four sections: identity, next of kin, location and
/// payout. Every field takes the full width, so the form reads well on the
/// smallest phones at the largest text size. Put it inside a [Form].
class FarmerDetailsFields extends StatefulWidget {
  final FarmerFormData data;

  /// Editing an existing farmer: the membership number cannot change.
  final bool editing;

  const FarmerDetailsFields({
    super.key,
    required this.data,
    this.editing = false,
  });

  @override
  State<FarmerDetailsFields> createState() => _FarmerDetailsFieldsState();
}

class _FarmerDetailsFieldsState extends State<FarmerDetailsFields> {
  FarmerFormData get d => widget.data;

  static int _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '').length;

  static String? _name(String? v, String field) =>
      v == null || v.trim().length < 2 ? '$field is required' : null;

  static String? _phone(String? v, {required bool required}) {
    final phone = (v ?? '').trim();
    if (phone.isEmpty) return required ? 'Phone number is required' : null;
    if (_digits(phone) < 10) {
      return 'Enter a valid phone number (at least 10 digits)';
    }
    return null;
  }

  Widget _section(String title, [String? note]) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );

  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.cardBorder),
  );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    const sectionGap = SizedBox(height: 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Farmer Identity'),
        AppTextField(
          label: 'First Name *',
          controller: d.firstName,
          hint: 'e.g. John',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) => _name(v, 'First name'),
        ),
        gap,
        AppTextField(
          label: 'Last Name *',
          controller: d.lastName,
          hint: 'e.g. Kamau',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) => _name(v, 'Last name'),
        ),
        gap,
        AppTextField(
          label: 'Phone Number *',
          controller: d.phone,
          hint: 'e.g. 0712345678',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
          validator: (v) => _phone(v, required: true),
        ),
        gap,
        AppTextField(
          label: 'National ID / Passport',
          controller: d.nationalId,
          hint: 'e.g. 12345678',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card_rounded,
        ),
        gap,
        if (!widget.editing) ...[
          AppTextField(
            label: 'Membership Number',
            controller: d.membershipNumber,
            hint: 'Leave blank to number automatically',
            prefixIcon: Icons.badge_outlined,
          ),
          gap,
        ],
        DropdownButtonFormField<String>(
          initialValue: d.gender,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Gender (optional)',
            prefixIcon: const Icon(
              Icons.wc_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: _border(),
            enabledBorder: _border(),
          ),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => d.gender = v),
        ),
        sectionGap,

        _section(
          'Next of Kin',
          'Who the Sacco contacts if the farmer cannot be reached.',
        ),
        NextOfKinFields(
          nameController: d.kinName,
          phoneController: d.kinPhone,
          relationship: d.kinRelationship,
          onRelationshipChanged: (v) => setState(() => d.kinRelationship = v),
          farmerPhone: () => d.phone.text,
        ),
        sectionGap,

        _section('Location'),
        AppTextField(
          label: 'Collection Route / Village',
          controller: d.location,
          hint: 'e.g. Githunguri Route A',
          prefixIcon: Icons.location_on_outlined,
        ),
        sectionGap,

        _section(
          'Payout Details',
          'Where the farmer is paid. Leave blank what does not apply.',
        ),
        AppTextField(
          label: 'M-Pesa Number',
          controller: d.mpesaNumber,
          hint: 'If different from the phone number',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.account_balance_wallet_outlined,
          validator: (v) => _phone(v, required: false),
        ),
        gap,
        AppTextField(
          label: 'M-Pesa Registered Name',
          controller: d.mpesaName,
          hint: 'As M-Pesa shows it',
          prefixIcon: Icons.badge_outlined,
        ),
        gap,
        AppTextField(
          label: 'Bank',
          controller: d.bankName,
          hint: 'e.g. Equity Bank',
          prefixIcon: Icons.account_balance_outlined,
        ),
        gap,
        AppTextField(
          label: 'Bank Account Number',
          controller: d.bankAccount,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.numbers_rounded,
        ),
        gap,
        AppTextField(
          label: 'Bank Branch',
          controller: d.bankBranch,
          prefixIcon: Icons.store_mall_directory_outlined,
        ),
      ],
    );
  }
}
