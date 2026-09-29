import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/models/customer_type_total_model.dart';

part 'report_models.freezed.dart';
part 'report_models.g.dart';

@freezed
class FarmerPayoutStatementModel with _$FarmerPayoutStatementModel {
  const factory FarmerPayoutStatementModel({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'membership_number') required String membershipNumber,
    @JsonKey(name: 'farmer_name') required String farmerName,
    @Default('') String phone,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'total_litres') @Default(0.0) double totalLitres,
    @JsonKey(name: 'average_price_per_litre')
    @Default(0.0)
    double averagePricePerLitre,
    @JsonKey(name: 'gross_amount_owed') @Default(0.0) double grossAmountOwed,
    @JsonKey(name: 'collections_count') @Default(0) int collectionsCount,
    @JsonKey(name: 'from_date') String? fromDate,
    @JsonKey(name: 'to_date') String? toDate,
  }) = _FarmerPayoutStatementModel;

  factory FarmerPayoutStatementModel.fromJson(Map<String, dynamic> json) =>
      _$FarmerPayoutStatementModelFromJson(json);
}

@freezed
class CollectorAuditSummaryModel with _$CollectorAuditSummaryModel {
  const factory CollectorAuditSummaryModel({
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'collector_name') @Default('') String collectorName,
    @JsonKey(name: 'total_collected_litres')
    @Default(0.0)
    double totalCollectedLitres,
    @JsonKey(name: 'total_purchases_amount')
    @Default(0.0)
    double totalPurchasesAmount,
    @JsonKey(name: 'total_sold_litres') @Default(0.0) double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue')
    @Default(0.0)
    double totalSalesRevenue,
    @JsonKey(name: 'cash_received_amount')
    @Default(0.0)
    double cashReceivedAmount,
    @JsonKey(name: 'total_spoiled_litres')
    @Default(0.0)
    double totalSpoiledLitres,
    // collected - sold - spoiled; > 0 missing, < 0 oversold
    @JsonKey(name: 'unaccounted_litres') @Default(0.0) double unaccountedLitres,
    @JsonKey(name: 'balance_status') @Default('BALANCED') String balanceStatus,
    // Allowed difference per collector per day, to balance each day alike.
    @JsonKey(name: 'tolerance_litres') @Default(0.0) double toleranceLitres,
    @JsonKey(name: 'active_days') @Default(0) int activeDays,
    @JsonKey(name: 'farmers_serviced_count')
    @Default(0)
    int farmersServicedCount,
  }) = _CollectorAuditSummaryModel;

  factory CollectorAuditSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$CollectorAuditSummaryModelFromJson(json);
}

@freezed
class SaccoReconciliationLedgerModel with _$SaccoReconciliationLedgerModel {
  const factory SaccoReconciliationLedgerModel({
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'sacco_name') String? saccoName,
    @JsonKey(name: 'from_date') @Default('') String fromDate,
    @JsonKey(name: 'to_date') @Default('') String toDate,
    @JsonKey(name: 'total_farmer_intake_litres')
    @Default(0.0)
    double totalFarmerIntakeLitres,
    @JsonKey(name: 'total_farmer_liability_kes')
    @Default(0.0)
    double totalFarmerLiabilityKes,
    @JsonKey(name: 'total_sold_litres') @Default(0.0) double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue_kes')
    @Default(0.0)
    double totalSalesRevenueKes,
    @JsonKey(name: 'cash_received_kes') @Default(0.0) double cashReceivedKes,
    @JsonKey(name: 'credit_sales_kes') @Default(0.0) double creditSalesKes,
    @JsonKey(name: 'total_spoilage_litres')
    @Default(0.0)
    double totalSpoilageLitres,
    // collected - sold - spoiled; > 0 missing, < 0 oversold
    @JsonKey(name: 'unaccounted_litres') @Default(0.0) double unaccountedLitres,
    @JsonKey(name: 'allowance_litres') @Default(0.0) double allowanceLitres,
    @JsonKey(name: 'is_balanced') @Default(true) bool isBalanced,
    @JsonKey(name: 'balance_status') @Default('BALANCED') String balanceStatus,
    @JsonKey(name: 'gross_margin_kes') @Default(0.0) double grossMarginKes,
    @JsonKey(name: 'receivables_kes') @Default(0.0) double receivablesKes,
    @JsonKey(name: 'sales_by_customer_type')
    @Default([])
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'collectors_summary')
    @Default([])
    List<CollectorAuditSummaryModel> collectorsSummary,
  }) = _SaccoReconciliationLedgerModel;

  factory SaccoReconciliationLedgerModel.fromJson(Map<String, dynamic> json) =>
      _$SaccoReconciliationLedgerModelFromJson(json);
}
