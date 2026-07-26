import '../../../collection/data/models/milk_collection_model.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  SettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<SaccoProfileModel> getSaccoProfile() {
    return _remoteDataSource.getSaccoProfile();
  }

  @override
  Future<List<MilkPriceModel>> getPriceHistory() {
    return _remoteDataSource.getPriceHistory();
  }

  @override
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request) {
    return _remoteDataSource.setMilkPrice(request);
  }
}
