import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/collector_dashboard_view.dart';
import '../widgets/executive_dashboard_view.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull?.user;
    final isExecutive = user?.isExecutive ?? false;

    final collectorAsync = ref.watch(collectorDashboardProvider(null));
    final executiveAsync = ref.watch(executiveDashboardProvider(7));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.fullName ?? 'Dairy Sacco',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              user?.displayRole ?? 'Field Milk Collector',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sacco Settings & Pricing',
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
        bottom: isExecutive
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(
                        iconMargin: EdgeInsets.only(bottom: 2),
                        icon: Icon(Icons.badge_outlined, size: 18),
                        text: 'Collector Shift',
                      ),
                      Tab(
                        iconMargin: EdgeInsets.only(bottom: 2),
                        icon: Icon(Icons.insights_rounded, size: 18),
                        text: 'Executive Overview',
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: isExecutive
          ? TabBarView(
              controller: _tabController,
              children: [
                // Collector Dashboard View
                collectorAsync.when(
                  data: (data) => CollectorDashboardView(
                    data: data,
                    onRefresh: () => ref.refresh(collectorDashboardProvider(null)),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(collectorDashboardProvider(null)),
                  ),
                ),

                // Executive Summary Dashboard View
                executiveAsync.when(
                  data: (data) => ExecutiveDashboardView(
                    data: data,
                    onRefresh: () => ref.refresh(executiveDashboardProvider(7)),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(executiveDashboardProvider(7)),
                  ),
                ),
              ],
            )
          : collectorAsync.when(
              data: (data) => CollectorDashboardView(
                data: data,
                onRefresh: () => ref.refresh(collectorDashboardProvider(null)),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => ErrorView(
                message: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.refresh(collectorDashboardProvider(null)),
              ),
            ),
    );
  }
}
