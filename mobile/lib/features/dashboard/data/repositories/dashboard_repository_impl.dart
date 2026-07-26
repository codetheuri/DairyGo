import '../datasources/dashboard_remote_data_source.dart';
import '../models/collector_dashboard_model.dart';
import '../models/executive_dashboard_model.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<CollectorDashboardModel> getCollectorDashboard({String? date}) {
    return _remoteDataSource.getCollectorDashboard(date: date);
  }

  @override
  Future<ExecutiveDashboardModel> getExecutiveDashboard({int days = 7}) {
    return _remoteDataSource.getExecutiveDashboard(days: days);
  }
}
