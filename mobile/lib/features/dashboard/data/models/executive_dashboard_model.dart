import 'package:freezed_annotation/freezed_annotation.dart';

part 'executive_dashboard_model.freezed.dart';
part 'executive_dashboard_model.g.dart';

@freezed
class ExecutiveSummaryCards with _$ExecutiveSummaryCards {
  const factory ExecutiveSummaryCards({
    @JsonKey(name: 'today_collected_litres')
    @Default(0.0)
    double todayCollectedLitres,
    @JsonKey(name: 'today_sales_litres') @Default(0.0) double todaySalesLitres,
    @JsonKey(name: 'today_spoilage_litres')
    @Default(0.0)
    double todaySpoilageLitres,
    // Moved between collectors today; does not change the Sacco's balance.
    @JsonKey(name: 'today_transferred_litres')
    @Default(0.0)
    double todayTransferredLitres,
    // collected - sold - spoiled today; > 0 missing, < 0 oversold
    @JsonKey(name: 'today_unaccounted_litres')
    @Default(0.0)
    double todayUnaccountedLitres,
    @JsonKey(name: 'today_balance_status')
    @Default('BALANCED')
    String todayBalanceStatus,
    @JsonKey(name: 'month_collected_litres')
    @Default(0.0)
    double monthCollectedLitres,
    @JsonKey(name: 'month_payout_liability_kes')
    @Default(0.0)
    double monthPayoutLiabilityKes,
    @JsonKey(name: 'month_sales_revenue_kes')
    @Default(0.0)
    double monthSalesRevenueKes,
    @JsonKey(name: 'month_gross_margin_kes')
    @Default(0.0)
    double monthGrossMarginKes,
    @JsonKey(name: 'receivables_kes') @Default(0.0) double receivablesKes,
    @JsonKey(name: 'active_members_count') @Default(0) int activeMembersCount,
    @JsonKey(name: 'active_collectors_count')
    @Default(0)
    int activeCollectorsCount,
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
    @JsonKey(name: 'unaccounted_litres') @Default(0.0) double unaccountedLitres,
  }) = _DailyTrendPoint;

  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyTrendPointFromJson(json);
}

@freezed
class ExecutiveDashboardModel with _$ExecutiveDashboardModel {
  const factory ExecutiveDashboardModel({
    @JsonKey(name: 'summary_cards') required ExecutiveSummaryCards summaryCards,
    @JsonKey(name: 'intake_trend')
    @Default([])
    List<DailyTrendPoint> intakeTrend,
  }) = _ExecutiveDashboardModel;

  factory ExecutiveDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$ExecutiveDashboardModelFromJson(json);
}
