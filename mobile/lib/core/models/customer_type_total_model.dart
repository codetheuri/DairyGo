import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_type_total_model.freezed.dart';
part 'customer_type_total_model.g.dart';

/// Milk sold to one type of customer (e.g. COOLER) over a period.
@freezed
class CustomerTypeTotalModel with _$CustomerTypeTotalModel {
  const factory CustomerTypeTotalModel({
    @JsonKey(name: 'customer_type') @Default('OTHER') String customerType,
    @Default(0.0) double litres,
    @Default(0.0) double revenue,
  }) = _CustomerTypeTotalModel;

  factory CustomerTypeTotalModel.fromJson(Map<String, dynamic> json) => _$CustomerTypeTotalModelFromJson(json);
}
