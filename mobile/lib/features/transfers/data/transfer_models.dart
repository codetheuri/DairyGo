import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_models.freezed.dart';
part 'transfer_models.g.dart';

/// Milk handed from one collector to another. It counts at once for both:
/// out of the sender's balance and into the receiver's.
@freezed
class MilkTransferModel with _$MilkTransferModel {
  const MilkTransferModel._();

  const factory MilkTransferModel({
    required String id,
    @JsonKey(name: 'from_collector_id') @Default(0) int fromCollectorId,
    @JsonKey(name: 'to_collector_id') @Default(0) int toCollectorId,
    @JsonKey(name: 'from_collector_name') @Default('') String fromCollectorName,
    @JsonKey(name: 'to_collector_name') @Default('') String toCollectorName,
    @JsonKey(name: 'transfer_date') required String transferDate,
    @JsonKey(name: 'quantity_litres') @Default(0.0) double quantityLitres,
    String? notes,
    @JsonKey(name: 'recorded_by_id') @Default(0) int recordedById,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    @JsonKey(name: 'created_at') String? createdAt,
    // Set when DairyGo support entered the record after its day.
    @JsonKey(name: 'late_reason') String? lateReason,
  }) = _MilkTransferModel;

  bool get isCancelled => voidedAt != null;

  /// The day, without the time part the API adds (YYYY-MM-DD).
  String get day => transferDate.split('T').first;

  /// Whether [userId] sent it (true), received it (false) or neither (null).
  bool? sentBy(int userId) => fromCollectorId == userId
      ? true
      : toCollectorId == userId
      ? false
      : null;

  factory MilkTransferModel.fromJson(Map<String, dynamic> json) =>
      _$MilkTransferModelFromJson(json);
}

/// A colleague milk can be transferred to.
@freezed
class TransferRecipientModel with _$TransferRecipientModel {
  const factory TransferRecipientModel({
    required int id,
    @Default('') String name,
    @Default('') String username,
  }) = _TransferRecipientModel;

  factory TransferRecipientModel.fromJson(Map<String, dynamic> json) =>
      _$TransferRecipientModelFromJson(json);
}
