import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/keep_fresh.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../controllers/field_ops_controller.dart';
import '../widgets/sale_detail_sheet.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/skeleton.dart';

class FieldOperationsHistoryScreen extends ConsumerStatefulWidget {
  const FieldOperationsHistoryScreen({super.key});

  @override
  ConsumerState<FieldOperationsHistoryScreen> createState() =>
      _FieldOperationsHistoryScreenState();
}

class _FieldOperationsHistoryScreenState
    extends ConsumerState<FieldOperationsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeDate(WidgetRef ref, DateTime newDate) {
    final formatted =
        "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";
    ref.read(fieldOpsFilterDateProvider.notifier).state = formatted;
  }

  void _stepDay(WidgetRef ref, String currentDateStr, int days) {
    final parts = currentDateStr.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]) ?? 2026;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2]) ?? 1;
      final current = DateTime(year, month, day);
      final stepped = current.add(Duration(days: days));
      _changeDate(ref, stepped);
    }
  }

  String _formatDisplayDate(String dateStr) {
    final today = getTodayDateString();
    if (dateStr == today) {
      return "Today ($dateStr)";
    }
    return dateStr;
  }

  String _formatItemTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return '';
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = ref.watch(fieldOpsFilterDateProvider);
    final isToday = selectedDateStr == getTodayDateString();

    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;
    final isExecutive = user?.isExecutive ?? false;

    final salesAsync = ref.watch(salesListProvider);
    final spoilageAsync = ref.watch(spoilageListProvider);

    return RefreshOnShow(
      providers: [salesListProvider, spoilageListProvider],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Field Operations & Sales',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.groups_2_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Customers',
              onPressed: () => context.go(AppRoutes.customers),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Record Sale',
              onPressed: () => context.push(AppRoutes.recordSale),
            ),
            IconButton(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
              tooltip: 'Log Spoilage',
              onPressed: () => context.push(AppRoutes.recordSpoilage),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.storefront_rounded, size: 18),
                    text: 'Field Sales',
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.report_problem_outlined, size: 18),
                    text: 'Spoilage Logs',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ReadableWidth(
          maxWidth: 900,
          child: Column(
            children: [
              // Date Navigator Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
                        tooltip: 'Previous Day',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _stepDay(ref, selectedDateStr, -1),
                      ),
                      Flexible(
                        child: InkWell(
                          onTap: () async {
                            final parts = selectedDateStr.split('-');
                            final initial = parts.length == 3
                                ? DateTime(
                                    int.parse(parts[0]),
                                    int.parse(parts[1]),
                                    int.parse(parts[2]),
                                  )
                                : DateTime.now();

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              _changeDate(ref, picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _formatDisplayDate(selectedDateStr),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (!isToday)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ref
                                        .read(
                                          fieldOpsFilterDateProvider.notifier,
                                        )
                                        .state =
                                    getTodayDateString();
                              },
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Next Day',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => _stepDay(ref, selectedDateStr, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Field Sales List
                    salesAsync.when(
                      data: (sales) {
                        if (sales.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () => ref.refreshFromServer([
                              salesListProvider.future,
                            ]),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 40),
                              children: [
                                EmptyStateWidget(
                                  title: 'No Direct Field Sales',
                                  description:
                                      'No field sales entries recorded for $selectedDateStr.',
                                  icon: Icons.storefront_outlined,
                                  buttonLabel: 'Record Field Sale',
                                  onButtonPressed: () =>
                                      context.push(AppRoutes.recordSale),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              ref.refreshFromServer([salesListProvider.future]),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: sales.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = sales[index];
                              final itemTime = _formatItemTime(item.createdAt);
                              final collectorName = item.collectorName;

                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    SaleDetailSheet.show(context, item),
                                child: Opacity(
                                  opacity: item.isVoided ? 0.55 : 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.accentMint,
                                          foregroundColor: AppColors.primary,
                                          child: Icon(
                                            item.customerType == 'COOLER'
                                                ? Icons.ac_unit_rounded
                                                : Icons.storefront_rounded,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.buyerName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                  decoration: item.isVoided
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.quantityLitres.toStringAsFixed(1)} L @ KES ${item.unitPrice.toStringAsFixed(0)}/L • ${item.paymentMethod}${itemTime.isNotEmpty ? " • $itemTime" : ""}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              if (isExecutive &&
                                                  collectorName != null &&
                                                  collectorName.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'By: $collectorName',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'KES ${item.totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            item.isVoided
                                                ? const StatusPill(
                                                    status: 'VOIDED',
                                                    type: StatusType.error,
                                                  )
                                                : StatusPill.fromStatusString(
                                                    item.paymentStatus,
                                                  ),
                                            if (item.amountOnCredit > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Owes ${item.amountOnCredit.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.warning,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
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
                        onRetry: () => ref.refresh(salesListProvider.future),
                      ),
                    ),

                    // Spoilage Logs List
                    spoilageAsync.when(
                      data: (spoilages) {
                        if (spoilages.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () => ref.refreshFromServer([
                              spoilageListProvider.future,
                            ]),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 40),
                              children: [
                                EmptyStateWidget(
                                  title: 'No Spoilage Losses Logged',
                                  description:
                                      'No transit loss or spoilage entries recorded for $selectedDateStr.',
                                  icon: Icons.check_circle_outline_rounded,
                                  buttonLabel: 'Log Spoilage',
                                  onButtonPressed: () =>
                                      context.push(AppRoutes.recordSpoilage),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () => ref.refreshFromServer([
                            spoilageListProvider.future,
                          ]),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: spoilages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = spoilages[index];
                              final itemTime = _formatItemTime(item.createdAt);
                              final collectorName = item.collectorName;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.warning
                                          .withValues(alpha: 0.1),
                                      foregroundColor: AppColors.warning,
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.reason,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.notes ?? "Transit Loss"}${itemTime.isNotEmpty ? " • $itemTime" : ""}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          if (isExecutive &&
                                              collectorName != null &&
                                              collectorName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'By: $collectorName',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${item.quantityLitres.toStringAsFixed(1)} L',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const ListSkeleton(),
                      error: (err, stack) => ErrorView(
                        message: err.toString().replaceAll('Exception: ', ''),
                        onRetry: () => ref.refresh(spoilageListProvider.future),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
