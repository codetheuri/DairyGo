// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SaccoProfileModelImpl _$$SaccoProfileModelImplFromJson(
  Map<String, dynamic> json,
) => _$SaccoProfileModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  code: json['code'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  status: json['status'] as String? ?? 'ACTIVE',
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$$SaccoProfileModelImplToJson(
  _$SaccoProfileModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'status': instance.status,
  'created_at': instance.createdAt,
};

_$SaccoSettingsModelImpl _$$SaccoSettingsModelImplFromJson(
  Map<String, dynamic> json,
) => _$SaccoSettingsModelImpl(
  saccoId: json['sacco_id'] as String,
  currency: json['currency'] as String? ?? 'KES',
  milkUnit: json['milk_unit'] as String? ?? 'LITRES',
  morningCutoffTime: json['morning_cutoff_time'] as String?,
  eveningCutoffTime: json['evening_cutoff_time'] as String?,
  reconciliationToleranceLitres:
      (json['reconciliation_tolerance_litres'] as num?)?.toDouble() ?? 0.0,
  inactiveAfterDays: (json['inactive_after_days'] as num?)?.toInt() ?? 60,
  advanceMaxPerPeriod: (json['advance_max_per_period'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$SaccoSettingsModelImplToJson(
  _$SaccoSettingsModelImpl instance,
) => <String, dynamic>{
  'sacco_id': instance.saccoId,
  'currency': instance.currency,
  'milk_unit': instance.milkUnit,
  'morning_cutoff_time': instance.morningCutoffTime,
  'evening_cutoff_time': instance.eveningCutoffTime,
  'reconciliation_tolerance_litres': instance.reconciliationToleranceLitres,
  'inactive_after_days': instance.inactiveAfterDays,
  'advance_max_per_period': instance.advanceMaxPerPeriod,
};

_$SetPriceRequestModelImpl _$$SetPriceRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$SetPriceRequestModelImpl(
  pricePerLitre: (json['price_per_litre'] as num).toDouble(),
  effectiveDate: json['effective_date'] as String?,
);

Map<String, dynamic> _$$SetPriceRequestModelImplToJson(
  _$SetPriceRequestModelImpl instance,
) => <String, dynamic>{
  'price_per_litre': instance.pricePerLitre,
  'effective_date': instance.effectiveDate,
};
