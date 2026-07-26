import 'package:freezed_annotation/freezed_annotation.dart';

part 'executive_dashboard_model.freezed.dart';
part 'executive_dashboard_model.g.dart';

@freezed
class ExecutiveSummaryCards with _$ExecutiveSummaryCards {
  const factory ExecutiveSummaryCards({
    @JsonKey(name: 'today_collected_litres') @Default(0.0) double todayCollectedLitres,
    @JsonKey(name: 'today_sales_litres') @Default(0.0) double todaySalesLitres,
    @JsonKey(name: 'today_spoilage_litres') @Default(0.0) double todaySpoilageLitres,
    @JsonKey(name: 'today_net_coolant_station_litres')
    @Default(0.0)
    double todayNetCoolantStationLitres,
    @JsonKey(name: 'month_collected_litres') @Default(0.0) double monthCollectedLitres,
    @JsonKey(name: 'month_payout_liability_kes') @Default(0.0) double monthPayoutLiabilityKes,
    @JsonKey(name: 'month_sales_revenue_kes') @Default(0.0) double monthSalesRevenueKes,
    @JsonKey(name: 'active_members_count') @Default(0) int activeMembersCount,
    @JsonKey(name: 'active_collectors_count') @Default(0) int activeCollectorsCount,
  }) = _ExecutiveSummaryCards;

  factory ExecutiveSummaryCards.fromJson(Map<String, dynamic> json) =>
      _$ExecutiveSummaryCardsFromJson(json);
}

@freezed
class DailyTrendPoint with _$DailyTrendPoint {
  const factory DailyTrendPoint({
    @Default('') String date,
    @JsonKey(name: 'collected_litres') @Default(0.0) double collectedLitres,
    @JsonKey(name: 'sales_litres') @Default(0.0) double salesLitres,
    @JsonKey(name: 'spoilage_litres') @Default(0.0) double spoilageLitres,
    @JsonKey(name: 'net_coolant_litres') @Default(0.0) double netCoolantLitres,
  }) = _DailyTrendPoint;

  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyTrendPointFromJson(json);
}

@freezed
class ExecutiveDashboardModel with _$ExecutiveDashboardModel {
  const factory ExecutiveDashboardModel({
    @JsonKey(name: 'summary_cards') required ExecutiveSummaryCards summaryCards,
    @JsonKey(name: 'intake_trend') @Default([]) List<DailyTrendPoint> intakeTrend,
  }) = _ExecutiveDashboardModel;

  factory ExecutiveDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$ExecutiveDashboardModelFromJson(json);
}
