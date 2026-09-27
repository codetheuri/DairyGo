import '../../../../core/models/audit_log_model.dart';
import '../../data/models/field_ops_models.dart';

abstract class FieldOpsRepository {
  Future<MilkSaleModel> recordSale(RecordSaleRequestModel request);
  Future<void> voidSale(String id, String reason);
  Future<List<AuditLogModel>> getSaleHistory(String id);
  Future<List<MilkSaleModel>> listSales({String? fromDate, String? toDate, String? search});
  Future<MilkSpoilageModel> recordSpoilage(RecordSpoilageRequestModel request);
  Future<List<MilkSpoilageModel>> listSpoilage({String? fromDate, String? toDate});
  Future<ReconciliationModel> getReconciliation({String? date});
}
