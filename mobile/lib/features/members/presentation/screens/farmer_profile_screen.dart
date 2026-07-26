import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/member_controller.dart';

class FarmerProfileScreen extends ConsumerWidget {
  final String memberId;

  const FarmerProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailsProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Member Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: memberAsync.when(
        data: (member) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.accentMint,
                        foregroundColor: AppColors.primary,
                        child: Text(
                          member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'F',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentMint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              member.membershipNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusPill.fromStatusString(member.status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contact & Personal Details Card
                Text(
                  'Contact & Personal Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.phone_outlined, 'Phone Number', member.phone),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildInfoRow(
                        Icons.credit_card_outlined,
                        'National ID',
                        member.nationalId ?? 'Not provided',
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Collection Route / Location',
                        member.location ?? 'Unspecified',
                      ),
                      if (member.gender != null) ...[
                        const Divider(height: 20, color: AppColors.cardBorder),
                        _buildInfoRow(Icons.wc_outlined, 'Gender', member.gender!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Details Card
                Text(
                  'Payout & Mobile Money Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.account_balance_wallet_outlined,
                        'M-Pesa Number',
                        member.mpesaNumber ?? member.phone,
                      ),
                      if (member.mpesaName != null && member.mpesaName!.isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.cardBorder),
                        _buildInfoRow(Icons.badge_outlined, 'M-Pesa Account Name', member.mpesaName!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(
                      'Record Milk Intake for ${member.firstName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      context.push('${AppRoutes.recordCollection}?memberId=${member.id}');
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => ErrorView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.refresh(memberDetailsProvider(memberId)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
