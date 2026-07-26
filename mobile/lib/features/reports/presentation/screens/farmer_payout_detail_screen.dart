import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/models/report_models.dart';
import '../controllers/report_controller.dart';

class FarmerPayoutDetailScreen extends ConsumerWidget {
  final FarmerPayoutStatementModel statement;

  const FarmerPayoutDetailScreen({super.key, required this.statement});

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    final parsed = DateTime.tryParse(dateTimeStr);
    if (parsed == null) return dateTimeStr;
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[local.month - 1];
    final year = local.year;

    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour:$minute $period';
  }

  String _formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr.split('T').first;
    final day = parsed.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[parsed.month - 1];
    return '$day $month';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromDate = ref.watch(reportFilterFromDateProvider);
    final toDate = ref.watch(reportFilterToDateProvider);

    final startShort = _formatShortDate(statement.fromDate ?? fromDate);
    final endShort = _formatShortDate(statement.toDate ?? toDate);

    final collectionsAsync = ref.watch(
      farmerIntakeHistoryProvider((
        memberId: statement.memberId,
        fromDate: statement.fromDate ?? fromDate,
        toDate: statement.toDate ?? toDate,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${statement.farmerName} Statement', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accentMint,
                      foregroundColor: AppColors.primary,
                      child: Text(
                        statement.farmerName.isNotEmpty ? statement.farmerName[0].toUpperCase() : 'F',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statement.farmerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Member #: ${statement.membershipNumber} • ${statement.phone}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (statement.mpesaNumber != null && statement.mpesaNumber!.isNotEmpty)
                            Text(
                              'M-Pesa: ${statement.mpesaNumber}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Summary Bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat(
                        'Gross Payout',
                        'KES ${statement.grossAmountOwed.toStringAsFixed(2)}',
                        AppColors.primary,
                        isBold: true,
                      ),
                      _buildSummaryStat(
                        'Total Litres',
                        '${statement.totalLitres.toStringAsFixed(1)} L',
                        AppColors.textPrimary,
                      ),
                      _buildSummaryStat(
                        'Avg Rate',
                        'KES ${statement.averagePricePerLitre.toStringAsFixed(0)}/L',
                        AppColors.success,
                      ),
                      _buildSummaryStat(
                        'Intakes',
                        '${statement.collectionsCount}',
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itemized Milk Intakes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                Flexible(
                  child: Text(
                    'Period: $startShort - $endShort',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Itemized Milk Intakes List
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Intake Entries Found',
                    description: 'No individual milk intake records for this farmer in selected period.',
                    icon: Icons.water_drop_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = collections[index];
                    final formattedTime = _formatDateTime(item.createdAt);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Shift: ${item.shift} • Rate: KES ${item.pricePerLitre.toStringAsFixed(0)}/L',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.quantityLitres.toStringAsFixed(1)} Litres',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'KES ${item.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
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
                onRetry: () => ref.refresh(
                  farmerIntakeHistoryProvider((
                    memberId: statement.memberId,
                    fromDate: statement.fromDate ?? fromDate,
                    toDate: statement.toDate ?? toDate,
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color, {bool isBold = false}) {
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
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
