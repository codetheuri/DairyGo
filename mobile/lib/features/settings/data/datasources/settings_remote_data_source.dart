import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../models/settings_models.dart';

abstract class SettingsRemoteDataSource {
  Future<SaccoProfileModel> getSaccoProfile();
  Future<List<MilkPriceModel>> getPriceHistory();
  Future<MilkPriceModel> setMilkPrice(SetPriceRequestModel request);
  Future<SaccoSettingsModel> getSettings();
  Future<SaccoSettingsModel> updateTolerance(double litres);
  Future<SaccoSettingsModel> updateInactiveAfterDays(int days);
  Future<SaccoSettingsModel> updateAdvanceRules({
    required double limit,
    required int lastDay,
    required int milkPercent,
  });
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
        return SaccoProfileModel.fromJson(
          data['data']['sacco'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to load Sacco profile');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading Sacco details');
    }
  }

  @override
  Future<List<MilkPriceModel>> getPriceHistory() async {
    try {
      final response = await _dio.get(
        ApiConstants.milkPrices,
        queryParameters: {'per_page': 50},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['prices'] as List? ?? [])
            .map((e) => MilkPriceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load milk price history');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Error fetching milk price history',
      );
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
        return MilkPriceModel.fromJson(
          data['data']['price'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to update milk price rate');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Error updating milk price rate',
      );
    }
  }

  @override
  Future<SaccoSettingsModel> getSettings() async {
    try {
      final response = await _dio.get(ApiConstants.saccoSettings);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return SaccoSettingsModel.fromJson(
          data['data']['settings'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to load Sacco settings');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading Sacco settings');
    }
  }

  @override
  Future<SaccoSettingsModel> updateTolerance(double litres) =>
      _updateSettings({'reconciliation_tolerance_litres': litres});

  @override
  Future<SaccoSettingsModel> updateInactiveAfterDays(int days) =>
      _updateSettings({'inactive_after_days': days});

  @override
  Future<SaccoSettingsModel> updateAdvanceRules({
    required double limit,
    required int lastDay,
    required int milkPercent,
  }) => _updateSettings({
    'advance_max_per_period': limit,
    'advance_last_day': lastDay,
    'advance_milk_percent': milkPercent,
  });

  /// Changes the settings in [changes]; the others stay as they are.
  Future<SaccoSettingsModel> _updateSettings(
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.saccoSettings,
        data: changes,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return SaccoSettingsModel.fromJson(
          data['data']['settings'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Could not save the setting');
    } on DioException catch (e) {
      final body = e.response?.data;
      String? serverMsg;
      if (body is Map) {
        final errors = body['errors'];
        serverMsg = errors is Map && errors.isNotEmpty
            ? errors.values.first?.toString()
            : body['message']?.toString();
      }
      throw Exception(serverMsg ?? e.message ?? 'Could not save the setting');
    }
  }
}
