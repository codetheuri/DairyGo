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

  @override
  Future<SaccoSettingsModel> getSettings() => _remoteDataSource.getSettings();

  @override
  Future<SaccoSettingsModel> updateTolerance(double litres) =>
      _remoteDataSource.updateTolerance(litres);

  @override
  Future<SaccoSettingsModel> updateInactiveAfterDays(int days) =>
      _remoteDataSource.updateInactiveAfterDays(days);

  @override
  Future<SaccoSettingsModel> updateAdvanceLimit(double limit) =>
      _remoteDataSource.updateAdvanceLimit(limit);
}
