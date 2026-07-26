import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/member_controller.dart';

class FarmerDirectoryScreen extends ConsumerWidget {
  const FarmerDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(memberSearchQueryProvider);
    final statusFilter = ref.watch(memberStatusFilterProvider);
    final membersAsync = ref.watch(membersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Directory', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Register Farmer', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push(AppRoutes.registerMember),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  onChanged: (val) => ref.read(memberSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Phone, or ID (e.g. M-0001)...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              ref.read(memberSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        ref,
                        label: 'All Farmers',
                        value: null,
                        currentValue: statusFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: 'Active',
                        value: 'ACTIVE',
                        currentValue: statusFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: 'Inactive',
                        value: 'INACTIVE',
                        currentValue: statusFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: 'Suspended',
                        value: 'SUSPENDED',
                        currentValue: statusFilter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Member List View
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No Farmers Found',
                    description: searchQuery.isNotEmpty
                        ? 'No farmer matching "$searchQuery" was found.'
                        : 'No registered farmers in the Sacco directory yet.',
                    icon: Icons.people_outline_rounded,
                    buttonLabel: 'Register New Farmer',
                    onButtonPressed: () => context.push(AppRoutes.registerMember),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(membersListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => context.push('/members/${member.id}'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                // Avatar Circle
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.accentMint,
                                  foregroundColor: AppColors.primary,
                                  child: Text(
                                    member.firstName.isNotEmpty
                                        ? member.firstName[0].toUpperCase()
                                        : 'F',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Member Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          StatusPill.fromStatusString(member.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.cardBorder),
                                            ),
                                            child: Text(
                                              member.membershipNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            member.phone,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (member.location != null && member.location!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              member.location!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => ErrorView(
                message: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.refresh(membersListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref, {
    required String label,
    required String? value,
    required String? currentValue,
  }) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (_) {
        ref.read(memberStatusFilterProvider.notifier).state = value;
      },
    );
  }
}
