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
  Future<List<MilkSaleModel>> listSales({String? fromDate, String? toDate, String? search}) {
    return _remoteDataSource.listSales(fromDate: fromDate, toDate: toDate, search: search);
  }

  @override
  Future<MilkSpoilageModel> recordSpoilage(RecordSpoilageRequestModel request) {
    return _remoteDataSource.recordSpoilage(request);
  }

  @override
  Future<List<MilkSpoilageModel>> listSpoilage({String? fromDate, String? toDate}) {
    return _remoteDataSource.listSpoilage(fromDate: fromDate, toDate: toDate);
  }

  @override
  Future<ReconciliationModel> getReconciliation({String? date}) {
    return _remoteDataSource.getReconciliation(date: date);
  }
}
