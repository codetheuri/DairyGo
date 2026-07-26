import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/field_ops_models.dart';

abstract class FieldOpsRemoteDataSource {
  Future<MilkSaleModel> recordSale(RecordSaleRequestModel request);
  Future<List<MilkSaleModel>> listSales({String? fromDate, String? toDate, String? search});
  Future<MilkSpoilageModel> recordSpoilage(RecordSpoilageRequestModel request);
  Future<List<MilkSpoilageModel>> listSpoilage({String? fromDate, String? toDate});
  Future<ReconciliationModel> getReconciliation({String? date});
}

class FieldOpsRemoteDataSourceImpl implements FieldOpsRemoteDataSource {
  final Dio _dio;

  FieldOpsRemoteDataSourceImpl(this._dio);

  @override
  Future<MilkSaleModel> recordSale(RecordSaleRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.sales,
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MilkSaleModel.fromJson(data['data']['sale'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to record direct field sale');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error recording direct field sale');
    }
  }

  @override
  Future<List<MilkSaleModel>> listSales({String? fromDate, String? toDate, String? search}) async {
    try {
      final queryParams = <String, dynamic>{'per_page': 100};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        ApiConstants.sales,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['sales'] as List? ?? [])
            .map((e) => MilkSaleModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load field sales');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading field sales');
    }
  }

  @override
  Future<MilkSpoilageModel> recordSpoilage(RecordSpoilageRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.spoilage,
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MilkSpoilageModel.fromJson(data['data']['spoilage'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to log milk spoilage');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error logging milk spoilage');
    }
  }

  @override
  Future<List<MilkSpoilageModel>> listSpoilage({String? fromDate, String? toDate}) async {
    try {
      final queryParams = <String, dynamic>{'per_page': 100};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final response = await _dio.get(
        ApiConstants.spoilage,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['spoilages'] as List? ?? [])
            .map((e) => MilkSpoilageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load spoilage logs');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading spoilage logs');
    }
  }

  @override
  Future<ReconciliationModel> getReconciliation({String? date}) async {
    try {
      final response = await _dio.get(
        ApiConstants.reconciliation,
        queryParameters: date != null ? {'date': date} : null,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return ReconciliationModel.fromJson(data['data']['reconciliation'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to load reconciliation data');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching reconciliation status');
    }
  }
}
