import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../payouts/presentation/widgets/farmer_account_card.dart';
import '../../../report_downloads/presentation/widgets/download_statement_button.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audit_history_list.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/member_controller.dart';
import '../widgets/farmer_status_sheet.dart';
import '../widgets/next_of_kin_dialog.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/skeleton.dart';

class FarmerProfileScreen extends ConsumerWidget {
  final String memberId;

  const FarmerProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailsProvider(memberId));
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final canEdit = user?.canEditFarmers ?? false;
    final canChangeStatus = user?.canChangeFarmerStatus ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Farmer Member Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit farmer details',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/members/$memberId/edit'),
            ),
        ],
      ),
      body: ReadableWidth(
        child: memberAsync.when(
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
                            member.firstName.isNotEmpty
                                ? member.firstName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.fullName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentMint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
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
                        FarmerStatusNote(status: member.status),
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
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Phone Number',
                          member.phone,
                        ),
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
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),
                          _buildInfoRow(
                            Icons.wc_outlined,
                            'Gender',
                            member.gender!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Next of kin
                  Text(
                    'Next of Kin',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: member.hasNextOfKin
                            ? AppColors.cardBorder
                            : AppColors.warning,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (member.hasNextOfKin) ...[
                          _buildInfoRow(
                            Icons.family_restroom_rounded,
                            'Name',
                            member.nextOfKinName!,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),
                          _buildInfoRow(
                            Icons.diversity_1_rounded,
                            'Relationship',
                            member.nextOfKinRelationship ?? 'Not recorded',
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),
                          _buildInfoRow(
                            Icons.phone_in_talk_outlined,
                            'Phone',
                            member.nextOfKinPhone ?? 'Not recorded',
                          ),
                        ] else
                          Text(
                            canEdit
                                ? 'Not recorded yet. This farmer was registered before next of kin was required.'
                                : 'Not recorded yet. Ask an administrator to add it.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (canEdit) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: Icon(
                              member.hasNextOfKin
                                  ? Icons.edit_outlined
                                  : Icons.add_rounded,
                              size: 18,
                            ),
                            label: Text(
                              member.hasNextOfKin
                                  ? 'Change next of kin'
                                  : 'Add next of kin',
                            ),
                            onPressed: () async {
                              final saved = await NextOfKinDialog.show(
                                context,
                                member,
                              );
                              if (saved == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Next of kin saved'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                          ),
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
                        if (member.mpesaName != null &&
                            member.mpesaName!.isNotEmpty) ...[
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),
                          _buildInfoRow(
                            Icons.badge_outlined,
                            'M-Pesa Account Name',
                            member.mpesaName!,
                          ),
                        ],
                        if ((member.bankAccountNumber ?? '').isNotEmpty) ...[
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),
                          _buildInfoRow(
                            Icons.account_balance_outlined,
                            'Bank',
                            [
                              member.bankName,
                              member.bankAccountNumber,
                              member.bankBranch,
                            ].where((v) => (v ?? '').isNotEmpty).join(' · '),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (user?.seesPayRuns ?? false) ...[
                    FarmerAccountCard(memberId: member.id),
                    const SizedBox(height: 20),
                  ],

                  // Who changed this farmer's details (loaded when opened).
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Change history',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [_FarmerHistory(memberId: member.id)],
                    ),
                  ),
                  const SizedBox(height: 24),

                  DownloadStatementButton.farmer(member),
                  const SizedBox(height: 12),

                  if (canChangeStatus) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.toggle_on_outlined),
                        label: const Text(
                          'Change Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            FarmerStatusSheet.show(context, member),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (canEdit) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          'Edit Farmer Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            context.push('/members/${member.id}/edit'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(
                        member.status.toUpperCase() == 'SUSPENDED'
                            ? 'Suspended: no milk intake'
                            : 'Record Milk Intake for ${member.firstName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: member.status.toUpperCase() == 'SUSPENDED'
                          ? null
                          : () {
                              context.push(
                                '${AppRoutes.recordCollection}?memberId=${member.id}',
                              );
                            },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const ListSkeleton(rows: 4),
          error: (err, stack) => ErrorView(
            message: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.refresh(memberDetailsProvider(memberId).future),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        // Long values wrap instead of running off the screen.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
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
        ),
      ],
    );
  }
}

class _FarmerHistory extends ConsumerWidget {
  final String memberId;

  const _FarmerHistory({required this.memberId});

  static const _fieldLabels = {
    'first_name': 'First name',
    'last_name': 'Last name',
    'phone': 'Phone',
    'national_id': 'National ID',
    'gender': 'Gender',
    'location': 'Location',
    'mpesa_number': 'M-Pesa number',
    'mpesa_name': 'M-Pesa name',
    'bank_name': 'Bank',
    'bank_account_number': 'Bank account',
    'bank_branch': 'Bank branch',
    'next_of_kin_name': 'Next of kin',
    'next_of_kin_relationship': 'Relationship',
    'next_of_kin_phone': 'Next of kin phone',
    'status': 'Status',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(memberHistoryProvider(memberId))
        .when(
          data: (entries) =>
              AuditHistoryList(entries: entries, fieldLabels: _fieldLabels),
          loading: () => const ListSkeleton(rows: 2),
          error: (e, _) => Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        );
  }
}
