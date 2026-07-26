// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collector_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CollectorDashboardModelImpl _$$CollectorDashboardModelImplFromJson(
  Map<String, dynamic> json,
) => _$CollectorDashboardModelImpl(
  collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
  collectorName: json['collector_name'] as String? ?? '',
  date: json['date'] as String? ?? '',
  todayCollectedLitres:
      (json['today_collected_litres'] as num?)?.toDouble() ?? 0.0,
  todayPurchasesAmount:
      (json['today_purchases_amount'] as num?)?.toDouble() ?? 0.0,
  todayFarmersServiced: (json['today_farmers_serviced'] as num?)?.toInt() ?? 0,
  todaySoldLitres: (json['today_sold_litres'] as num?)?.toDouble() ?? 0.0,
  todaySalesRevenue: (json['today_sales_revenue'] as num?)?.toDouble() ?? 0.0,
  todaySpoiledLitres: (json['today_spoiled_litres'] as num?)?.toDouble() ?? 0.0,
  todayNetStationDeliveryLitres:
      (json['today_net_station_delivery_litres'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$CollectorDashboardModelImplToJson(
  _$CollectorDashboardModelImpl instance,
) => <String, dynamic>{
  'collector_id': instance.collectorId,
  'collector_name': instance.collectorName,
  'date': instance.date,
  'today_collected_litres': instance.todayCollectedLitres,
  'today_purchases_amount': instance.todayPurchasesAmount,
  'today_farmers_serviced': instance.todayFarmersServiced,
  'today_sold_litres': instance.todaySoldLitres,
  'today_sales_revenue': instance.todaySalesRevenue,
  'today_spoiled_litres': instance.todaySpoiledLitres,
  'today_net_station_delivery_litres': instance.todayNetStationDeliveryLitres,
};
