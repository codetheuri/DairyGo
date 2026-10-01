import '../../../collection/data/models/milk_collection_model.dart';
import '../../data/models/settings_models.dart';

abstract class SettingsRepository {
  Future<SaccoProfileModel> getSaccoProfile();
  Future<List<MilkPriceModel>> getPriceHistory();
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request);
  Future<SaccoSettingsModel> getSettings();
  Future<SaccoSettingsModel> updateTolerance(double litres);

  /// Days without milk after which active farmers become inactive; 0 = never.
  Future<SaccoSettingsModel> updateInactiveAfterDays(int days);

  /// 0 removes the limit.
  Future<SaccoSettingsModel> updateAdvanceRules({
    required double limit,
    required int lastDay,
    required int milkPercent,
  });
}
