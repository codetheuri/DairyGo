import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/executive_dashboard_model.dart';

class TrendChartWidget extends StatelessWidget {
  final List<DailyTrendPoint> points;

  const TrendChartWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          'No trend data available for this period',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    final maxVal = points.map((e) => e.collectedLitres).fold<double>(
          1.0,
          (prev, curr) => curr > prev ? curr : prev,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '7-Day Collection & Sales Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            Row(
              children: [
                _buildLegendIndicator('Intake', AppColors.primary),
                const SizedBox(width: 12),
                _buildLegendIndicator('Sales', AppColors.secondary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              SizedBox(
                height: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points.map((point) {
                    final intakeHeightRatio = (point.collectedLitres / maxVal).clamp(0.05, 1.0);
                    final salesHeightRatio = (point.salesLitres / maxVal).clamp(0.0, 1.0);
                    final dateLabel = point.date.length >= 5 ? point.date.substring(point.date.length - 5) : point.date;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Intake Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 14,
                              height: 120 * intakeHeightRatio,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Sales Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 14,
                              height: 120 * salesHeightRatio,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
