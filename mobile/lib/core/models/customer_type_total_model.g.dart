// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_type_total_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerTypeTotalModelImpl _$$CustomerTypeTotalModelImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerTypeTotalModelImpl(
  customerType: json['customer_type'] as String? ?? 'OTHER',
  litres: (json['litres'] as num?)?.toDouble() ?? 0.0,
  revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$CustomerTypeTotalModelImplToJson(
  _$CustomerTypeTotalModelImpl instance,
) => <String, dynamic>{
  'customer_type': instance.customerType,
  'litres': instance.litres,
  'revenue': instance.revenue,
};
