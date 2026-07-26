// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_ops_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilkSaleModelImpl _$$MilkSaleModelImplFromJson(Map<String, dynamic> json) =>
    _$MilkSaleModelImpl(
      id: json['id'] as String,
      saccoId: json['sacco_id'] as String? ?? '',
      collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
      saleDate: json['sale_date'] as String,
      buyerName: json['buyer_name'] as String,
      buyerPhone: json['buyer_phone'] as String?,
      quantityLitres: (json['quantity_litres'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'PAID',
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$MilkSaleModelImplToJson(_$MilkSaleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sacco_id': instance.saccoId,
      'collector_id': instance.collectorId,
      'sale_date': instance.saleDate,
      'buyer_name': instance.buyerName,
      'buyer_phone': instance.buyerPhone,
      'quantity_litres': instance.quantityLitres,
      'unit_price': instance.unitPrice,
      'total_amount': instance.totalAmount,
      'payment_status': instance.paymentStatus,
      'payment_method': instance.paymentMethod,
      'notes': instance.notes,
      'created_at': instance.createdAt,
    };

_$RecordSaleRequestModelImpl _$$RecordSaleRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecordSaleRequestModelImpl(
  saleDate: json['sale_date'] as String,
  buyerName: json['buyer_name'] as String,
  buyerPhone: json['buyer_phone'] as String?,
  quantityLitres: (json['quantity_litres'] as num).toDouble(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  paymentStatus: json['payment_status'] as String? ?? 'PAID',
  paymentMethod: json['payment_method'] as String? ?? 'CASH',
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$RecordSaleRequestModelImplToJson(
  _$RecordSaleRequestModelImpl instance,
) => <String, dynamic>{
  'sale_date': instance.saleDate,
  'buyer_name': instance.buyerName,
  'buyer_phone': instance.buyerPhone,
  'quantity_litres': instance.quantityLitres,
  'unit_price': instance.unitPrice,
  'payment_status': instance.paymentStatus,
  'payment_method': instance.paymentMethod,
  'notes': instance.notes,
};

_$MilkSpoilageModelImpl _$$MilkSpoilageModelImplFromJson(
  Map<String, dynamic> json,
) => _$MilkSpoilageModelImpl(
  id: json['id'] as String,
  saccoId: json['sacco_id'] as String? ?? '',
  collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
  spoilageDate: json['spoilage_date'] as String,
  quantityLitres: (json['quantity_litres'] as num?)?.toDouble() ?? 0.0,
  reason: json['reason'] as String,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$$MilkSpoilageModelImplToJson(
  _$MilkSpoilageModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'sacco_id': instance.saccoId,
  'collector_id': instance.collectorId,
  'spoilage_date': instance.spoilageDate,
  'quantity_litres': instance.quantityLitres,
  'reason': instance.reason,
  'notes': instance.notes,
  'created_at': instance.createdAt,
};

_$RecordSpoilageRequestModelImpl _$$RecordSpoilageRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecordSpoilageRequestModelImpl(
  spoilageDate: json['spoilage_date'] as String,
  quantityLitres: (json['quantity_litres'] as num).toDouble(),
  reason: json['reason'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$RecordSpoilageRequestModelImplToJson(
  _$RecordSpoilageRequestModelImpl instance,
) => <String, dynamic>{
  'spoilage_date': instance.spoilageDate,
  'quantity_litres': instance.quantityLitres,
  'reason': instance.reason,
  'notes': instance.notes,
};

_$ReconciliationModelImpl _$$ReconciliationModelImplFromJson(
  Map<String, dynamic> json,
) => _$ReconciliationModelImpl(
  collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
  collectorName: json['collector_name'] as String? ?? '',
  date: json['date'] as String? ?? '',
  totalCollectedLitres:
      (json['total_collected_litres'] as num?)?.toDouble() ?? 0.0,
  totalSoldLitres: (json['total_sold_litres'] as num?)?.toDouble() ?? 0.0,
  totalSpoiledLitres: (json['total_spoiled_litres'] as num?)?.toDouble() ?? 0.0,
  netDeliveredLitres: (json['net_delivered_litres'] as num?)?.toDouble() ?? 0.0,
  totalSalesAmount: (json['total_sales_amount'] as num?)?.toDouble() ?? 0.0,
  totalPurchasesAmount:
      (json['total_purchases_amount'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ReconciliationModelImplToJson(
  _$ReconciliationModelImpl instance,
) => <String, dynamic>{
  'collector_id': instance.collectorId,
  'collector_name': instance.collectorName,
  'date': instance.date,
  'total_collected_litres': instance.totalCollectedLitres,
  'total_sold_litres': instance.totalSoldLitres,
  'total_spoiled_litres': instance.totalSpoiledLitres,
  'net_delivered_litres': instance.netDeliveredLitres,
  'total_sales_amount': instance.totalSalesAmount,
  'total_purchases_amount': instance.totalPurchasesAmount,
};
