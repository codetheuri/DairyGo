import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/models/customer_type_total_model.dart';
import '../../../transfers/data/transfer_models.dart';

part 'field_ops_models.freezed.dart';
part 'field_ops_models.g.dart';

/// Milk sold to a customer. Every litre leaving a collector is a sale, coolers
/// included. [buyerName] is the customer's name at the time of sale.
@freezed
class MilkSaleModel with _$MilkSaleModel {
  const MilkSaleModel._();

  const factory MilkSaleModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'customer_id') @Default('') String customerId,
    @JsonKey(name: 'customer_type') String? customerType,
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'buyer_name') required String buyerName,
    @JsonKey(name: 'buyer_phone') String? buyerPhone,
    @JsonKey(name: 'quantity_litres') @Default(0.0) double quantityLitres,
    @JsonKey(name: 'unit_price') @Default(0.0) double unitPrice,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @JsonKey(name: 'amount_paid') @Default(0.0) double amountPaid,
    @JsonKey(name: 'payment_status') @Default('PAID') String paymentStatus,
    @JsonKey(name: 'payment_method') @Default('CASH') String paymentMethod,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'collector_name') String? collectorName,
    // Set when DairyGo support entered the record after its day.
    @JsonKey(name: 'late_reason') String? lateReason,
  }) = _MilkSaleModel;

  bool get isVoided => voidedAt != null;

  /// Amount left unpaid at the time of sale; it went on the customer's balance.
  double get amountOnCredit => isVoided ? 0 : (totalAmount - amountPaid);

  factory MilkSaleModel.fromJson(Map<String, dynamic> json) =>
      _$MilkSaleModelFromJson(json);
}

/// A sale to an existing customer. [amountPaid] is what was paid at the sale;
/// the rest goes on the customer's balance. Use method CREDIT when nothing was paid.
@freezed
class RecordSaleRequestModel with _$RecordSaleRequestModel {
  const factory RecordSaleRequestModel({
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'sale_date') String? saleDate,
    @JsonKey(name: 'quantity_litres') required double quantityLitres,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'amount_paid') required double amountPaid,
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
    @JsonKey(name: 'collector_name') String? collectorName,
    // Set when DairyGo support entered the record after its day.
    @JsonKey(name: 'late_reason') String? lateReason,
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
    @JsonKey(name: 'total_collected_litres')
    @Default(0.0)
    double totalCollectedLitres,
    @JsonKey(name: 'total_sold_litres') @Default(0.0) double totalSoldLitres,
    @JsonKey(name: 'total_spoiled_litres')
    @Default(0.0)
    double totalSpoiledLitres,
    // Milk from and to other collectors on the day.
    @JsonKey(name: 'total_received_litres')
    @Default(0.0)
    double totalReceivedLitres,
    @JsonKey(name: 'total_transferred_out_litres')
    @Default(0.0)
    double totalTransferredOutLitres,
    // collected + received - sold - transferred out - spoiled;
    // > 0 missing, < 0 oversold
    @JsonKey(name: 'unaccounted_litres') @Default(0.0) double unaccountedLitres,
    @JsonKey(name: 'balance_status') @Default('BALANCED') String balanceStatus,
    @JsonKey(name: 'total_sales_amount') @Default(0.0) double totalSalesAmount,
    @JsonKey(name: 'cash_received_amount')
    @Default(0.0)
    double cashReceivedAmount,
    @JsonKey(name: 'credit_sales_amount')
    @Default(0.0)
    double creditSalesAmount,
    @JsonKey(name: 'sales_by_customer_type')
    @Default([])
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'total_purchases_amount')
    @Default(0.0)
    double totalPurchasesAmount,
    @Default([]) List<MilkTransferModel> transfers,
  }) = _ReconciliationModel;

  factory ReconciliationModel.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationModelFromJson(json);
}
