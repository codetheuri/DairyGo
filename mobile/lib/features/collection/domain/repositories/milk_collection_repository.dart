import '../../data/models/milk_collection_model.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../../../core/pagination/page_result.dart';

abstract class MilkCollectionRepository {
  Future<MilkPriceModel> getActivePrice();
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
  });
  Future<MilkCollectionModel> recordCollection(RecordCollectionRequestModel request);
  Future<MilkCollectionModel> updateCollection(String id, UpdateCollectionRequestModel request);
  Future<List<AuditLogModel>> getCollectionHistory(String id);
}
