import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/collector_dashboard_model.dart';
import '../models/executive_dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<CollectorDashboardModel> getCollectorDashboard({String? date});
  Future<ExecutiveDashboardModel> getExecutiveDashboard({int days = 7});
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<CollectorDashboardModel> getCollectorDashboard({String? date}) async {
    try {
      final response = await _dio.get(
        ApiConstants.collectorDashboard,
        queryParameters: date != null ? {'date': date} : null,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return CollectorDashboardModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to load collector dashboard');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching collector shift data');
    }
  }

  @override
  Future<ExecutiveDashboardModel> getExecutiveDashboard({int days = 7}) async {
    try {
      final response = await _dio.get(
        ApiConstants.executiveDashboard,
        queryParameters: {'days': days},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return ExecutiveDashboardModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to load executive dashboard');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching executive summary data');
    }
  }
}
