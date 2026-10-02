// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilkTransferModelImpl _$$MilkTransferModelImplFromJson(
  Map<String, dynamic> json,
) => _$MilkTransferModelImpl(
  id: json['id'] as String,
  fromCollectorId: (json['from_collector_id'] as num?)?.toInt() ?? 0,
  toCollectorId: (json['to_collector_id'] as num?)?.toInt() ?? 0,
  fromCollectorName: json['from_collector_name'] as String? ?? '',
  toCollectorName: json['to_collector_name'] as String? ?? '',
  transferDate: json['transfer_date'] as String,
  quantityLitres: (json['quantity_litres'] as num?)?.toDouble() ?? 0.0,
  notes: json['notes'] as String?,
  recordedById: (json['recorded_by_id'] as num?)?.toInt() ?? 0,
  voidedAt: json['voided_at'] as String?,
  voidReason: json['void_reason'] as String?,
  createdAt: json['created_at'] as String?,
  lateReason: json['late_reason'] as String?,
);

Map<String, dynamic> _$$MilkTransferModelImplToJson(
  _$MilkTransferModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'from_collector_id': instance.fromCollectorId,
  'to_collector_id': instance.toCollectorId,
  'from_collector_name': instance.fromCollectorName,
  'to_collector_name': instance.toCollectorName,
  'transfer_date': instance.transferDate,
  'quantity_litres': instance.quantityLitres,
  'notes': instance.notes,
  'recorded_by_id': instance.recordedById,
  'voided_at': instance.voidedAt,
  'void_reason': instance.voidReason,
  'created_at': instance.createdAt,
  'late_reason': instance.lateReason,
};

_$TransferRecipientModelImpl _$$TransferRecipientModelImplFromJson(
  Map<String, dynamic> json,
) => _$TransferRecipientModelImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  username: json['username'] as String? ?? '',
);

Map<String, dynamic> _$$TransferRecipientModelImplToJson(
  _$TransferRecipientModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
};
