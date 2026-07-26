import '../datasources/milk_collection_remote_data_source.dart';
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
  Future<List<MilkCollectionModel>> listCollections({
    String? memberId,
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
  Future<MilkCollectionModel> recordCollection(RecordCollectionRequestModel request) {
    return _remoteDataSource.recordCollection(request);
  }

  @override
  Future<MilkCollectionModel> updateCollection(String id, UpdateCollectionRequestModel request) {
    return _remoteDataSource.updateCollection(id, request);
  }
}
