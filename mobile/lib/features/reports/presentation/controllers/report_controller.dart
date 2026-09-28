import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/page_result.dart';

import '../../../../core/network/dio_client.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../field_operations/data/models/field_ops_models.dart';
import '../../../field_operations/presentation/controllers/field_ops_controller.dart';
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

/// Reloads the lists, dashboards and reports that change when milk is
/// recorded, sold, spoiled or priced. Only screens that are open refetch at
/// once; the others reload when next opened. The farmer directory is not
/// included: recording milk does not change it.
void invalidateAllAppMetrics(Ref ref) {
  ref.invalidate(milkCollectionsListProvider);
  ref.invalidate(collectorDashboardProvider(null));
  ref.invalidate(executiveDashboardProvider(7));
  ref.invalidate(salesListProvider);
  ref.invalidate(spoilageListProvider);
  ref.invalidate(reconciliationProvider(null));
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

final reportFilterFromDateProvider = StateProvider.autoDispose<String>(
  (ref) => getFirstDayOfMonthString(),
);
final reportFilterToDateProvider = StateProvider.autoDispose<String>(
  (ref) => getLastDayOfMonthString(),
);

// Persistent cached providers (no autoDispose) for instant screen transitions
final farmerPayoutReportProvider =
    FutureProvider<List<FarmerPayoutStatementModel>>((ref) async {
      ref.reloadWhenNewerDataArrives();
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
      ref.reloadWhenNewerDataArrives();
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
      ref.reloadWhenNewerDataArrives();
      final repository = ref.watch(reportRepositoryProvider);
      final fromDate = ref.watch(reportFilterFromDateProvider);
      final toDate = ref.watch(reportFilterToDateProvider);

      return repository.getCollectorAuditReport(
        fromDate: fromDate,
        toDate: toDate,
      );
    });

/// A report period for one farmer or one collector (YYYY-MM-DD, inclusive).
typedef FarmerPeriod = ({String memberId, String fromDate, String toDate});
typedef CollectorPeriod = ({int collectorId, String fromDate, String toDate});

/// One farmer's collections for a statement period. The server filters by
/// farmer, and every page is loaded so the list matches the statement totals.
final farmerIntakeHistoryProvider =
    FutureProvider.family<List<MilkCollectionModel>, FarmerPeriod>((
      ref,
      arg,
    ) async {
      final repository = ref.watch(milkCollectionRepositoryProvider);
      return fetchAllPages(
        (page) => repository.listCollections(
          memberId: arg.memberId,
          fromDate: arg.fromDate,
          toDate: arg.toDate,
          page: page,
          perPage: maxPageSize,
        ),
      );
    });

/// One collector's collections, sales and spoilage for the audit detail.
/// Filtered on the server rather than downloading every collector's rows.
final collectorMonthCollectionsProvider =
    FutureProvider.family<List<MilkCollectionModel>, CollectorPeriod>((
      ref,
      arg,
    ) async {
      final repository = ref.watch(milkCollectionRepositoryProvider);
      return fetchAllPages(
        (page) => repository.listCollections(
          collectorId: arg.collectorId,
          fromDate: arg.fromDate,
          toDate: arg.toDate,
          page: page,
          perPage: maxPageSize,
        ),
      );
    });

final collectorMonthSalesProvider =
    FutureProvider.family<List<MilkSaleModel>, CollectorPeriod>((
      ref,
      arg,
    ) async {
      return ref
          .watch(fieldOpsRepositoryProvider)
          .listSales(
            collectorId: arg.collectorId,
            fromDate: arg.fromDate,
            toDate: arg.toDate,
          );
    });

final collectorMonthSpoilageProvider =
    FutureProvider.family<List<MilkSpoilageModel>, CollectorPeriod>((
      ref,
      arg,
    ) async {
      return ref
          .watch(fieldOpsRepositoryProvider)
          .listSpoilage(
            collectorId: arg.collectorId,
            fromDate: arg.fromDate,
            toDate: arg.toDate,
          );
    });
