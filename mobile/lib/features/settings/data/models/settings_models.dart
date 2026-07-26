import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_models.freezed.dart';
part 'settings_models.g.dart';

@freezed
class SaccoProfileModel with _$SaccoProfileModel {
  const factory SaccoProfileModel({
    required String id,
    required String name,
    required String code,
    String? email,
    String? phone,
    String? address,
    @Default('ACTIVE') String status,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _SaccoProfileModel;

  factory SaccoProfileModel.fromJson(Map<String, dynamic> json) =>
      _$SaccoProfileModelFromJson(json);
}

@freezed
class SaccoSettingsModel with _$SaccoSettingsModel {
  const factory SaccoSettingsModel({
    @JsonKey(name: 'sacco_id') required String saccoId,
    @Default('KES') String currency,
    @JsonKey(name: 'milk_unit') @Default('LITRES') String milkUnit,
    @JsonKey(name: 'morning_cutoff_time') String? morningCutoffTime,
    @JsonKey(name: 'evening_cutoff_time') String? eveningCutoffTime,
  }) = _SaccoSettingsModel;

  factory SaccoSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SaccoSettingsModelFromJson(json);
}

@freezed
class SetPriceRequestModel with _$SetPriceRequestModel {
  const factory SetPriceRequestModel({
    @JsonKey(name: 'price_per_litre') required double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
  }) = _SetPriceRequestModel;

  factory SetPriceRequestModel.fromJson(Map<String, dynamic> json) =>
      _$SetPriceRequestModelFromJson(json);
}
