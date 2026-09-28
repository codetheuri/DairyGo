import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/models/executive_dashboard_model.dart';
import 'trend_chart_widget.dart';
import '../../../../core/widgets/balance_badge.dart';

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
                  // The balance badge moves under the title when they do not fit on one line.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Sacco Executive Overview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Today's milk balance: collected vs sold (coolers included) + spoiled.
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: BalanceBadge(
                          unaccountedLitres: cards.todayUnaccountedLitres,
                          status: cards.todayBalanceStatus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeaderStat(
                        value:
                            '${cards.todayCollectedLitres.toStringAsFixed(0)} L',
                        label: 'Today Intake',
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      _HeaderStat(
                        value: '${cards.activeMembersCount}',
                        label: 'Farmers',
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      _HeaderStat(
                        value: '${cards.activeCollectorsCount}',
                        label: 'Collectors',
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

            ResponsiveGrid(
              // Two per row on phones (one with large text), more on wider screens.
              minItemWidth: 160,
              minColumns: 1,
              children: [
                StatCard(
                  title: 'Month Intake',
                  value: '${cards.monthCollectedLitres.toStringAsFixed(0)} L',
                  subtitle: 'Total volume collected',
                  icon: Icons.opacity_rounded,
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.accentMint,
                ),
                StatCard(
                  title: 'Payout Liability',
                  value:
                      'KES ${cards.monthPayoutLiabilityKes.toStringAsFixed(0)}',
                  subtitle: 'Owed to members',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                ),
                StatCard(
                  title: 'Sales Revenue',
                  value: 'KES ${cards.monthSalesRevenueKes.toStringAsFixed(0)}',
                  subtitle: 'Direct & bulk sales',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                ),
                StatCard(
                  title: 'Gross Margin',
                  value: 'KES ${cards.monthGrossMarginKes.toStringAsFixed(0)}',
                  subtitle: 'Sales minus farmer payouts',
                  icon: Icons.savings_rounded,
                  iconColor: cards.monthGrossMarginKes >= 0
                      ? AppColors.success
                      : AppColors.error,
                  backgroundColor:
                      (cards.monthGrossMarginKes >= 0
                              ? AppColors.success
                              : AppColors.error)
                          .withValues(alpha: 0.1),
                ),
                StatCard(
                  title: 'Customers Owe',
                  value: 'KES ${cards.receivablesKes.toStringAsFixed(0)}',
                  subtitle: 'Credit sales not yet paid',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
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

/// One figure in the dashboard header. Shares the row equally with the others
/// and shrinks a long number to fit rather than overflowing.
class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
