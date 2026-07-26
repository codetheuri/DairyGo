import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/models/report_models.dart';
import '../controllers/report_controller.dart';

class CollectorDailyAuditItem {
  final String date;
  final double collected;
  final double sold;
  final double spoiled;
  final double netHandover;

  CollectorDailyAuditItem({
    required this.date,
    required this.collected,
    required this.sold,
    required this.spoiled,
    required this.netHandover,
  });
}

class CollectorAuditDetailScreen extends ConsumerWidget {
  final CollectorAuditSummaryModel summary;

  const CollectorAuditDetailScreen({super.key, required this.summary});

  String _formatDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    final day = parsed.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[parsed.month - 1];
    final year = parsed.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromDate = ref.watch(reportFilterFromDateProvider);
    final toDate = ref.watch(reportFilterToDateProvider);

    final collectionsAsync = ref.watch(
      collectorMonthCollectionsProvider((fromDate: fromDate, toDate: toDate)),
    );
    final salesAsync = ref.watch(
      collectorMonthSalesProvider((fromDate: fromDate, toDate: toDate)),
    );
    final spoilageAsync = ref.watch(
      collectorMonthSpoilageProvider((fromDate: fromDate, toDate: toDate)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${summary.collectorName} Audit', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Collector Header Summary Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Text(
                        summary.collectorName.isNotEmpty ? summary.collectorName[0].toUpperCase() : 'C',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.collectorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Period: $fromDate to $toDate',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial & Volume Overview Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Intake', '${summary.totalCollectedLitres.toStringAsFixed(1)}L', AppColors.primary),
                      _buildMetric('Sold', '${summary.totalSoldLitres.toStringAsFixed(1)}L', AppColors.secondary),
                      _buildMetric('Spoiled', '${summary.totalSpoiledLitres.toStringAsFixed(1)}L', AppColors.warning),
                      _buildMetric('Station', '${summary.netDeliveredLitres.toStringAsFixed(1)}L', AppColors.success, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daily Mathematical Reconciliation Log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ),
          ),

          // Daily Reconciliation List across entire month
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                return salesAsync.when(
                  data: (sales) {
                    return spoilageAsync.when(
                      data: (spoilages) {
                        // Filter for this collector if collectorId is available
                        final filteredCollections = summary.collectorId > 0
                            ? collections.where((c) => c.collectorId == summary.collectorId).toList()
                            : collections;
                        final filteredSales = summary.collectorId > 0
                            ? sales.where((s) => s.collectorId == summary.collectorId).toList()
                            : sales;
                        final filteredSpoilage = summary.collectorId > 0
                            ? spoilages.where((sp) => sp.collectorId == summary.collectorId).toList()
                            : spoilages;

                        // Group by date
                        final Map<String, double> collectedMap = {};
                        final Map<String, double> soldMap = {};
                        final Map<String, double> spoiledMap = {};

                        for (var c in filteredCollections) {
                          final dateKey = c.collectionDate.split('T').first;
                          collectedMap[dateKey] = (collectedMap[dateKey] ?? 0.0) + c.quantityLitres;
                        }

                        for (var s in filteredSales) {
                          final dateKey = s.saleDate.split('T').first;
                          soldMap[dateKey] = (soldMap[dateKey] ?? 0.0) + s.quantityLitres;
                        }

                        for (var sp in filteredSpoilage) {
                          final dateKey = sp.spoilageDate.split('T').first;
                          spoiledMap[dateKey] = (spoiledMap[dateKey] ?? 0.0) + sp.quantityLitres;
                        }

                        final allDates = {
                          ...collectedMap.keys,
                          ...soldMap.keys,
                          ...spoiledMap.keys,
                        }.toList()
                          ..sort((a, b) => b.compareTo(a));

                        if (allDates.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'No Operations Logged',
                            description: 'No daily collection, sale, or spoilage entries found for this month.',
                            icon: Icons.calendar_today_outlined,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: allDates.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final date = allDates[index];
                            final collected = collectedMap[date] ?? 0.0;
                            final sold = soldMap[date] ?? 0.0;
                            final spoiled = spoiledMap[date] ?? 0.0;
                            final netHandover = collected - sold - spoiled;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(date),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentMint,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Net Handover: ${netHandover.toStringAsFixed(1)} L',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, color: AppColors.cardBorder),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSubItem('Intake', '${collected.toStringAsFixed(1)}L', AppColors.primary),
                                      _buildSubItem('Sales', '${sold.toStringAsFixed(1)}L', AppColors.secondary),
                                      _buildSubItem('Spoiled', '${spoiled.toStringAsFixed(1)}L', AppColors.warning),
                                      _buildSubItem('To Station', '${netHandover.toStringAsFixed(1)}L', AppColors.success),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (e, s) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.refresh(collectorMonthSpoilageProvider((fromDate: fromDate, toDate: toDate))),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, s) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.refresh(collectorMonthSalesProvider((fromDate: fromDate, toDate: toDate))),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, s) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(collectorMonthCollectionsProvider((fromDate: fromDate, toDate: toDate))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            fontSize: isBold ? 14 : 13,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSubItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
