import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/report_controller.dart';
import 'collector_audit_detail_screen.dart';
import 'farmer_payout_detail_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _stepMonth(int offset) {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    setState(() {
      _selectedMonth = nextMonth;
    });
    ref.read(reportFilterFromDateProvider.notifier).state = getFirstDayOfMonthString(nextMonth);
    ref.read(reportFilterToDateProvider.notifier).state = getLastDayOfMonthString(nextMonth);
  }

  String _formatMonthHeader(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final payoutsAsync = ref.watch(farmerPayoutReportProvider);
    final ledgerAsync = ref.watch(saccoLedgerReportProvider);
    final auditAsync = ref.watch(collectorAuditReportProvider);

    final fromDate = ref.watch(reportFilterFromDateProvider);
    final toDate = ref.watch(reportFilterToDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Audit Views', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.receipt_long_rounded, size: 18),
                  text: 'Farmer Payouts',
                ),
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.account_balance_rounded, size: 18),
                  text: 'Sacco Ledger',
                ),
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.badge_outlined, size: 18),
                  text: 'Collector Audit',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Monthly Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                    tooltip: 'Previous Month',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _stepMonth(-1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        _formatMonthHeader(_selectedMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($fromDate to $toDate)',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    tooltip: 'Next Month',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _stepMonth(1),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Farmer Payout Statements View
                payoutsAsync.when(
                  data: (statements) {
                    if (statements.isEmpty) {
                      return EmptyStateWidget(
                        title: 'No Payout Statements',
                        description: 'No farmer payout records for ${_formatMonthHeader(_selectedMonth)}.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(farmerPayoutReportProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: statements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = statements[index];

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmerPayoutDetailScreen(statement: item),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.accentMint,
                                      foregroundColor: AppColors.primary,
                                      child: Text(
                                        item.farmerName.isNotEmpty ? item.farmerName[0].toUpperCase() : 'F',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.farmerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.membershipNumber} • ${item.totalLitres.toStringAsFixed(1)} L (${item.collectionsCount} Intakes)',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Tap for itemized daily breakdown >',
                                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'KES ${item.grossAmountOwed.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@ KES ${item.averagePricePerLitre.toStringAsFixed(0)}/L',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(farmerPayoutReportProvider),
                  ),
                ),

                // 2. Sacco Ledger View
                ledgerAsync.when(
                  data: (ledger) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: ledger.isBalanced ? AppColors.accentMint : AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ledger.isBalanced ? AppColors.primary : AppColors.error,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mathematical Balancing Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: ledger.isBalanced ? AppColors.primary : AppColors.error,
                                      ),
                                    ),
                                    StatusPill.fromStatusString(
                                      ledger.isBalanced ? 'VERIFIED' : 'REJECTED',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ledger.isBalanced
                                      ? 'All intakes, sales, and spoilage losses mathematically balance!'
                                      : 'Discrepancy detected: ${ledger.discrepancyLitres.toStringAsFixed(1)} Litres variance!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ledger.isBalanced ? AppColors.primary : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Volume & Financial Balancing Ledger',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              children: [
                                _buildLedgerRow('Total Farmer Intake', '${ledger.totalFarmerIntakeLitres.toStringAsFixed(1)} L', AppColors.primary),
                                const Divider(height: 20, color: AppColors.cardBorder),
                                _buildLedgerRow('Farmer Payout Liability', 'KES ${ledger.totalFarmerLiabilityKes.toStringAsFixed(2)}', AppColors.warning),
                                const Divider(height: 20, color: AppColors.cardBorder),
                                _buildLedgerRow('Field Sales Volume', '${ledger.totalFieldSalesLitres.toStringAsFixed(1)} L', AppColors.secondary),
                                const Divider(height: 20, color: AppColors.cardBorder),
                                _buildLedgerRow('Field Sales Revenue', 'KES ${ledger.totalFieldSalesRevenueKes.toStringAsFixed(2)}', AppColors.success),
                                const Divider(height: 20, color: AppColors.cardBorder),
                                _buildLedgerRow('Spoilage Loss', '${ledger.totalSpoilageLitres.toStringAsFixed(1)} L', AppColors.error),
                                const Divider(height: 20, color: AppColors.cardBorder),
                                _buildLedgerRow('Net Coolant Station Handover', '${ledger.netCoolantStationLitres.toStringAsFixed(1)} L', AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(saccoLedgerReportProvider),
                  ),
                ),

                // 3. Collector Audit Summaries View
                auditAsync.when(
                  data: (collectors) {
                    if (collectors.isEmpty) {
                      return EmptyStateWidget(
                        title: 'No Collector Audits',
                        description: 'No field collector audits recorded for ${_formatMonthHeader(_selectedMonth)}.',
                        icon: Icons.badge_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(collectorAuditReportProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: collectors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = collectors[index];

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CollectorAuditDetailScreen(summary: item),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
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
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              child: Text(
                                                item.collectorName.isNotEmpty ? item.collectorName[0].toUpperCase() : 'C',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              item.collectorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text(
                                          'Tap for daily audit log >',
                                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16, color: AppColors.cardBorder),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildAuditItem('Collected', '${item.totalCollectedLitres.toStringAsFixed(1)}L', AppColors.primary),
                                        _buildAuditItem('Sold', '${item.totalSoldLitres.toStringAsFixed(1)}L', AppColors.secondary),
                                        _buildAuditItem('Spoiled', '${item.totalSpoiledLitres.toStringAsFixed(1)}L', AppColors.warning),
                                        _buildAuditItem('Net Handover', '${item.netDeliveredLitres.toStringAsFixed(1)}L', AppColors.success),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(collectorAuditReportProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildAuditItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
