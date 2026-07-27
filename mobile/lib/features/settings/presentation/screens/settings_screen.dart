import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/register_staff_dialog.dart';
import '../widgets/set_price_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr.split('T').first;
    final day = parsed.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[parsed.month - 1];
    final year = parsed.year;
    return '$day $month $year';
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saccoProfileAsync = ref.watch(saccoProfileProvider);
    final activePriceAsync = ref.watch(activeMilkPriceProvider);
    final priceHistoryAsync = ref.watch(milkPriceHistoryProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;

    final canSetPrice = user?.canSetPrice ?? false;
    final canManageStaff = user?.canManageStaff ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Sacco Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(saccoProfileProvider);
          ref.invalidate(activeMilkPriceProvider);
          ref.invalidate(milkPriceHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sacco Profile Details Card
              Text(
                'Dairy Sacco Organization Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),

              saccoProfileAsync.when(
                data: (sacco) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.accentMint,
                              foregroundColor: AppColors.primary,
                              child: const Icon(Icons.store_rounded, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sacco.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${sacco.code}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill.fromStatusString(sacco.status),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.cardBorder),

                        _buildInfoRow(Icons.calendar_today_rounded, 'Registration Date', _formatDate(sacco.createdAt)),
                        if (sacco.email != null && sacco.email!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.email_outlined, 'Email Address', sacco.email!),
                        ],
                        if (sacco.phone != null && sacco.phone!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.phone_outlined, 'Contact Phone', sacco.phone!),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => _buildLoadingCard('Loading organization profile...'),
                error: (err, stack) => ErrorView(
                  message: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.refresh(saccoProfileProvider),
                ),
              ),
              const SizedBox(height: 22),

              // 2. Active Milk Buying Price & Price History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Milk Buying Price Configuration',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (canSetPrice)
                    activePriceAsync.when(
                      data: (activePrice) => TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Change Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => SetPriceDialog(currentPrice: activePrice.pricePerLitre),
                          );
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Active Buying Rate Card / Setup Banner
              activePriceAsync.when(
                data: (activePrice) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Intake Price Rate:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'KES ${activePrice.pricePerLitre.toStringAsFixed(2)} / Litre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const StatusPill(status: 'ACTIVE RATE', type: StatusType.success),
                      ],
                    ),
                  );
                },
                loading: () => _buildLoadingCard('Loading milk price configuration...'),
                error: (err, stack) {
                  final msg = err.toString().replaceAll('Exception: ', '');
                  final isNoPriceConfigured = msg.toLowerCase().contains('no active milk price');

                  if (isNoPriceConfigured) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'No Active Milk Price Configured',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Set the initial milk buying price per litre for Sacco milk intake operations.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (canSetPrice) ...[
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Set Initial Buying Price'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const SetPriceDialog(currentPrice: null),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ErrorView(
                    message: msg,
                    onRetry: () => ref.refresh(activeMilkPriceProvider),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Price History Log
              Text(
                'Price Rate History Log',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),

              priceHistoryAsync.when(
                data: (prices) {
                  if (prices.isEmpty) {
                    return const Text('No price history entries recorded.', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, index) {
                        final item = prices[index];
                        final isCurrentActive = item.isActive;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isCurrentActive ? AppColors.accentMint : AppColors.background,
                            foregroundColor: isCurrentActive ? AppColors.primary : AppColors.textMuted,
                            child: const Icon(Icons.payments_rounded, size: 16),
                          ),
                          title: Text(
                            'KES ${item.pricePerLitre.toStringAsFixed(2)} / Litre',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCurrentActive ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Effective Date: ${_formatDate(item.effectiveDate)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: isCurrentActive
                              ? const StatusPill(status: 'ACTIVE', type: StatusType.success)
                              : const Text('HISTORICAL', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  );
                },
                loading: () => _buildLoadingCard('Loading price rate history...'),
                error: (err, stack) => const Text('No historical rates recorded.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 24),

              // 3. Sacco Staff & User Management (Hiddne silently for non-Admins)
              if (canManageStaff) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sacco Staff & User Management',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const RegisterStaffDialog(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Registration & Role Assignment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add and provision user accounts for Milk Collectors, Board Members, Executives, and Sacco Admins.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.people_outline_rounded, size: 18),
                              label: const Text('Staff Roster'),
                              onPressed: () => context.push(AppRoutes.staff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: const Text('Add Staff'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const RegisterStaffDialog(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 4. User Session & Logout Card
              Text(
                'User Session & Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              child: Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Authenticated User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  user?.email ?? 'User Account',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                          tooltip: 'Sign Out',
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).logout();
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: const Text('Change My Password / PIN'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ChangePasswordDialog(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
