import '../../data/models/collector_dashboard_model.dart';
import '../../data/models/executive_dashboard_model.dart';

abstract class DashboardRepository {
  Future<CollectorDashboardModel> getCollectorDashboard({String? date});
  Future<ExecutiveDashboardModel> getExecutiveDashboard({int days = 7});
}
