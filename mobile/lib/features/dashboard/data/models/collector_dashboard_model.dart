import 'package:freezed_annotation/freezed_annotation.dart';

part 'collector_dashboard_model.freezed.dart';
part 'collector_dashboard_model.g.dart';

@freezed
class CollectorDashboardModel with _$CollectorDashboardModel {
  const factory CollectorDashboardModel({
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'collector_name') @Default('') String collectorName,
    @Default('') String date,
    @JsonKey(name: 'today_collected_litres') @Default(0.0) double todayCollectedLitres,
    @JsonKey(name: 'today_purchases_amount') @Default(0.0) double todayPurchasesAmount,
    @JsonKey(name: 'today_farmers_serviced') @Default(0) int todayFarmersServiced,
    @JsonKey(name: 'today_sold_litres') @Default(0.0) double todaySoldLitres,
    @JsonKey(name: 'today_sales_revenue') @Default(0.0) double todaySalesRevenue,
    @JsonKey(name: 'today_spoiled_litres') @Default(0.0) double todaySpoiledLitres,
    @JsonKey(name: 'today_net_station_delivery_litres')
    @Default(0.0)
    double todayNetStationDeliveryLitres,
  }) = _CollectorDashboardModel;

  factory CollectorDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$CollectorDashboardModelFromJson(json);
}
