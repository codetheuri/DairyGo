import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/models/executive_dashboard_model.dart';
import 'trend_chart_widget.dart';

class ExecutiveDashboardView extends StatelessWidget {
  final ExecutiveDashboardModel data;
  final VoidCallback onRefresh;

  const ExecutiveDashboardView({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cards = data.summaryCards;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
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
                  Text(
                    'Sacco Executive Overview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cards.todayCollectedLitres.toStringAsFixed(0)} L',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Today Intake',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cards.activeMembersCount}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Farmers',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cards.activeCollectorsCount}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Collectors',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Month to Date Financial Metrics
            Text(
              'Month-to-Date Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Month Intake',
                  value: '${(cards.monthCollectedLitres / 1000).toStringAsFixed(1)}k L',
                  subtitle: 'Total volume collected',
                  icon: Icons.opacity_rounded,
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.accentMint,
                ),
                StatCard(
                  title: 'Payout Liability',
                  value: 'KES ${(cards.monthPayoutLiabilityKes / 1000).toStringAsFixed(1)}k',
                  subtitle: 'Owed to members',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                ),
                StatCard(
                  title: 'Sales Revenue',
                  value: 'KES ${(cards.monthSalesRevenueKes / 1000).toStringAsFixed(1)}k',
                  subtitle: 'Direct & bulk sales',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                ),
                StatCard(
                  title: 'Today Spoilage',
                  value: '${cards.todaySpoilageLitres.toStringAsFixed(1)} L',
                  subtitle: 'Loss in transit',
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.error,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trend Chart
            TrendChartWidget(points: data.intakeTrend),
          ],
        ),
      ),
    );
  }
}
