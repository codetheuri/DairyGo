import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/models/collector_dashboard_model.dart';

class CollectorDashboardView extends StatelessWidget {
  final CollectorDashboardModel data;
  final VoidCallback onRefresh;

  const CollectorDashboardView({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Handover Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shift Overview (${data.date.isNotEmpty ? data.date : "Today"})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const StatusPill(
                        status: 'SHIFT ACTIVE',
                        type: StatusType.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.todayNetStationDeliveryLitres.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Litres',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formula: (Intake ${data.todayCollectedLitres}L) - (Sales ${data.todaySoldLitres}L + Spoilage ${data.todaySpoiledLitres}L)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Today\'s Field Shift Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            // Stat Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                InkWell(
                  onTap: () => context.push(AppRoutes.collections),
                  borderRadius: BorderRadius.circular(16),
                  child: StatCard(
                    title: 'Total Intake',
                    value: '${data.todayCollectedLitres.toStringAsFixed(1)} L',
                    subtitle: '${data.todayFarmersServiced} farmers serviced (Tap to view)',
                    icon: Icons.water_drop_rounded,
                    iconColor: AppColors.primary,
                    backgroundColor: AppColors.accentMint,
                  ),
                ),
                InkWell(
                  onTap: () => context.push(AppRoutes.fieldOperations),
                  borderRadius: BorderRadius.circular(16),
                  child: StatCard(
                    title: 'Field Sales',
                    value: '${data.todaySoldLitres.toStringAsFixed(1)} L',
                    subtitle: 'KES ${data.todaySalesRevenue.toStringAsFixed(0)} (Tap to view)',
                    icon: Icons.point_of_sale_rounded,
                    iconColor: AppColors.secondary,
                    backgroundColor: AppColors.accentMint,
                  ),
                ),
                InkWell(
                  onTap: () => context.push(AppRoutes.fieldOperations),
                  borderRadius: BorderRadius.circular(16),
                  child: StatCard(
                    title: 'Spoilage Loss',
                    value: '${data.todaySpoiledLitres.toStringAsFixed(1)} L',
                    subtitle: 'Logged in transit (Tap to view)',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  ),
                ),
                StatCard(
                  title: 'Intake Value',
                  value: 'KES ${data.todayPurchasesAmount.toStringAsFixed(0)}',
                  subtitle: 'Farmer payout liability',
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.success,
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Field Actions
            Text(
              'Field Collector Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Record Intake',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.recordCollection),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.storefront_rounded,
                    label: 'Direct Sale',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppRoutes.recordSale),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Log Spoilage',
                    color: AppColors.warning,
                    onTap: () => context.push(AppRoutes.recordSpoilage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'New Farmer',
                    color: AppColors.primaryDark,
                    onTap: () => context.push(AppRoutes.registerMember),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
