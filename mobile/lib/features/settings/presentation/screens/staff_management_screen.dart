import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/register_staff_dialog.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(saccoStaffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacco Staff & Duty Roster', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Add Staff Member',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const RegisterStaffDialog(),
              ).then((_) => ref.invalidate(saccoStaffListProvider));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const RegisterStaffDialog(),
          ).then((_) => ref.invalidate(saccoStaffListProvider));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(saccoStaffListProvider);
        },
        child: staffAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No Sacco Staff Registered Yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap "+ Add Staff" to register Milk Collectors and Board Members.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final staff = users[index];
                final isAdmin = staff.isSuperUser;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isAdmin ? AppColors.accentMint : AppColors.background,
                        foregroundColor: isAdmin ? AppColors.primary : AppColors.textSecondary,
                        child: Text(
                          staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Username: @${staff.username}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            if (staff.email.isNotEmpty) ...[
                              Text(
                                staff.email,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                            if (staff.phone != null && staff.phone!.isNotEmpty) ...[
                              Text(
                                'Phone: ${staff.phone}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusPill(
                            status: staff.displayRole.toUpperCase(),
                            type: isAdmin ? StatusType.success : (staff.isExecutive ? StatusType.warning : StatusType.info),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Active Duty',
                            style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => ErrorView(
            message: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(saccoStaffListProvider),
          ),
        ),
      ),
    );
  }
}
