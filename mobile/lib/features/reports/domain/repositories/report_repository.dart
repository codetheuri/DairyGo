import '../../data/models/report_models.dart';

abstract class ReportRepository {
  Future<List<FarmerPayoutStatementModel>> getFarmerPayoutReport({
    String? fromDate,
    String? toDate,
    String? memberId,
  });
  Future<SaccoReconciliationLedgerModel> getReconciliationLedger({
    String? fromDate,
    String? toDate,
  });
  Future<List<CollectorAuditSummaryModel>> getCollectorAuditReport({
    String? fromDate,
    String? toDate,
    int? collectorId,
  });
}
