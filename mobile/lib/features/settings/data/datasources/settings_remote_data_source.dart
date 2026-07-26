import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../models/settings_models.dart';

abstract class SettingsRemoteDataSource {
  Future<SaccoProfileModel> getSaccoProfile();
  Future<List<MilkPriceModel>> getPriceHistory();
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio _dio;

  SettingsRemoteDataSourceImpl(this._dio);

  @override
  Future<SaccoProfileModel> getSaccoProfile() async {
    try {
      final response = await _dio.get('/api/v1/sacco/profile');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return SaccoProfileModel.fromJson(data['data']['sacco'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to load Sacco profile');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading Sacco details');
    }
  }

  @override
  Future<List<MilkPriceModel>> getPriceHistory() async {
    try {
      final response = await _dio.get(ApiConstants.milkPrices, queryParameters: {'per_page': 50});
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['prices'] as List? ?? [])
            .map((e) => MilkPriceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load milk price history');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching milk price history');
    }
  }

  @override
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.milkPrices,
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MilkPriceModel.fromJson(data['data']['price'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to update milk price rate');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error updating milk price rate');
    }
  }
}
