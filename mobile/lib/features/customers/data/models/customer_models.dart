import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_models.freezed.dart';
part 'customer_models.g.dart';

/// Customer types. Coolers are customers like any other buyer.
const customerTypes = [
  'COOLER',
  'PROCESSOR',
  'HOTEL',
  'SHOP',
  'INDIVIDUAL',
  'OTHER',
];

String customerTypeLabel(String type) {
  switch (type) {
    case 'COOLER':
      return 'Cooler';
    case 'PROCESSOR':
      return 'Processor';
    case 'HOTEL':
      return 'Hotel';
    case 'SHOP':
      return 'Shop';
    case 'INDIVIDUAL':
      return 'Individual';
    default:
      return 'Other';
  }
}

/// A buyer of milk. [balance] is what the customer owes the Sacco; it is only
/// sent to users allowed to read statements (admins and board members).
@freezed
class CustomerModel with _$CustomerModel {
  const CustomerModel._();

  const factory CustomerModel({
    required String id,
    required String name,
    String? phone,
    @JsonKey(name: 'customer_type') @Default('OTHER') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    @Default('ACTIVE') String status,
    String? notes,
    double? balance,
  }) = _CustomerModel;

  bool get isActive => status == 'ACTIVE';

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
}

@freezed
class CreateCustomerRequestModel with _$CreateCustomerRequestModel {
  const factory CreateCustomerRequestModel({
    required String name,
    String? phone,
    @JsonKey(name: 'customer_type') @Default('OTHER') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    String? notes,
  }) = _CreateCustomerRequestModel;

  factory CreateCustomerRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerRequestModelFromJson(json);
}

/// One line of a customer statement: a SALE (debit, with any amount paid at
/// the sale as credit) or a PAYMENT (credit), with the running balance after it.
@freezed
class StatementLineModel with _$StatementLineModel {
  const factory StatementLineModel({
    @Default('SALE') String kind,
    @JsonKey(name: 'reference_id') @Default('') String referenceId,
    @Default('') String date,
    @Default('') String description,
    @Default(0.0) double litres,
    @Default(0.0) double debit,
    @Default(0.0) double credit,
    @Default(0.0) double balance,
  }) = _StatementLineModel;

  factory StatementLineModel.fromJson(Map<String, dynamic> json) =>
      _$StatementLineModelFromJson(json);
}

@freezed
class CustomerStatementModel with _$CustomerStatementModel {
  const factory CustomerStatementModel({
    required CustomerModel customer,
    @JsonKey(name: 'from_date') @Default('') String fromDate,
    @JsonKey(name: 'to_date') @Default('') String toDate,
    @JsonKey(name: 'opening_balance') @Default(0.0) double openingBalance,
    @JsonKey(name: 'total_debit') @Default(0.0) double totalDebit,
    @JsonKey(name: 'total_credit') @Default(0.0) double totalCredit,
    @JsonKey(name: 'closing_balance') @Default(0.0) double closingBalance,
    @Default([]) List<StatementLineModel> lines,
  }) = _CustomerStatementModel;

  factory CustomerStatementModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerStatementModelFromJson(json);
}

@freezed
class CustomerBalanceModel with _$CustomerBalanceModel {
  const factory CustomerBalanceModel({
    @JsonKey(name: 'customer_id') required String customerId,
    required String name,
    String? phone,
    @JsonKey(name: 'customer_type') @Default('OTHER') String customerType,
    @JsonKey(name: 'total_sales') @Default(0.0) double totalSales,
    @JsonKey(name: 'total_paid') @Default(0.0) double totalPaid,
    @Default(0.0) double balance,
  }) = _CustomerBalanceModel;

  factory CustomerBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerBalanceModelFromJson(json);
}

@freezed
class RecordPaymentRequestModel with _$RecordPaymentRequestModel {
  const factory RecordPaymentRequestModel({
    required double amount,
    @JsonKey(name: 'payment_date') String? paymentDate,
    @Default('CASH') String method,
    String? reference,
    String? notes,
  }) = _RecordPaymentRequestModel;

  factory RecordPaymentRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RecordPaymentRequestModelFromJson(json);
}
