import '../../../collection/data/models/milk_collection_model.dart';
import '../../data/models/settings_models.dart';

abstract class SettingsRepository {
  Future<SaccoProfileModel> getSaccoProfile();
  Future<List<MilkPriceModel>> getPriceHistory();
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request);
}
