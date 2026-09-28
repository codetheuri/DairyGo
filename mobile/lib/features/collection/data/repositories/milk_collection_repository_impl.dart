import '../datasources/milk_collection_remote_data_source.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../../../core/pagination/page_result.dart';
import '../models/milk_collection_model.dart';
import '../../domain/repositories/milk_collection_repository.dart';

class MilkCollectionRepositoryImpl implements MilkCollectionRepository {
  final MilkCollectionRemoteDataSource _remoteDataSource;

  MilkCollectionRepositoryImpl(this._remoteDataSource);

  @override
  Future<MilkPriceModel> getActivePrice() {
    return _remoteDataSource.getActivePrice();
  }

  @override
  Future<PageResult<MilkCollectionModel>> listCollections({
    String? memberId,
    int? collectorId,
    String? fromDate,
    String? toDate,
    String? shift,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return _remoteDataSource.listCollections(
      memberId: memberId,
      collectorId: collectorId,
      fromDate: fromDate,
      toDate: toDate,
      shift: shift,
      status: status,
      search: search,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<MilkCollectionModel> recordCollection(
    RecordCollectionRequestModel request,
  ) {
    return _remoteDataSource.recordCollection(request);
  }

  @override
  Future<MilkCollectionModel> updateCollection(
    String id,
    UpdateCollectionRequestModel request,
  ) {
    return _remoteDataSource.updateCollection(id, request);
  }

  @override
  Future<List<AuditLogModel>> getCollectionHistory(String id) {
    return _remoteDataSource.getCollectionHistory(id);
  }
}
