import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/models/collector_dashboard_model.dart';
import '../../data/models/executive_dashboard_model.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardRemoteDataSourceImpl(dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
  return DashboardRepositoryImpl(dataSource);
});

final collectorDashboardProvider = FutureProvider.family<CollectorDashboardModel, String?>((ref, date) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getCollectorDashboard(date: date);
});

final executiveDashboardProvider = FutureProvider.family<ExecutiveDashboardModel, int>((ref, days) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getExecutiveDashboard(days: days);
});
