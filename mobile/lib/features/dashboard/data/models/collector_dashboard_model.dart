import 'package:freezed_annotation/freezed_annotation.dart';

part 'collector_dashboard_model.freezed.dart';
part 'collector_dashboard_model.g.dart';

@freezed
class CollectorDashboardModel with _$CollectorDashboardModel {
  const factory CollectorDashboardModel({
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'collector_name') @Default('') String collectorName,
    @Default('') String date,
    @JsonKey(name: 'today_collected_litres')
    @Default(0.0)
    double todayCollectedLitres,
    @JsonKey(name: 'today_purchases_amount')
    @Default(0.0)
    double todayPurchasesAmount,
    @JsonKey(name: 'today_farmers_serviced')
    @Default(0)
    int todayFarmersServiced,
    @JsonKey(name: 'today_sold_litres') @Default(0.0) double todaySoldLitres,
    @JsonKey(name: 'today_sales_revenue')
    @Default(0.0)
    double todaySalesRevenue,
    @JsonKey(name: 'today_cash_received')
    @Default(0.0)
    double todayCashReceived,
    @JsonKey(name: 'today_spoiled_litres')
    @Default(0.0)
    double todaySpoiledLitres,
    // collected - sold - spoiled today; > 0 missing, < 0 oversold
    @JsonKey(name: 'today_unaccounted_litres')
    @Default(0.0)
    double todayUnaccountedLitres,
    @JsonKey(name: 'today_balance_status')
    @Default('BALANCED')
    String todayBalanceStatus,
  }) = _CollectorDashboardModel;

  factory CollectorDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$CollectorDashboardModelFromJson(json);
}
