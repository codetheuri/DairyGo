import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/report_models.dart';

abstract class ReportRemoteDataSource {
  Future<List<FarmerPayoutStatementModel>> getFarmerPayoutReport({
    String? fromDate,
    String? toDate,
    String? memberId,
  });
  Future<SaccoReconciliationLedgerModel> getReconciliationLedger({
    String? fromDate,
    String? toDate,
  });
  Future<List<CollectorAuditSummaryModel>> getCollectorAuditReport({
    String? fromDate,
    String? toDate,
    int? collectorId,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final Dio _dio;

  ReportRemoteDataSourceImpl(this._dio);

  @override
  Future<List<FarmerPayoutStatementModel>> getFarmerPayoutReport({
    String? fromDate,
    String? toDate,
    String? memberId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'per_page': 100};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
      if (memberId != null && memberId.isNotEmpty) queryParams['member_id'] = memberId;

      final response = await _dio.get(
        ApiConstants.farmerPayoutReport,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['statements'] as List? ?? [])
            .map((e) => FarmerPayoutStatementModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load farmer payout statements');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching farmer payout report');
    }
  }

  @override
  Future<SaccoReconciliationLedgerModel> getReconciliationLedger({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final response = await _dio.get(
        ApiConstants.saccoReconciliationReport,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return SaccoReconciliationLedgerModel.fromJson(
          data['data']['ledger'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to load Sacco balancing ledger');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching Sacco balancing ledger');
    }
  }

  @override
  Future<List<CollectorAuditSummaryModel>> getCollectorAuditReport({
    String? fromDate,
    String? toDate,
    int? collectorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'per_page': 100};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
      if (collectorId != null && collectorId > 0) queryParams['collector_id'] = collectorId;

      final response = await _dio.get(
        ApiConstants.collectorAuditReport,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['audit_summaries'] as List? ?? [])
            .map((e) => CollectorAuditSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load collector audit summaries');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching collector audit report');
    }
  }
}
