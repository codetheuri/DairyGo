import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../field_operations/data/models/field_ops_models.dart';
import '../../../field_operations/presentation/controllers/field_ops_controller.dart';
import '../../../members/presentation/controllers/member_controller.dart';
import '../../data/datasources/report_remote_data_source.dart';
import '../../data/models/report_models.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';

String getFirstDayOfMonthString([DateTime? date]) {
  final now = date ?? DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
}

String getLastDayOfMonthString([DateTime? date]) {
  final now = date ?? DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0);
  return "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
}

/// Global helper to invalidate all cached metric and report providers after any mutation
void invalidateAllAppMetrics(Ref ref) {
  ref.invalidate(milkCollectionsListProvider);
  ref.invalidate(collectorDashboardProvider(null));
  ref.invalidate(executiveDashboardProvider(7));
  ref.invalidate(salesListProvider);
  ref.invalidate(spoilageListProvider);
  ref.invalidate(reconciliationProvider(null));
  ref.invalidate(membersListProvider);
  ref.invalidate(farmerPayoutReportProvider);
  ref.invalidate(saccoLedgerReportProvider);
  ref.invalidate(collectorAuditReportProvider);
}

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReportRemoteDataSourceImpl(dio);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dataSource = ref.watch(reportRemoteDataSourceProvider);
  return ReportRepositoryImpl(dataSource);
});

final reportFilterFromDateProvider =
    StateProvider.autoDispose<String>((ref) => getFirstDayOfMonthString());
final reportFilterToDateProvider =
    StateProvider.autoDispose<String>((ref) => getLastDayOfMonthString());

// Persistent cached providers (no autoDispose) for instant screen transitions
final farmerPayoutReportProvider =
    FutureProvider<List<FarmerPayoutStatementModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final fromDate = ref.watch(reportFilterFromDateProvider);
  final toDate = ref.watch(reportFilterToDateProvider);

  return repository.getFarmerPayoutReport(
    fromDate: fromDate,
    toDate: toDate,
  );
});

final saccoLedgerReportProvider =
    FutureProvider<SaccoReconciliationLedgerModel>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final fromDate = ref.watch(reportFilterFromDateProvider);
  final toDate = ref.watch(reportFilterToDateProvider);

  return repository.getReconciliationLedger(
    fromDate: fromDate,
    toDate: toDate,
  );
});

final collectorAuditReportProvider =
    FutureProvider<List<CollectorAuditSummaryModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final fromDate = ref.watch(reportFilterFromDateProvider);
  final toDate = ref.watch(reportFilterToDateProvider);

  return repository.getCollectorAuditReport(
    fromDate: fromDate,
    toDate: toDate,
  );
});

final farmerIntakeHistoryProvider = FutureProvider
    .family<List<MilkCollectionModel>, ({String memberId, String fromDate, String toDate})>(
        (ref, arg) async {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  return repository.listCollections(
    memberId: arg.memberId,
    fromDate: arg.fromDate,
    toDate: arg.toDate,
    perPage: 200,
  );
});

final collectorMonthCollectionsProvider = FutureProvider
    .family<List<MilkCollectionModel>, ({String fromDate, String toDate})>((ref, arg) async {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  return repository.listCollections(
    fromDate: arg.fromDate,
    toDate: arg.toDate,
    perPage: 200,
  );
});

final collectorMonthSalesProvider = FutureProvider
    .family<List<MilkSaleModel>, ({String fromDate, String toDate})>((ref, arg) async {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  return repository.listSales(
    fromDate: arg.fromDate,
    toDate: arg.toDate,
  );
});

final collectorMonthSpoilageProvider = FutureProvider
    .family<List<MilkSpoilageModel>, ({String fromDate, String toDate})>((ref, arg) async {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  return repository.listSpoilage(
    fromDate: arg.fromDate,
    toDate: arg.toDate,
  );
});
