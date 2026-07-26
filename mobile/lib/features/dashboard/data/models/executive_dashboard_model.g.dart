// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'executive_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExecutiveSummaryCardsImpl _$$ExecutiveSummaryCardsImplFromJson(
  Map<String, dynamic> json,
) => _$ExecutiveSummaryCardsImpl(
  todayCollectedLitres:
      (json['today_collected_litres'] as num?)?.toDouble() ?? 0.0,
  todaySalesLitres: (json['today_sales_litres'] as num?)?.toDouble() ?? 0.0,
  todaySpoilageLitres:
      (json['today_spoilage_litres'] as num?)?.toDouble() ?? 0.0,
  todayNetCoolantStationLitres:
      (json['today_net_coolant_station_litres'] as num?)?.toDouble() ?? 0.0,
  monthCollectedLitres:
      (json['month_collected_litres'] as num?)?.toDouble() ?? 0.0,
  monthPayoutLiabilityKes:
      (json['month_payout_liability_kes'] as num?)?.toDouble() ?? 0.0,
  monthSalesRevenueKes:
      (json['month_sales_revenue_kes'] as num?)?.toDouble() ?? 0.0,
  activeMembersCount: (json['active_members_count'] as num?)?.toInt() ?? 0,
  activeCollectorsCount:
      (json['active_collectors_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ExecutiveSummaryCardsImplToJson(
  _$ExecutiveSummaryCardsImpl instance,
) => <String, dynamic>{
  'today_collected_litres': instance.todayCollectedLitres,
  'today_sales_litres': instance.todaySalesLitres,
  'today_spoilage_litres': instance.todaySpoilageLitres,
  'today_net_coolant_station_litres': instance.todayNetCoolantStationLitres,
  'month_collected_litres': instance.monthCollectedLitres,
  'month_payout_liability_kes': instance.monthPayoutLiabilityKes,
  'month_sales_revenue_kes': instance.monthSalesRevenueKes,
  'active_members_count': instance.activeMembersCount,
  'active_collectors_count': instance.activeCollectorsCount,
};

_$DailyTrendPointImpl _$$DailyTrendPointImplFromJson(
  Map<String, dynamic> json,
) => _$DailyTrendPointImpl(
  date: json['date'] as String? ?? '',
  collectedLitres: (json['collected_litres'] as num?)?.toDouble() ?? 0.0,
  salesLitres: (json['sales_litres'] as num?)?.toDouble() ?? 0.0,
  spoilageLitres: (json['spoilage_litres'] as num?)?.toDouble() ?? 0.0,
  netCoolantLitres: (json['net_coolant_litres'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$DailyTrendPointImplToJson(
  _$DailyTrendPointImpl instance,
) => <String, dynamic>{
  'date': instance.date,
  'collected_litres': instance.collectedLitres,
  'sales_litres': instance.salesLitres,
  'spoilage_litres': instance.spoilageLitres,
  'net_coolant_litres': instance.netCoolantLitres,
};

_$ExecutiveDashboardModelImpl _$$ExecutiveDashboardModelImplFromJson(
  Map<String, dynamic> json,
) => _$ExecutiveDashboardModelImpl(
  summaryCards: ExecutiveSummaryCards.fromJson(
    json['summary_cards'] as Map<String, dynamic>,
  ),
  intakeTrend:
      (json['intake_trend'] as List<dynamic>?)
          ?.map((e) => DailyTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$ExecutiveDashboardModelImplToJson(
  _$ExecutiveDashboardModelImpl instance,
) => <String, dynamic>{
  'summary_cards': instance.summaryCards,
  'intake_trend': instance.intakeTrend,
};
