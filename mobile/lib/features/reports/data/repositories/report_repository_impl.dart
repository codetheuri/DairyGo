import '../datasources/report_remote_data_source.dart';
import '../models/report_models.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<FarmerPayoutStatementModel>> getFarmerPayoutReport({
    String? fromDate,
    String? toDate,
    String? memberId,
  }) {
    return _remoteDataSource.getFarmerPayoutReport(
      fromDate: fromDate,
      toDate: toDate,
      memberId: memberId,
    );
  }

  @override
  Future<SaccoReconciliationLedgerModel> getReconciliationLedger({
    String? fromDate,
    String? toDate,
  }) {
    return _remoteDataSource.getReconciliationLedger(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<List<CollectorAuditSummaryModel>> getCollectorAuditReport({
    String? fromDate,
    String? toDate,
    int? collectorId,
  }) {
    return _remoteDataSource.getCollectorAuditReport(
      fromDate: fromDate,
      toDate: toDate,
      collectorId: collectorId,
    );
  }
}
