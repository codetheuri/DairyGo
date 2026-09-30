import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

/// How a next of kin can be related to the farmer.
const nextOfKinRelationships = [
  'Spouse',
  'Son',
  'Daughter',
  'Parent',
  'Sibling',
  'Other relative',
  'Friend',
];

/// The three next of kin details every farmer must have: full name, how
/// they are related, and a phone number. Each field takes the full width, so
/// it reads well on the smallest phones and at the largest text size. Put it
/// inside a [Form]; the fields validate themselves.
class NextOfKinFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String? relationship;
  final ValueChanged<String?> onRelationshipChanged;

  /// The farmer's own phone, to catch the same number typed twice.
  final String Function()? farmerPhone;

  const NextOfKinFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.relationship,
    required this.onRelationshipChanged,
    this.farmerPhone,
  });

  static int _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '').length;

  @override
  Widget build(BuildContext context) {
    // A relationship saved earlier that is not in the list is still offered.
    final options = [
      ...nextOfKinRelationships,
      if (relationship != null &&
          !nextOfKinRelationships.contains(relationship))
        relationship!,
    ];
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Next of kin full name *',
          controller: nameController,
          hint: 'e.g. Mary Wanjiku',
          prefixIcon: Icons.family_restroom_rounded,
          validator: (v) => v == null || v.trim().length < 2
              ? 'Next of kin name is required'
              : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: relationship,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Relationship *',
            prefixIcon: const Icon(
              Icons.diversity_1_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: border(AppColors.cardBorder),
            enabledBorder: border(AppColors.cardBorder),
          ),
          items: [
            for (final r in options)
              DropdownMenuItem(
                value: r,
                child: Text(r, overflow: TextOverflow.ellipsis),
              ),
          ],
          validator: (v) =>
              v == null || v.isEmpty ? 'Choose the relationship' : null,
          onChanged: onRelationshipChanged,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Next of kin phone *',
          controller: phoneController,
          hint: 'e.g. 0712345678',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_in_talk_outlined,
          validator: (v) {
            final phone = (v ?? '').trim();
            if (phone.isEmpty) return 'Next of kin phone is required';
            if (_digits(phone) < 10) {
              return 'Enter a valid phone number (at least 10 digits)';
            }
            final own = farmerPhone?.call().trim() ?? '';
            if (own.isNotEmpty && own == phone) {
              return 'Use a different number from the farmer\'s own';
            }
            return null;
          },
        ),
      ],
    );
  }
}
