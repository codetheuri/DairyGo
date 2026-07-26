import '../../data/models/milk_collection_model.dart';

abstract class MilkCollectionRepository {
  Future<MilkPriceModel> getActivePrice();
  Future<List<MilkCollectionModel>> listCollections({
    String? memberId,
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
}
