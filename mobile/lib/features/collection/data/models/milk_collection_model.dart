import 'package:freezed_annotation/freezed_annotation.dart';

part 'milk_collection_model.freezed.dart';
part 'milk_collection_model.g.dart';

@freezed
class MilkPriceModel with _$MilkPriceModel {
  const factory MilkPriceModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'price_per_litre') @Default(0.0) double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _MilkPriceModel;

  factory MilkPriceModel.fromJson(Map<String, dynamic> json) =>
      _$MilkPriceModelFromJson(json);
}

@freezed
class MilkCollectionModel with _$MilkCollectionModel {
  const MilkCollectionModel._();

  const factory MilkCollectionModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'collector_id') @Default(0) int collectorId,
    @JsonKey(name: 'collection_date') required String collectionDate,
    @Default('MORNING') String shift,
    @JsonKey(name: 'quantity_litres') @Default(0.0) double quantityLitres,
    @JsonKey(name: 'price_per_litre') @Default(0.0) double pricePerLitre,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @Default('SUBMITTED') String status,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    // Optional populated member fields
    @JsonKey(name: 'member_name') String? memberName,
    @JsonKey(name: 'membership_number') String? membershipNumber,
  }) = _MilkCollectionModel;

  factory MilkCollectionModel.fromJson(Map<String, dynamic> json) =>
      _$MilkCollectionModelFromJson(json);
}

@freezed
class RecordCollectionRequestModel with _$RecordCollectionRequestModel {
  const factory RecordCollectionRequestModel({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'collection_date') String? collectionDate,
    @Default('MORNING') String shift,
    @JsonKey(name: 'quantity_litres') required double quantityLitres,
    @JsonKey(name: 'price_per_litre') double? pricePerLitre,
    String? notes,
  }) = _RecordCollectionRequestModel;

  factory RecordCollectionRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RecordCollectionRequestModelFromJson(json);
}

@freezed
class UpdateCollectionRequestModel with _$UpdateCollectionRequestModel {
  const factory UpdateCollectionRequestModel({
    @JsonKey(name: 'quantity_litres') double? quantityLitres,
    String? shift,
    String? notes,
  }) = _UpdateCollectionRequestModel;

  factory UpdateCollectionRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateCollectionRequestModelFromJson(json);
}
