// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milk_collection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilkPriceModelImpl _$$MilkPriceModelImplFromJson(Map<String, dynamic> json) =>
    _$MilkPriceModelImpl(
      id: json['id'] as String,
      saccoId: json['sacco_id'] as String? ?? '',
      pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: json['effective_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$$MilkPriceModelImplToJson(
  _$MilkPriceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'sacco_id': instance.saccoId,
  'price_per_litre': instance.pricePerLitre,
  'effective_date': instance.effectiveDate,
  'is_active': instance.isActive,
};

_$MilkCollectionModelImpl _$$MilkCollectionModelImplFromJson(
  Map<String, dynamic> json,
) => _$MilkCollectionModelImpl(
  id: json['id'] as String,
  saccoId: json['sacco_id'] as String? ?? '',
  memberId: json['member_id'] as String,
  collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
  collectionDate: json['collection_date'] as String,
  shift: json['shift'] as String? ?? 'MORNING',
  quantityLitres: (json['quantity_litres'] as num?)?.toDouble() ?? 0.0,
  pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 0.0,
  totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
  status: json['status'] as String? ?? 'SUBMITTED',
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String?,
  memberName: json['member_name'] as String?,
  membershipNumber: json['membership_number'] as String?,
);

Map<String, dynamic> _$$MilkCollectionModelImplToJson(
  _$MilkCollectionModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'sacco_id': instance.saccoId,
  'member_id': instance.memberId,
  'collector_id': instance.collectorId,
  'collection_date': instance.collectionDate,
  'shift': instance.shift,
  'quantity_litres': instance.quantityLitres,
  'price_per_litre': instance.pricePerLitre,
  'total_amount': instance.totalAmount,
  'status': instance.status,
  'notes': instance.notes,
  'created_at': instance.createdAt,
  'member_name': instance.memberName,
  'membership_number': instance.membershipNumber,
};

_$RecordCollectionRequestModelImpl _$$RecordCollectionRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecordCollectionRequestModelImpl(
  memberId: json['member_id'] as String,
  collectionDate: json['collection_date'] as String?,
  shift: json['shift'] as String? ?? 'MORNING',
  quantityLitres: (json['quantity_litres'] as num).toDouble(),
  pricePerLitre: (json['price_per_litre'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$RecordCollectionRequestModelImplToJson(
  _$RecordCollectionRequestModelImpl instance,
) => <String, dynamic>{
  'member_id': instance.memberId,
  'collection_date': instance.collectionDate,
  'shift': instance.shift,
  'quantity_litres': instance.quantityLitres,
  'price_per_litre': instance.pricePerLitre,
  'notes': instance.notes,
};

_$UpdateCollectionRequestModelImpl _$$UpdateCollectionRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$UpdateCollectionRequestModelImpl(
  quantityLitres: (json['quantity_litres'] as num?)?.toDouble(),
  shift: json['shift'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$UpdateCollectionRequestModelImplToJson(
  _$UpdateCollectionRequestModelImpl instance,
) => <String, dynamic>{
  'quantity_litres': instance.quantityLitres,
  'shift': instance.shift,
  'notes': instance.notes,
};
