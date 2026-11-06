import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/money.dart';

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
    // Litres of measuring difference tolerated per collector per day when balancing milk.
    @JsonKey(name: 'reconciliation_tolerance_litres')
    @Default(0.0)
    double reconciliationToleranceLitres,
    // Days without milk after which an active farmer becomes inactive; 0 = never.
    @JsonKey(name: 'inactive_after_days') @Default(60) int inactiveAfterDays,
    // Most a farmer may take in advances between pay runs; null = no limit.
    @JsonKey(name: 'advance_max_per_period') double? advanceMaxPerPeriod,
    // Advances only from this day of the month to its end; null = any day.
    @JsonKey(name: 'advance_from_day') int? advanceFromDay,
    // Advances may not pass this % of milk delivered, less what is owed; null = no check.
    @JsonKey(name: 'advance_milk_percent') int? advanceMilkPercent,
  }) = _SaccoSettingsModel;

  factory SaccoSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SaccoSettingsModelFromJson(json);
}

/// What a Sacco price from a date changes (or would change, when checking):
/// unpaid milk from that date follows it, paid months and farmers on their
/// own price do not.
class SaccoPriceCheck {
  final int repriced;
  final int farmers;
  final int ownPriceFarmers;
  final double valueChange;

  /// Set when the date falls in a closed period: milk up to this day is paid
  /// and keeps its price.
  final DateTime? paidThrough;

  const SaccoPriceCheck({
    required this.repriced,
    required this.farmers,
    required this.ownPriceFarmers,
    required this.valueChange,
    this.paidThrough,
  });

  factory SaccoPriceCheck.fromJson(Map<String, dynamic> j) => SaccoPriceCheck(
    repriced: (j['repriced'] as num?)?.toInt() ?? 0,
    farmers: (j['farmers'] as num?)?.toInt() ?? 0,
    ownPriceFarmers: (j['own_price_farmers'] as num?)?.toInt() ?? 0,
    valueChange: toDouble(j['value_change']),
    paidThrough: DateTime.tryParse(j['paid_through'] as String? ?? ''),
  );

  /// The person should see this before the price is saved.
  bool get worthShowing => repriced > 0 || paidThrough != null;
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
