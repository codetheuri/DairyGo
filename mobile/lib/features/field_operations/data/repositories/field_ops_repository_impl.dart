import '../../../../core/models/audit_log_model.dart';
import '../datasources/field_ops_remote_data_source.dart';
import '../models/field_ops_models.dart';
import '../../domain/repositories/field_ops_repository.dart';

class FieldOpsRepositoryImpl implements FieldOpsRepository {
  final FieldOpsRemoteDataSource _remoteDataSource;

  FieldOpsRepositoryImpl(this._remoteDataSource);

  @override
  Future<MilkSaleModel> recordSale(RecordSaleRequestModel request) {
    return _remoteDataSource.recordSale(request);
  }

  @override
  Future<void> voidSale(String id, String reason) =>
      _remoteDataSource.voidSale(id, reason);

  @override
  Future<List<AuditLogModel>> getSaleHistory(String id) =>
      _remoteDataSource.getSaleHistory(id);

  @override
  Future<List<MilkSaleModel>> listSales({
    String? fromDate,
    String? toDate,
    String? search,
    int? collectorId,
  }) {
    return _remoteDataSource.listSales(
      fromDate: fromDate,
      toDate: toDate,
      search: search,
      collectorId: collectorId,
    );
  }

  @override
  Future<MilkSpoilageModel> recordSpoilage(RecordSpoilageRequestModel request) {
    return _remoteDataSource.recordSpoilage(request);
  }

  @override
  Future<List<MilkSpoilageModel>> listSpoilage({
    String? fromDate,
    String? toDate,
    int? collectorId,
  }) {
    return _remoteDataSource.listSpoilage(
      fromDate: fromDate,
      toDate: toDate,
      collectorId: collectorId,
    );
  }

  @override
  Future<ReconciliationModel> getReconciliation({String? date}) {
    return _remoteDataSource.getReconciliation(date: date);
  }
}
