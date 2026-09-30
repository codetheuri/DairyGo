import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/models/report_models.dart';
import '../controllers/report_controller.dart';
import '../../../../core/widgets/balance_badge.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/utils/milk_balance.dart';
import '../../../../core/widgets/figure_cell.dart';
import '../../../transfers/data/transfer_models.dart';
import '../../../transfers/presentation/transfer_controller.dart';
import '../../../transfers/presentation/widgets/transfer_detail_sheet.dart';
import '../../../transfers/presentation/widgets/transfer_tile.dart';

class CollectorAuditDetailScreen extends ConsumerWidget {
  final CollectorAuditSummaryModel summary;

  const CollectorAuditDetailScreen({super.key, required this.summary});

  String _formatDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    final day = parsed.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[parsed.month - 1];
    final year = parsed.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromDate = ref.watch(reportFilterFromDateProvider);
    final toDate = ref.watch(reportFilterToDateProvider);

    final period = (
      collectorId: summary.collectorId,
      fromDate: fromDate,
      toDate: toDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${summary.collectorName} Audit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                        summary.collectorName.isNotEmpty
                            ? summary.collectorName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
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
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        'Intake',
                        '${summary.totalCollectedLitres.toStringAsFixed(1)}L',
                        AppColors.primary,
                      ),
                      _buildMetric(
                        'Sold',
                        '${summary.totalSoldLitres.toStringAsFixed(1)}L',
                        AppColors.secondary,
                      ),
                      _buildMetric(
                        'Spoiled',
                        '${summary.totalSpoiledLitres.toStringAsFixed(1)}L',
                        AppColors.warning,
                      ),
                      _buildMetric(
                        'Unaccounted',
                        '${summary.unaccountedLitres.toStringAsFixed(1)}L',
                        BalanceBadge.colorFor(summary.balanceStatus),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                if (summary.totalReceivedLitres > 0 ||
                    summary.totalTransferredOutLitres > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TransferSummaryLine(
                      received: summary.totalReceivedLitres,
                      given: summary.totalTransferredOutLitres,
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
                'Daily milk balance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Daily milk balance across the period
          Expanded(child: _days(ref, period)),
        ],
      ),
    );
  }

  /// Every day of the period with activity, newest first, balanced the same
  /// way as the server: collected + received − sold − given − spoiled.
  Widget _days(WidgetRef ref, CollectorPeriod period) {
    final collectionsAsync = ref.watch(
      collectorMonthCollectionsProvider(period),
    );
    final salesAsync = ref.watch(collectorMonthSalesProvider(period));
    final spoilageAsync = ref.watch(collectorMonthSpoilageProvider(period));
    final transfersAsync = ref.watch(collectorPeriodTransfersProvider(period));
    final all = <AsyncValue<Object?>>[
      collectionsAsync,
      salesAsync,
      spoilageAsync,
      transfersAsync,
    ];

    final failed = all.where((a) => a.hasError && !a.hasValue).firstOrNull;
    if (failed != null) {
      return ErrorView(
        message: failed.error.toString().replaceAll('Exception: ', ''),
        onRetry: () => Future.wait([
          ref.refresh(collectorMonthCollectionsProvider(period).future),
          ref.refresh(collectorMonthSalesProvider(period).future),
          ref.refresh(collectorMonthSpoilageProvider(period).future),
          ref.refresh(collectorPeriodTransfersProvider(period).future),
        ]),
      );
    }
    if (all.any((a) => !a.hasValue)) return const ListSkeleton(rows: 4);

    final id = summary.collectorId;
    final collected = <String, double>{};
    final sold = <String, double>{};
    final spoiled = <String, double>{};
    final transfersByDay = <String, List<MilkTransferModel>>{};
    void add(Map<String, double> m, String date, double litres) =>
        m[date] = (m[date] ?? 0) + litres;

    for (final c in collectionsAsync.value!.where((c) => c.collectorId == id)) {
      add(collected, c.collectionDate.split('T').first, c.quantityLitres);
    }
    for (final s in salesAsync.value!.where((s) => s.collectorId == id)) {
      add(sold, s.saleDate.split('T').first, s.quantityLitres);
    }
    for (final sp in spoilageAsync.value!.where((sp) => sp.collectorId == id)) {
      add(spoiled, sp.spoilageDate.split('T').first, sp.quantityLitres);
    }
    for (final t in transfersAsync.value!.where((t) => !t.isCancelled)) {
      (transfersByDay[t.day] ??= []).add(t);
    }

    final dates = {
      ...collected.keys,
      ...sold.keys,
      ...spoiled.keys,
      ...transfersByDay.keys,
    }.toList()..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Operations Logged',
        description:
            'No collections, sales, transfers or spoilage in this period.',
        icon: Icons.calendar_today_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final date = dates[index];
        final transfers = transfersByDay[date] ?? const [];
        final received = transfers
            .where((t) => t.toCollectorId == id)
            .fold(0.0, (sum, t) => sum + t.quantityLitres);
        final given = transfers
            .where((t) => t.fromCollectorId == id)
            .fold(0.0, (sum, t) => sum + t.quantityLitres);
        final balance = MilkBalance.compute(
          collected: collected[date] ?? 0,
          received: received,
          sold: sold[date] ?? 0,
          transferredOut: given,
          spoiled: spoiled[date] ?? 0,
          allowanceLitres: summary.toleranceLitres,
        );

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
              // The badge moves under the date when they do not fit.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
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
                  BalanceBadge(
                    unaccountedLitres: balance.unaccountedLitres,
                    status: balance.status,
                  ),
                ],
              ),
              const Divider(height: 16, color: AppColors.cardBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubItem(
                    'Intake',
                    '${(collected[date] ?? 0).toStringAsFixed(1)}L',
                    AppColors.primary,
                  ),
                  _buildSubItem(
                    'Sales',
                    '${(sold[date] ?? 0).toStringAsFixed(1)}L',
                    AppColors.secondary,
                  ),
                  _buildSubItem(
                    'Spoiled',
                    '${(spoiled[date] ?? 0).toStringAsFixed(1)}L',
                    AppColors.warning,
                  ),
                ],
              ),
              // Each transfer, with who and when, so the day can be traced.
              for (final t in transfers) ...[
                const SizedBox(height: 8),
                TransferTile(
                  transfer: t,
                  viewerId: id,
                  onTap: () => TransferDetailSheet.show(context, t),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Expanded(
      child: FigureCell(
        label: label,
        value: value,
        color: color,
        emphasis: isBold,
      ),
    );
  }

  Widget _buildSubItem(String label, String value, Color color) {
    return Expanded(
      child: FigureCell(label: label, value: value, color: color),
    );
  }
}
