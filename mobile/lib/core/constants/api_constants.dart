/// ApiConstants holds all API routes and base URL configurations.
/// 
/// Senior Architect Note:
/// For local Android Emulator development, use `http://10.0.2.2:8081`.
/// For physical mobile device testing on local network, update to your local LAN IP (e.g. `http://192.168.x.x:8081`).
abstract class ApiConstants {
  static const String baseUrl = 'http://192.168.18.6:8081';
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth Routes
  static const String login = '/api/v1/auth/login';
  static const String me = '/api/v1/auth/me';

  // Member Routes
  static const String members = '/api/v1/sacco/members';

  // Collection Routes
  static const String activePrice = '/api/v1/sacco/milk-prices/active';
  static const String milkPrices = '/api/v1/sacco/milk-prices';
  static const String collections = '/api/v1/sacco/milk-collections';
  static const String sales = '/api/v1/sacco/milk-sales';
  static const String spoilage = '/api/v1/sacco/milk-spoilage';
  static const String reconciliation = '/api/v1/sacco/reconciliation';

  // Report Routes
  static const String farmerPayoutReport = '/api/v1/sacco/reports/farmer-payout';
  static const String saccoReconciliationReport = '/api/v1/sacco/reports/reconciliation';
  static const String collectorAuditReport = '/api/v1/sacco/reports/collector-audit';

  // Dashboard Routes
  static const String executiveDashboard = '/api/v1/sacco/dashboard/summary';
  static const String collectorDashboard = '/api/v1/sacco/dashboard/collector';

  // SMS / Notification Routes
  static const String sendSms = '/api/v1/sacco/notifications/sms/send';
  static const String smsLogs = '/api/v1/sacco/notifications/sms/logs';
}
