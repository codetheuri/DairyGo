// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FarmerPayoutStatementModelImpl _$$FarmerPayoutStatementModelImplFromJson(
  Map<String, dynamic> json,
) => _$FarmerPayoutStatementModelImpl(
  memberId: json['member_id'] as String,
  membershipNumber: json['membership_number'] as String,
  farmerName: json['farmer_name'] as String,
  phone: json['phone'] as String? ?? '',
  mpesaNumber: json['mpesa_number'] as String?,
  bankAccountNumber: json['bank_account_number'] as String?,
  bankName: json['bank_name'] as String?,
  totalLitres: (json['total_litres'] as num?)?.toDouble() ?? 0.0,
  averagePricePerLitre:
      (json['average_price_per_litre'] as num?)?.toDouble() ?? 0.0,
  grossAmountOwed: (json['gross_amount_owed'] as num?)?.toDouble() ?? 0.0,
  collectionsCount: (json['collections_count'] as num?)?.toInt() ?? 0,
  fromDate: json['from_date'] as String?,
  toDate: json['to_date'] as String?,
);

Map<String, dynamic> _$$FarmerPayoutStatementModelImplToJson(
  _$FarmerPayoutStatementModelImpl instance,
) => <String, dynamic>{
  'member_id': instance.memberId,
  'membership_number': instance.membershipNumber,
  'farmer_name': instance.farmerName,
  'phone': instance.phone,
  'mpesa_number': instance.mpesaNumber,
  'bank_account_number': instance.bankAccountNumber,
  'bank_name': instance.bankName,
  'total_litres': instance.totalLitres,
  'average_price_per_litre': instance.averagePricePerLitre,
  'gross_amount_owed': instance.grossAmountOwed,
  'collections_count': instance.collectionsCount,
  'from_date': instance.fromDate,
  'to_date': instance.toDate,
};

_$CollectorAuditSummaryModelImpl _$$CollectorAuditSummaryModelImplFromJson(
  Map<String, dynamic> json,
) => _$CollectorAuditSummaryModelImpl(
  collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
  collectorName: json['collector_name'] as String? ?? '',
  totalCollectedLitres:
      (json['total_collected_litres'] as num?)?.toDouble() ?? 0.0,
  totalPurchasesAmount:
      (json['total_purchases_amount'] as num?)?.toDouble() ?? 0.0,
  totalSoldLitres: (json['total_sold_litres'] as num?)?.toDouble() ?? 0.0,
  totalSalesRevenue: (json['total_sales_revenue'] as num?)?.toDouble() ?? 0.0,
  totalSpoiledLitres: (json['total_spoiled_litres'] as num?)?.toDouble() ?? 0.0,
  netDeliveredLitres: (json['net_delivered_litres'] as num?)?.toDouble() ?? 0.0,
  farmersServicedCount: (json['farmers_serviced_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CollectorAuditSummaryModelImplToJson(
  _$CollectorAuditSummaryModelImpl instance,
) => <String, dynamic>{
  'collector_id': instance.collectorId,
  'collector_name': instance.collectorName,
  'total_collected_litres': instance.totalCollectedLitres,
  'total_purchases_amount': instance.totalPurchasesAmount,
  'total_sold_litres': instance.totalSoldLitres,
  'total_sales_revenue': instance.totalSalesRevenue,
  'total_spoiled_litres': instance.totalSpoiledLitres,
  'net_delivered_litres': instance.netDeliveredLitres,
  'farmers_serviced_count': instance.farmersServicedCount,
};

_$SaccoReconciliationLedgerModelImpl
_$$SaccoReconciliationLedgerModelImplFromJson(
  Map<String, dynamic> json,
) => _$SaccoReconciliationLedgerModelImpl(
  saccoId: json['sacco_id'] as String? ?? '',
  saccoName: json['sacco_name'] as String?,
  fromDate: json['from_date'] as String? ?? '',
  toDate: json['to_date'] as String? ?? '',
  totalFarmerIntakeLitres:
      (json['total_farmer_intake_litres'] as num?)?.toDouble() ?? 0.0,
  totalFarmerLiabilityKes:
      (json['total_farmer_liability_kes'] as num?)?.toDouble() ?? 0.0,
  totalFieldSalesLitres:
      (json['total_field_sales_litres'] as num?)?.toDouble() ?? 0.0,
  totalFieldSalesRevenueKes:
      (json['total_field_sales_revenue_kes'] as num?)?.toDouble() ?? 0.0,
  totalSpoilageLitres:
      (json['total_spoilage_litres'] as num?)?.toDouble() ?? 0.0,
  netCoolantStationLitres:
      (json['net_coolant_station_litres'] as num?)?.toDouble() ?? 0.0,
  isBalanced: json['is_balanced'] as bool? ?? true,
  discrepancyLitres: (json['discrepancy_litres'] as num?)?.toDouble() ?? 0.0,
  collectorsSummary:
      (json['collectors_summary'] as List<dynamic>?)
          ?.map(
            (e) =>
                CollectorAuditSummaryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$$SaccoReconciliationLedgerModelImplToJson(
  _$SaccoReconciliationLedgerModelImpl instance,
) => <String, dynamic>{
  'sacco_id': instance.saccoId,
  'sacco_name': instance.saccoName,
  'from_date': instance.fromDate,
  'to_date': instance.toDate,
  'total_farmer_intake_litres': instance.totalFarmerIntakeLitres,
  'total_farmer_liability_kes': instance.totalFarmerLiabilityKes,
  'total_field_sales_litres': instance.totalFieldSalesLitres,
  'total_field_sales_revenue_kes': instance.totalFieldSalesRevenueKes,
  'total_spoilage_litres': instance.totalSpoilageLitres,
  'net_coolant_station_litres': instance.netCoolantStationLitres,
  'is_balanced': instance.isBalanced,
  'discrepancy_litres': instance.discrepancyLitres,
  'collectors_summary': instance.collectorsSummary,
};
