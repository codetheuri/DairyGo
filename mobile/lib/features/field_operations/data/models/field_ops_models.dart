import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_ops_models.freezed.dart';
part 'field_ops_models.g.dart';

@freezed
class MilkSaleModel with _$MilkSaleModel {
  const factory MilkSaleModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'buyer_name') required String buyerName,
    @JsonKey(name: 'buyer_phone') String? buyerPhone,
    @JsonKey(name: 'quantity_litres') @Default(0.0) double quantityLitres,
    @JsonKey(name: 'unit_price') @Default(0.0) double unitPrice,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @JsonKey(name: 'payment_status') @Default('PAID') String paymentStatus,
    @JsonKey(name: 'payment_method') @Default('CASH') String paymentMethod,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MilkSaleModel;

  factory MilkSaleModel.fromJson(Map<String, dynamic> json) =>
      _$MilkSaleModelFromJson(json);
}

@freezed
class RecordSaleRequestModel with _$RecordSaleRequestModel {
  const factory RecordSaleRequestModel({
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'buyer_name') required String buyerName,
    @JsonKey(name: 'buyer_phone') String? buyerPhone,
    @JsonKey(name: 'quantity_litres') required double quantityLitres,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'payment_status') @Default('PAID') String paymentStatus,
    @JsonKey(name: 'payment_method') @Default('CASH') String paymentMethod,
    String? notes,
  }) = _RecordSaleRequestModel;

  factory RecordSaleRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RecordSaleRequestModelFromJson(json);
}

@freezed
class MilkSpoilageModel with _$MilkSpoilageModel {
  const factory MilkSpoilageModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'spoilage_date') required String spoilageDate,
    @JsonKey(name: 'quantity_litres') @Default(0.0) double quantityLitres,
    required String reason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MilkSpoilageModel;

  factory MilkSpoilageModel.fromJson(Map<String, dynamic> json) =>
      _$MilkSpoilageModelFromJson(json);
}

@freezed
class RecordSpoilageRequestModel with _$RecordSpoilageRequestModel {
  const factory RecordSpoilageRequestModel({
    @JsonKey(name: 'spoilage_date') required String spoilageDate,
    @JsonKey(name: 'quantity_litres') required double quantityLitres,
    required String reason,
    String? notes,
  }) = _RecordSpoilageRequestModel;

  factory RecordSpoilageRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RecordSpoilageRequestModelFromJson(json);
}

@freezed
class ReconciliationModel with _$ReconciliationModel {
  const factory ReconciliationModel({
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'collector_name') @Default('') String collectorName,
    @Default('') String date,
    @JsonKey(name: 'total_collected_litres') @Default(0.0) double totalCollectedLitres,
    @JsonKey(name: 'total_sold_litres') @Default(0.0) double totalSoldLitres,
    @JsonKey(name: 'total_spoiled_litres') @Default(0.0) double totalSpoiledLitres,
    @JsonKey(name: 'net_delivered_litres') @Default(0.0) double netDeliveredLitres,
    @JsonKey(name: 'total_sales_amount') @Default(0.0) double totalSalesAmount,
    @JsonKey(name: 'total_purchases_amount') @Default(0.0) double totalPurchasesAmount,
  }) = _ReconciliationModel;

  factory ReconciliationModel.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationModelFromJson(json);
}
