import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/keep_fresh.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../transfers/presentation/widgets/transfer_tile.dart';
import '../controllers/report_controller.dart';
import 'collector_audit_detail_screen.dart';
import 'farmer_payout_detail_screen.dart';
import '../../../../core/widgets/balance_badge.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../../customers/presentation/widgets/customers_owing_sheet.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/figure_cell.dart';

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
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    setState(() {
      _selectedMonth = nextMonth;
    });
    ref.read(reportFilterFromDateProvider.notifier).state =
        getFirstDayOfMonthString(nextMonth);
    ref.read(reportFilterToDateProvider.notifier).state =
        getLastDayOfMonthString(nextMonth);
  }

  String _formatMonthHeader(DateTime date) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  void _refreshAllReports() {
    ref.invalidate(farmerPayoutReportProvider);
    ref.invalidate(saccoLedgerReportProvider);
    ref.invalidate(collectorAuditReportProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;
    final isExecutive = user?.seesReports ?? false;

    // Security Gate: Restrict Reports View to Sacco Administrators & Executive Board Members
    if (!isExecutive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reports & Audit Views',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Executive Access Restricted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Full Sacco audit reports, collector reconciliations, and farmer payout ledgers are reserved for Sacco Administrators and Executive Board Members.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const StatusPill(
                  status: 'RESTRICTED VIEW',
                  type: StatusType.warning,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payoutsAsync = ref.watch(farmerPayoutReportProvider);
    final ledgerAsync = ref.watch(saccoLedgerReportProvider);
    final auditAsync = ref.watch(collectorAuditReportProvider);

    final fromDate = ref.watch(reportFilterFromDateProvider);
    final toDate = ref.watch(reportFilterToDateProvider);

    return RefreshOnShow(
      providers: [
        farmerPayoutReportProvider,
        saccoLedgerReportProvider,
        collectorAuditReportProvider,
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reports & Audit Views',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'Refresh Reports Data',
              onPressed: _refreshAllReports,
            ),
          ],
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
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Previous Month',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => _stepMonth(-1),
                    ),
                    // The month name always shows; the exact dates only when there is room.
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatMonthHeader(_selectedMonth),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (MediaQuery.sizeOf(context).width >= 420) ...[
                            const SizedBox(width: 6),
                            Text(
                              '($fromDate to $toDate)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                      ),
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
                          description:
                              'No farmer payout records for ${_formatMonthHeader(_selectedMonth)}.',
                          icon: Icons.receipt_long_outlined,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => ref.refreshFromServer([
                          farmerPayoutReportProvider.future,
                        ]),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: statements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
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
                                      builder: (_) => FarmerPayoutDetailScreen(
                                        statement: item,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.accentMint,
                                        foregroundColor: AppColors.primary,
                                        child: Text(
                                          item.farmerName.isNotEmpty
                                              ? item.farmerName[0].toUpperCase()
                                              : 'F',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Tap for itemized daily breakdown >',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
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
                    loading: () => const ListSkeleton(),
                    error: (err, stack) => ErrorView(
                      message: err.toString().replaceAll('Exception: ', ''),
                      onRetry: () =>
                          ref.refresh(farmerPayoutReportProvider.future),
                    ),
                  ),

                  // 2. Sacco Ledger View (Refreshable)
                  ledgerAsync.when(
                    data: (ledger) {
                      return RefreshIndicator(
                        onRefresh: () => ref.refreshFromServer([
                          saccoLedgerReportProvider.future,
                        ]),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Milk balance: every litre collected must be sold (coolers included) or spoiled.
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: BalanceBadge.colorFor(
                                    ledger.balanceStatus,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: BalanceBadge.colorFor(
                                      ledger.balanceStatus,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Wraps at large text sizes
                                    // instead of running off the card.
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        const Text(
                                          'Milk Balance',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        BalanceBadge(
                                          unaccountedLitres:
                                              ledger.unaccountedLitres,
                                          status: ledger.balanceStatus,
                                          large: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Collected ${ledger.totalFarmerIntakeLitres.toStringAsFixed(1)} L − '
                                      'sold ${ledger.totalSoldLitres.toStringAsFixed(1)} L − '
                                      'spoiled ${ledger.totalSpoilageLitres.toStringAsFixed(1)} L = '
                                      '${ledger.unaccountedLitres.toStringAsFixed(1)} L unaccounted '
                                      '(tolerance ${ledger.allowanceLitres.toStringAsFixed(1)} L).'
                                      '${ledger.totalTransferredLitres > 0 ? ' Transfers between collectors cancel out here; each collector below includes them.' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (ledger.collectorsSummary.any(
                                      (c) => c.balanceStatus != 'BALANCED',
                                    )) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Collectors to check:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      for (final c
                                          in ledger.collectorsSummary.where(
                                            (c) =>
                                                c.balanceStatus != 'BALANCED',
                                          ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.collectorName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              BalanceBadge(
                                                unaccountedLitres:
                                                    c.unaccountedLitres,
                                                status: c.balanceStatus,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Milk Volumes',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
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
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildLedgerRow(
                                      'Collected from Farmers',
                                      '${ledger.totalFarmerIntakeLitres.toStringAsFixed(1)} L',
                                      AppColors.primary,
                                    ),
                                    for (final t
                                        in ledger.salesByCustomerType) ...[
                                      const Divider(
                                        height: 20,
                                        color: AppColors.cardBorder,
                                      ),
                                      _buildLedgerRow(
                                        'Sold to ${customerTypeLabel(t.customerType)}',
                                        '${t.litres.toStringAsFixed(1)} L',
                                        AppColors.secondary,
                                      ),
                                    ],
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      'Total Sold',
                                      '${ledger.totalSoldLitres.toStringAsFixed(1)} L',
                                      AppColors.secondary,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      'Spoilage Loss',
                                      '${ledger.totalSpoilageLitres.toStringAsFixed(1)} L',
                                      AppColors.error,
                                    ),
                                    if (ledger.totalTransferredLitres > 0) ...[
                                      const Divider(
                                        height: 20,
                                        color: AppColors.cardBorder,
                                      ),
                                      _buildLedgerRow(
                                        'Moved between collectors',
                                        '${ledger.totalTransferredLitres.toStringAsFixed(1)} L',
                                        AppColors.info,
                                      ),
                                    ],
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      'Unaccounted',
                                      '${ledger.unaccountedLitres.toStringAsFixed(1)} L',
                                      BalanceBadge.colorFor(
                                        ledger.balanceStatus,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Money',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
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
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildLedgerRow(
                                      'Owed to Farmers',
                                      'KES ${ledger.totalFarmerLiabilityKes.toStringAsFixed(2)}',
                                      AppColors.warning,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      'Sales Revenue',
                                      'KES ${ledger.totalSalesRevenueKes.toStringAsFixed(2)}',
                                      AppColors.success,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      '  Paid at Sale',
                                      'KES ${ledger.cashReceivedKes.toStringAsFixed(2)}',
                                      AppColors.textSecondary,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      '  Sold on Credit',
                                      'KES ${ledger.creditSalesKes.toStringAsFixed(2)}',
                                      AppColors.textSecondary,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    _buildLedgerRow(
                                      'Gross Margin',
                                      'KES ${ledger.grossMarginKes.toStringAsFixed(2)}',
                                      ledger.grossMarginKes >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                    const Divider(
                                      height: 20,
                                      color: AppColors.cardBorder,
                                    ),
                                    // Opens the customers who owe, for
                                    // those allowed to see balances.
                                    InkWell(
                                      onTap:
                                          (user?.seesCustomerBalances ?? false)
                                          ? () => CustomersOwingSheet.show(
                                              context,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildLedgerRow(
                                                'Customers Owe (now)',
                                                'KES ${ledger.receivablesKes.toStringAsFixed(2)}',
                                                AppColors.warning,
                                              ),
                                            ),
                                            if (user?.seesCustomerBalances ??
                                                false)
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                color: AppColors.textMuted,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (user?.seesCustomerBalances ?? false)
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Tap to see who owes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const ListSkeleton(),
                    error: (err, stack) => ErrorView(
                      message: err.toString().replaceAll('Exception: ', ''),
                      onRetry: () =>
                          ref.refresh(saccoLedgerReportProvider.future),
                    ),
                  ),

                  // 3. Collector Audit Summaries View (Refreshable)
                  auditAsync.when(
                    data: (collectors) {
                      if (collectors.isEmpty) {
                        return EmptyStateWidget(
                          title: 'No Collector Audits',
                          description:
                              'No field collector audits recorded for ${_formatMonthHeader(_selectedMonth)}.',
                          icon: Icons.badge_outlined,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => ref.refreshFromServer([
                          collectorAuditReportProvider.future,
                        ]),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: collectors.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
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
                                      builder: (_) =>
                                          CollectorAuditDetailScreen(
                                            summary: item,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                child: Text(
                                                  item.collectorName.isNotEmpty
                                                      ? item.collectorName[0]
                                                            .toUpperCase()
                                                      : 'C',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        height: 16,
                                        color: AppColors.cardBorder,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildAuditItem(
                                            'Collected',
                                            '${item.totalCollectedLitres.toStringAsFixed(1)}L',
                                            AppColors.primary,
                                          ),
                                          _buildAuditItem(
                                            'Sold',
                                            '${item.totalSoldLitres.toStringAsFixed(1)}L',
                                            AppColors.secondary,
                                          ),
                                          _buildAuditItem(
                                            'Spoiled',
                                            '${item.totalSpoiledLitres.toStringAsFixed(1)}L',
                                            AppColors.warning,
                                          ),
                                          _buildAuditItem(
                                            'Unaccounted',
                                            '${item.unaccountedLitres.toStringAsFixed(1)}L',
                                            BalanceBadge.colorFor(
                                              item.balanceStatus,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.totalReceivedLitres > 0 ||
                                          item.totalTransferredOutLitres > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: TransferSummaryLine(
                                            received: item.totalReceivedLitres,
                                            given:
                                                item.totalTransferredOutLitres,
                                          ),
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
                    loading: () => const ListSkeleton(),
                    error: (err, stack) => ErrorView(
                      message: err.toString().replaceAll('Exception: ', ''),
                      onRetry: () =>
                          ref.refresh(collectorAuditReportProvider.future),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value, Color color) {
    // The label takes the room the figure leaves and wraps if it must.
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditItem(String label, String value, Color color) {
    return Expanded(
      child: FigureCell(label: label, value: value, color: color),
    );
  }
}
