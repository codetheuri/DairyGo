// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field_ops_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MilkSaleModel _$MilkSaleModelFromJson(Map<String, dynamic> json) {
  return _MilkSaleModel.fromJson(json);
}

/// @nodoc
mixin _$MilkSaleModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  String get customerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_type')
  String? get customerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'sale_date')
  String get saleDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'buyer_name')
  String get buyerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'buyer_phone')
  String? get buyerPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price')
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_paid')
  double get amountPaid => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_status')
  String get paymentStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  @JsonKey(name: 'voided_at')
  String? get voidedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'void_reason')
  String? get voidReason => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String? get collectorName => throw _privateConstructorUsedError;

  /// Serializes this MilkSaleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilkSaleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilkSaleModelCopyWith<MilkSaleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilkSaleModelCopyWith<$Res> {
  factory $MilkSaleModelCopyWith(
    MilkSaleModel value,
    $Res Function(MilkSaleModel) then,
  ) = _$MilkSaleModelCopyWithImpl<$Res, MilkSaleModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'customer_id') String customerId,
    @JsonKey(name: 'customer_type') String? customerType,
    @JsonKey(name: 'sale_date') String saleDate,
    @JsonKey(name: 'buyer_name') String buyerName,
    @JsonKey(name: 'buyer_phone') String? buyerPhone,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'payment_status') String paymentStatus,
    @JsonKey(name: 'payment_method') String paymentMethod,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class _$MilkSaleModelCopyWithImpl<$Res, $Val extends MilkSaleModel>
    implements $MilkSaleModelCopyWith<$Res> {
  _$MilkSaleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilkSaleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? collectorId = null,
    Object? customerId = null,
    Object? customerType = freezed,
    Object? saleDate = null,
    Object? buyerName = null,
    Object? buyerPhone = freezed,
    Object? quantityLitres = null,
    Object? unitPrice = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? paymentStatus = null,
    Object? paymentMethod = null,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? collectorName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            saccoId: null == saccoId
                ? _value.saccoId
                : saccoId // ignore: cast_nullable_to_non_nullable
                      as String,
            collectorId: null == collectorId
                ? _value.collectorId
                : collectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerType: freezed == customerType
                ? _value.customerType
                : customerType // ignore: cast_nullable_to_non_nullable
                      as String?,
            saleDate: null == saleDate
                ? _value.saleDate
                : saleDate // ignore: cast_nullable_to_non_nullable
                      as String,
            buyerName: null == buyerName
                ? _value.buyerName
                : buyerName // ignore: cast_nullable_to_non_nullable
                      as String,
            buyerPhone: freezed == buyerPhone
                ? _value.buyerPhone
                : buyerPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            amountPaid: null == amountPaid
                ? _value.amountPaid
                : amountPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            voidedAt: freezed == voidedAt
                ? _value.voidedAt
                : voidedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            collectorName: freezed == collectorName
                ? _value.collectorName
                : collectorName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilkSaleModelImplCopyWith<$Res>
    implements $MilkSaleModelCopyWith<$Res> {
  factory _$$MilkSaleModelImplCopyWith(
    _$MilkSaleModelImpl value,
    $Res Function(_$MilkSaleModelImpl) then,
  ) = __$$MilkSaleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'customer_id') String customerId,
    @JsonKey(name: 'customer_type') String? customerType,
    @JsonKey(name: 'sale_date') String saleDate,
    @JsonKey(name: 'buyer_name') String buyerName,
    @JsonKey(name: 'buyer_phone') String? buyerPhone,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'payment_status') String paymentStatus,
    @JsonKey(name: 'payment_method') String paymentMethod,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class __$$MilkSaleModelImplCopyWithImpl<$Res>
    extends _$MilkSaleModelCopyWithImpl<$Res, _$MilkSaleModelImpl>
    implements _$$MilkSaleModelImplCopyWith<$Res> {
  __$$MilkSaleModelImplCopyWithImpl(
    _$MilkSaleModelImpl _value,
    $Res Function(_$MilkSaleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilkSaleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? collectorId = null,
    Object? customerId = null,
    Object? customerType = freezed,
    Object? saleDate = null,
    Object? buyerName = null,
    Object? buyerPhone = freezed,
    Object? quantityLitres = null,
    Object? unitPrice = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? paymentStatus = null,
    Object? paymentMethod = null,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? collectorName = freezed,
  }) {
    return _then(
      _$MilkSaleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        collectorId: null == collectorId
            ? _value.collectorId
            : collectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerType: freezed == customerType
            ? _value.customerType
            : customerType // ignore: cast_nullable_to_non_nullable
                  as String?,
        saleDate: null == saleDate
            ? _value.saleDate
            : saleDate // ignore: cast_nullable_to_non_nullable
                  as String,
        buyerName: null == buyerName
            ? _value.buyerName
            : buyerName // ignore: cast_nullable_to_non_nullable
                  as String,
        buyerPhone: freezed == buyerPhone
            ? _value.buyerPhone
            : buyerPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        amountPaid: null == amountPaid
            ? _value.amountPaid
            : amountPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        voidedAt: freezed == voidedAt
            ? _value.voidedAt
            : voidedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        collectorName: freezed == collectorName
            ? _value.collectorName
            : collectorName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MilkSaleModelImpl extends _MilkSaleModel {
  const _$MilkSaleModelImpl({
    required this.id,
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'customer_id') this.customerId = '',
    @JsonKey(name: 'customer_type') this.customerType,
    @JsonKey(name: 'sale_date') required this.saleDate,
    @JsonKey(name: 'buyer_name') required this.buyerName,
    @JsonKey(name: 'buyer_phone') this.buyerPhone,
    @JsonKey(name: 'quantity_litres') this.quantityLitres = 0.0,
    @JsonKey(name: 'unit_price') this.unitPrice = 0.0,
    @JsonKey(name: 'total_amount') this.totalAmount = 0.0,
    @JsonKey(name: 'amount_paid') this.amountPaid = 0.0,
    @JsonKey(name: 'payment_status') this.paymentStatus = 'PAID',
    @JsonKey(name: 'payment_method') this.paymentMethod = 'CASH',
    @JsonKey(name: 'voided_at') this.voidedAt,
    @JsonKey(name: 'void_reason') this.voidReason,
    this.notes,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'collector_name') this.collectorName,
  }) : super._();

  factory _$MilkSaleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilkSaleModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'collector_id')
  final int collectorId;
  @override
  @JsonKey(name: 'customer_id')
  final String customerId;
  @override
  @JsonKey(name: 'customer_type')
  final String? customerType;
  @override
  @JsonKey(name: 'sale_date')
  final String saleDate;
  @override
  @JsonKey(name: 'buyer_name')
  final String buyerName;
  @override
  @JsonKey(name: 'buyer_phone')
  final String? buyerPhone;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey(name: 'amount_paid')
  final double amountPaid;
  @override
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @override
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  @JsonKey(name: 'voided_at')
  final String? voidedAt;
  @override
  @JsonKey(name: 'void_reason')
  final String? voidReason;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'collector_name')
  final String? collectorName;

  @override
  String toString() {
    return 'MilkSaleModel(id: $id, saccoId: $saccoId, collectorId: $collectorId, customerId: $customerId, customerType: $customerType, saleDate: $saleDate, buyerName: $buyerName, buyerPhone: $buyerPhone, quantityLitres: $quantityLitres, unitPrice: $unitPrice, totalAmount: $totalAmount, amountPaid: $amountPaid, paymentStatus: $paymentStatus, paymentMethod: $paymentMethod, voidedAt: $voidedAt, voidReason: $voidReason, notes: $notes, createdAt: $createdAt, collectorName: $collectorName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilkSaleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerType, customerType) ||
                other.customerType == customerType) &&
            (identical(other.saleDate, saleDate) ||
                other.saleDate == saleDate) &&
            (identical(other.buyerName, buyerName) ||
                other.buyerName == buyerName) &&
            (identical(other.buyerPhone, buyerPhone) ||
                other.buyerPhone == buyerPhone) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.voidedAt, voidedAt) ||
                other.voidedAt == voidedAt) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    saccoId,
    collectorId,
    customerId,
    customerType,
    saleDate,
    buyerName,
    buyerPhone,
    quantityLitres,
    unitPrice,
    totalAmount,
    amountPaid,
    paymentStatus,
    paymentMethod,
    voidedAt,
    voidReason,
    notes,
    createdAt,
    collectorName,
  ]);

  /// Create a copy of MilkSaleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilkSaleModelImplCopyWith<_$MilkSaleModelImpl> get copyWith =>
      __$$MilkSaleModelImplCopyWithImpl<_$MilkSaleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MilkSaleModelImplToJson(this);
  }
}

abstract class _MilkSaleModel extends MilkSaleModel {
  const factory _MilkSaleModel({
    required final String id,
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'customer_id') final String customerId,
    @JsonKey(name: 'customer_type') final String? customerType,
    @JsonKey(name: 'sale_date') required final String saleDate,
    @JsonKey(name: 'buyer_name') required final String buyerName,
    @JsonKey(name: 'buyer_phone') final String? buyerPhone,
    @JsonKey(name: 'quantity_litres') final double quantityLitres,
    @JsonKey(name: 'unit_price') final double unitPrice,
    @JsonKey(name: 'total_amount') final double totalAmount,
    @JsonKey(name: 'amount_paid') final double amountPaid,
    @JsonKey(name: 'payment_status') final String paymentStatus,
    @JsonKey(name: 'payment_method') final String paymentMethod,
    @JsonKey(name: 'voided_at') final String? voidedAt,
    @JsonKey(name: 'void_reason') final String? voidReason,
    final String? notes,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'collector_name') final String? collectorName,
  }) = _$MilkSaleModelImpl;
  const _MilkSaleModel._() : super._();

  factory _MilkSaleModel.fromJson(Map<String, dynamic> json) =
      _$MilkSaleModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'customer_id')
  String get customerId;
  @override
  @JsonKey(name: 'customer_type')
  String? get customerType;
  @override
  @JsonKey(name: 'sale_date')
  String get saleDate;
  @override
  @JsonKey(name: 'buyer_name')
  String get buyerName;
  @override
  @JsonKey(name: 'buyer_phone')
  String? get buyerPhone;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  @JsonKey(name: 'unit_price')
  double get unitPrice;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  @JsonKey(name: 'amount_paid')
  double get amountPaid;
  @override
  @JsonKey(name: 'payment_status')
  String get paymentStatus;
  @override
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  @JsonKey(name: 'voided_at')
  String? get voidedAt;
  @override
  @JsonKey(name: 'void_reason')
  String? get voidReason;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'collector_name')
  String? get collectorName;

  /// Create a copy of MilkSaleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilkSaleModelImplCopyWith<_$MilkSaleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecordSaleRequestModel _$RecordSaleRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _RecordSaleRequestModel.fromJson(json);
}

/// @nodoc
mixin _$RecordSaleRequestModel {
  @JsonKey(name: 'customer_id')
  String get customerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sale_date')
  String? get saleDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price')
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_paid')
  double get amountPaid => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this RecordSaleRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordSaleRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordSaleRequestModelCopyWith<RecordSaleRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordSaleRequestModelCopyWith<$Res> {
  factory $RecordSaleRequestModelCopyWith(
    RecordSaleRequestModel value,
    $Res Function(RecordSaleRequestModel) then,
  ) = _$RecordSaleRequestModelCopyWithImpl<$Res, RecordSaleRequestModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'customer_id') String customerId,
    @JsonKey(name: 'sale_date') String? saleDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'payment_method') String paymentMethod,
    String? notes,
  });
}

/// @nodoc
class _$RecordSaleRequestModelCopyWithImpl<
  $Res,
  $Val extends RecordSaleRequestModel
>
    implements $RecordSaleRequestModelCopyWith<$Res> {
  _$RecordSaleRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordSaleRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? saleDate = freezed,
    Object? quantityLitres = null,
    Object? unitPrice = null,
    Object? amountPaid = null,
    Object? paymentMethod = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            saleDate: freezed == saleDate
                ? _value.saleDate
                : saleDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            amountPaid: null == amountPaid
                ? _value.amountPaid
                : amountPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecordSaleRequestModelImplCopyWith<$Res>
    implements $RecordSaleRequestModelCopyWith<$Res> {
  factory _$$RecordSaleRequestModelImplCopyWith(
    _$RecordSaleRequestModelImpl value,
    $Res Function(_$RecordSaleRequestModelImpl) then,
  ) = __$$RecordSaleRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'customer_id') String customerId,
    @JsonKey(name: 'sale_date') String? saleDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'amount_paid') double amountPaid,
    @JsonKey(name: 'payment_method') String paymentMethod,
    String? notes,
  });
}

/// @nodoc
class __$$RecordSaleRequestModelImplCopyWithImpl<$Res>
    extends
        _$RecordSaleRequestModelCopyWithImpl<$Res, _$RecordSaleRequestModelImpl>
    implements _$$RecordSaleRequestModelImplCopyWith<$Res> {
  __$$RecordSaleRequestModelImplCopyWithImpl(
    _$RecordSaleRequestModelImpl _value,
    $Res Function(_$RecordSaleRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordSaleRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? saleDate = freezed,
    Object? quantityLitres = null,
    Object? unitPrice = null,
    Object? amountPaid = null,
    Object? paymentMethod = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$RecordSaleRequestModelImpl(
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        saleDate: freezed == saleDate
            ? _value.saleDate
            : saleDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        amountPaid: null == amountPaid
            ? _value.amountPaid
            : amountPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordSaleRequestModelImpl implements _RecordSaleRequestModel {
  const _$RecordSaleRequestModelImpl({
    @JsonKey(name: 'customer_id') required this.customerId,
    @JsonKey(name: 'sale_date') this.saleDate,
    @JsonKey(name: 'quantity_litres') required this.quantityLitres,
    @JsonKey(name: 'unit_price') required this.unitPrice,
    @JsonKey(name: 'amount_paid') required this.amountPaid,
    @JsonKey(name: 'payment_method') this.paymentMethod = 'CASH',
    this.notes,
  });

  factory _$RecordSaleRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordSaleRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'customer_id')
  final String customerId;
  @override
  @JsonKey(name: 'sale_date')
  final String? saleDate;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @override
  @JsonKey(name: 'amount_paid')
  final double amountPaid;
  @override
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  final String? notes;

  @override
  String toString() {
    return 'RecordSaleRequestModel(customerId: $customerId, saleDate: $saleDate, quantityLitres: $quantityLitres, unitPrice: $unitPrice, amountPaid: $amountPaid, paymentMethod: $paymentMethod, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordSaleRequestModelImpl &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.saleDate, saleDate) ||
                other.saleDate == saleDate) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    customerId,
    saleDate,
    quantityLitres,
    unitPrice,
    amountPaid,
    paymentMethod,
    notes,
  );

  /// Create a copy of RecordSaleRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordSaleRequestModelImplCopyWith<_$RecordSaleRequestModelImpl>
  get copyWith =>
      __$$RecordSaleRequestModelImplCopyWithImpl<_$RecordSaleRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordSaleRequestModelImplToJson(this);
  }
}

abstract class _RecordSaleRequestModel implements RecordSaleRequestModel {
  const factory _RecordSaleRequestModel({
    @JsonKey(name: 'customer_id') required final String customerId,
    @JsonKey(name: 'sale_date') final String? saleDate,
    @JsonKey(name: 'quantity_litres') required final double quantityLitres,
    @JsonKey(name: 'unit_price') required final double unitPrice,
    @JsonKey(name: 'amount_paid') required final double amountPaid,
    @JsonKey(name: 'payment_method') final String paymentMethod,
    final String? notes,
  }) = _$RecordSaleRequestModelImpl;

  factory _RecordSaleRequestModel.fromJson(Map<String, dynamic> json) =
      _$RecordSaleRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'customer_id')
  String get customerId;
  @override
  @JsonKey(name: 'sale_date')
  String? get saleDate;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  @JsonKey(name: 'unit_price')
  double get unitPrice;
  @override
  @JsonKey(name: 'amount_paid')
  double get amountPaid;
  @override
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  String? get notes;

  /// Create a copy of RecordSaleRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordSaleRequestModelImplCopyWith<_$RecordSaleRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MilkSpoilageModel _$MilkSpoilageModelFromJson(Map<String, dynamic> json) {
  return _MilkSpoilageModel.fromJson(json);
}

/// @nodoc
mixin _$MilkSpoilageModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'spoilage_date')
  String get spoilageDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String? get collectorName => throw _privateConstructorUsedError;

  /// Serializes this MilkSpoilageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilkSpoilageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilkSpoilageModelCopyWith<MilkSpoilageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilkSpoilageModelCopyWith<$Res> {
  factory $MilkSpoilageModelCopyWith(
    MilkSpoilageModel value,
    $Res Function(MilkSpoilageModel) then,
  ) = _$MilkSpoilageModelCopyWithImpl<$Res, MilkSpoilageModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'spoilage_date') String spoilageDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String reason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class _$MilkSpoilageModelCopyWithImpl<$Res, $Val extends MilkSpoilageModel>
    implements $MilkSpoilageModelCopyWith<$Res> {
  _$MilkSpoilageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilkSpoilageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? collectorId = null,
    Object? spoilageDate = null,
    Object? quantityLitres = null,
    Object? reason = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? collectorName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            saccoId: null == saccoId
                ? _value.saccoId
                : saccoId // ignore: cast_nullable_to_non_nullable
                      as String,
            collectorId: null == collectorId
                ? _value.collectorId
                : collectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            spoilageDate: null == spoilageDate
                ? _value.spoilageDate
                : spoilageDate // ignore: cast_nullable_to_non_nullable
                      as String,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            collectorName: freezed == collectorName
                ? _value.collectorName
                : collectorName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilkSpoilageModelImplCopyWith<$Res>
    implements $MilkSpoilageModelCopyWith<$Res> {
  factory _$$MilkSpoilageModelImplCopyWith(
    _$MilkSpoilageModelImpl value,
    $Res Function(_$MilkSpoilageModelImpl) then,
  ) = __$$MilkSpoilageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'spoilage_date') String spoilageDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String reason,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class __$$MilkSpoilageModelImplCopyWithImpl<$Res>
    extends _$MilkSpoilageModelCopyWithImpl<$Res, _$MilkSpoilageModelImpl>
    implements _$$MilkSpoilageModelImplCopyWith<$Res> {
  __$$MilkSpoilageModelImplCopyWithImpl(
    _$MilkSpoilageModelImpl _value,
    $Res Function(_$MilkSpoilageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilkSpoilageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? collectorId = null,
    Object? spoilageDate = null,
    Object? quantityLitres = null,
    Object? reason = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? collectorName = freezed,
  }) {
    return _then(
      _$MilkSpoilageModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        collectorId: null == collectorId
            ? _value.collectorId
            : collectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        spoilageDate: null == spoilageDate
            ? _value.spoilageDate
            : spoilageDate // ignore: cast_nullable_to_non_nullable
                  as String,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        collectorName: freezed == collectorName
            ? _value.collectorName
            : collectorName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MilkSpoilageModelImpl implements _MilkSpoilageModel {
  const _$MilkSpoilageModelImpl({
    required this.id,
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'spoilage_date') required this.spoilageDate,
    @JsonKey(name: 'quantity_litres') this.quantityLitres = 0.0,
    required this.reason,
    this.notes,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'collector_name') this.collectorName,
  });

  factory _$MilkSpoilageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilkSpoilageModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'collector_id')
  final int collectorId;
  @override
  @JsonKey(name: 'spoilage_date')
  final String spoilageDate;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  final String reason;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'collector_name')
  final String? collectorName;

  @override
  String toString() {
    return 'MilkSpoilageModel(id: $id, saccoId: $saccoId, collectorId: $collectorId, spoilageDate: $spoilageDate, quantityLitres: $quantityLitres, reason: $reason, notes: $notes, createdAt: $createdAt, collectorName: $collectorName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilkSpoilageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.spoilageDate, spoilageDate) ||
                other.spoilageDate == spoilageDate) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    saccoId,
    collectorId,
    spoilageDate,
    quantityLitres,
    reason,
    notes,
    createdAt,
    collectorName,
  );

  /// Create a copy of MilkSpoilageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilkSpoilageModelImplCopyWith<_$MilkSpoilageModelImpl> get copyWith =>
      __$$MilkSpoilageModelImplCopyWithImpl<_$MilkSpoilageModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MilkSpoilageModelImplToJson(this);
  }
}

abstract class _MilkSpoilageModel implements MilkSpoilageModel {
  const factory _MilkSpoilageModel({
    required final String id,
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'spoilage_date') required final String spoilageDate,
    @JsonKey(name: 'quantity_litres') final double quantityLitres,
    required final String reason,
    final String? notes,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'collector_name') final String? collectorName,
  }) = _$MilkSpoilageModelImpl;

  factory _MilkSpoilageModel.fromJson(Map<String, dynamic> json) =
      _$MilkSpoilageModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'spoilage_date')
  String get spoilageDate;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  String get reason;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'collector_name')
  String? get collectorName;

  /// Create a copy of MilkSpoilageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilkSpoilageModelImplCopyWith<_$MilkSpoilageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecordSpoilageRequestModel _$RecordSpoilageRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _RecordSpoilageRequestModel.fromJson(json);
}

/// @nodoc
mixin _$RecordSpoilageRequestModel {
  @JsonKey(name: 'spoilage_date')
  String get spoilageDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this RecordSpoilageRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordSpoilageRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordSpoilageRequestModelCopyWith<RecordSpoilageRequestModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordSpoilageRequestModelCopyWith<$Res> {
  factory $RecordSpoilageRequestModelCopyWith(
    RecordSpoilageRequestModel value,
    $Res Function(RecordSpoilageRequestModel) then,
  ) =
      _$RecordSpoilageRequestModelCopyWithImpl<
        $Res,
        RecordSpoilageRequestModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'spoilage_date') String spoilageDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String reason,
    String? notes,
  });
}

/// @nodoc
class _$RecordSpoilageRequestModelCopyWithImpl<
  $Res,
  $Val extends RecordSpoilageRequestModel
>
    implements $RecordSpoilageRequestModelCopyWith<$Res> {
  _$RecordSpoilageRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordSpoilageRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spoilageDate = null,
    Object? quantityLitres = null,
    Object? reason = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            spoilageDate: null == spoilageDate
                ? _value.spoilageDate
                : spoilageDate // ignore: cast_nullable_to_non_nullable
                      as String,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecordSpoilageRequestModelImplCopyWith<$Res>
    implements $RecordSpoilageRequestModelCopyWith<$Res> {
  factory _$$RecordSpoilageRequestModelImplCopyWith(
    _$RecordSpoilageRequestModelImpl value,
    $Res Function(_$RecordSpoilageRequestModelImpl) then,
  ) = __$$RecordSpoilageRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'spoilage_date') String spoilageDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String reason,
    String? notes,
  });
}

/// @nodoc
class __$$RecordSpoilageRequestModelImplCopyWithImpl<$Res>
    extends
        _$RecordSpoilageRequestModelCopyWithImpl<
          $Res,
          _$RecordSpoilageRequestModelImpl
        >
    implements _$$RecordSpoilageRequestModelImplCopyWith<$Res> {
  __$$RecordSpoilageRequestModelImplCopyWithImpl(
    _$RecordSpoilageRequestModelImpl _value,
    $Res Function(_$RecordSpoilageRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordSpoilageRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spoilageDate = null,
    Object? quantityLitres = null,
    Object? reason = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$RecordSpoilageRequestModelImpl(
        spoilageDate: null == spoilageDate
            ? _value.spoilageDate
            : spoilageDate // ignore: cast_nullable_to_non_nullable
                  as String,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordSpoilageRequestModelImpl implements _RecordSpoilageRequestModel {
  const _$RecordSpoilageRequestModelImpl({
    @JsonKey(name: 'spoilage_date') required this.spoilageDate,
    @JsonKey(name: 'quantity_litres') required this.quantityLitres,
    required this.reason,
    this.notes,
  });

  factory _$RecordSpoilageRequestModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RecordSpoilageRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'spoilage_date')
  final String spoilageDate;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  final String reason;
  @override
  final String? notes;

  @override
  String toString() {
    return 'RecordSpoilageRequestModel(spoilageDate: $spoilageDate, quantityLitres: $quantityLitres, reason: $reason, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordSpoilageRequestModelImpl &&
            (identical(other.spoilageDate, spoilageDate) ||
                other.spoilageDate == spoilageDate) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, spoilageDate, quantityLitres, reason, notes);

  /// Create a copy of RecordSpoilageRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordSpoilageRequestModelImplCopyWith<_$RecordSpoilageRequestModelImpl>
  get copyWith =>
      __$$RecordSpoilageRequestModelImplCopyWithImpl<
        _$RecordSpoilageRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordSpoilageRequestModelImplToJson(this);
  }
}

abstract class _RecordSpoilageRequestModel
    implements RecordSpoilageRequestModel {
  const factory _RecordSpoilageRequestModel({
    @JsonKey(name: 'spoilage_date') required final String spoilageDate,
    @JsonKey(name: 'quantity_litres') required final double quantityLitres,
    required final String reason,
    final String? notes,
  }) = _$RecordSpoilageRequestModelImpl;

  factory _RecordSpoilageRequestModel.fromJson(Map<String, dynamic> json) =
      _$RecordSpoilageRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'spoilage_date')
  String get spoilageDate;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  String get reason;
  @override
  String? get notes;

  /// Create a copy of RecordSpoilageRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordSpoilageRequestModelImplCopyWith<_$RecordSpoilageRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ReconciliationModel _$ReconciliationModelFromJson(Map<String, dynamic> json) {
  return _ReconciliationModel.fromJson(json);
}

/// @nodoc
mixin _$ReconciliationModel {
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String get collectorName => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_collected_litres')
  double get totalCollectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_spoiled_litres')
  double get totalSpoiledLitres => throw _privateConstructorUsedError; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'balance_status')
  String get balanceStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sales_amount')
  double get totalSalesAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'cash_received_amount')
  double get cashReceivedAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_sales_amount')
  double get creditSalesAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'total_purchases_amount')
  double get totalPurchasesAmount => throw _privateConstructorUsedError;

  /// Serializes this ReconciliationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReconciliationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReconciliationModelCopyWith<ReconciliationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReconciliationModelCopyWith<$Res> {
  factory $ReconciliationModelCopyWith(
    ReconciliationModel value,
    $Res Function(ReconciliationModel) then,
  ) = _$ReconciliationModelCopyWithImpl<$Res, ReconciliationModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    String date,
    @JsonKey(name: 'total_collected_litres') double totalCollectedLitres,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_spoiled_litres') double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'total_sales_amount') double totalSalesAmount,
    @JsonKey(name: 'cash_received_amount') double cashReceivedAmount,
    @JsonKey(name: 'credit_sales_amount') double creditSalesAmount,
    @JsonKey(name: 'sales_by_customer_type')
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'total_purchases_amount') double totalPurchasesAmount,
  });
}

/// @nodoc
class _$ReconciliationModelCopyWithImpl<$Res, $Val extends ReconciliationModel>
    implements $ReconciliationModelCopyWith<$Res> {
  _$ReconciliationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReconciliationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? date = null,
    Object? totalCollectedLitres = null,
    Object? totalSoldLitres = null,
    Object? totalSpoiledLitres = null,
    Object? unaccountedLitres = null,
    Object? balanceStatus = null,
    Object? totalSalesAmount = null,
    Object? cashReceivedAmount = null,
    Object? creditSalesAmount = null,
    Object? salesByCustomerType = null,
    Object? totalPurchasesAmount = null,
  }) {
    return _then(
      _value.copyWith(
            collectorId: null == collectorId
                ? _value.collectorId
                : collectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            collectorName: null == collectorName
                ? _value.collectorName
                : collectorName // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            totalCollectedLitres: null == totalCollectedLitres
                ? _value.totalCollectedLitres
                : totalCollectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSoldLitres: null == totalSoldLitres
                ? _value.totalSoldLitres
                : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSpoiledLitres: null == totalSpoiledLitres
                ? _value.totalSpoiledLitres
                : totalSpoiledLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            unaccountedLitres: null == unaccountedLitres
                ? _value.unaccountedLitres
                : unaccountedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            balanceStatus: null == balanceStatus
                ? _value.balanceStatus
                : balanceStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            totalSalesAmount: null == totalSalesAmount
                ? _value.totalSalesAmount
                : totalSalesAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            cashReceivedAmount: null == cashReceivedAmount
                ? _value.cashReceivedAmount
                : cashReceivedAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            creditSalesAmount: null == creditSalesAmount
                ? _value.creditSalesAmount
                : creditSalesAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            salesByCustomerType: null == salesByCustomerType
                ? _value.salesByCustomerType
                : salesByCustomerType // ignore: cast_nullable_to_non_nullable
                      as List<CustomerTypeTotalModel>,
            totalPurchasesAmount: null == totalPurchasesAmount
                ? _value.totalPurchasesAmount
                : totalPurchasesAmount // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReconciliationModelImplCopyWith<$Res>
    implements $ReconciliationModelCopyWith<$Res> {
  factory _$$ReconciliationModelImplCopyWith(
    _$ReconciliationModelImpl value,
    $Res Function(_$ReconciliationModelImpl) then,
  ) = __$$ReconciliationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    String date,
    @JsonKey(name: 'total_collected_litres') double totalCollectedLitres,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_spoiled_litres') double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'total_sales_amount') double totalSalesAmount,
    @JsonKey(name: 'cash_received_amount') double cashReceivedAmount,
    @JsonKey(name: 'credit_sales_amount') double creditSalesAmount,
    @JsonKey(name: 'sales_by_customer_type')
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'total_purchases_amount') double totalPurchasesAmount,
  });
}

/// @nodoc
class __$$ReconciliationModelImplCopyWithImpl<$Res>
    extends _$ReconciliationModelCopyWithImpl<$Res, _$ReconciliationModelImpl>
    implements _$$ReconciliationModelImplCopyWith<$Res> {
  __$$ReconciliationModelImplCopyWithImpl(
    _$ReconciliationModelImpl _value,
    $Res Function(_$ReconciliationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReconciliationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? date = null,
    Object? totalCollectedLitres = null,
    Object? totalSoldLitres = null,
    Object? totalSpoiledLitres = null,
    Object? unaccountedLitres = null,
    Object? balanceStatus = null,
    Object? totalSalesAmount = null,
    Object? cashReceivedAmount = null,
    Object? creditSalesAmount = null,
    Object? salesByCustomerType = null,
    Object? totalPurchasesAmount = null,
  }) {
    return _then(
      _$ReconciliationModelImpl(
        collectorId: null == collectorId
            ? _value.collectorId
            : collectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        collectorName: null == collectorName
            ? _value.collectorName
            : collectorName // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        totalCollectedLitres: null == totalCollectedLitres
            ? _value.totalCollectedLitres
            : totalCollectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSoldLitres: null == totalSoldLitres
            ? _value.totalSoldLitres
            : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSpoiledLitres: null == totalSpoiledLitres
            ? _value.totalSpoiledLitres
            : totalSpoiledLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        unaccountedLitres: null == unaccountedLitres
            ? _value.unaccountedLitres
            : unaccountedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        balanceStatus: null == balanceStatus
            ? _value.balanceStatus
            : balanceStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSalesAmount: null == totalSalesAmount
            ? _value.totalSalesAmount
            : totalSalesAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        cashReceivedAmount: null == cashReceivedAmount
            ? _value.cashReceivedAmount
            : cashReceivedAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        creditSalesAmount: null == creditSalesAmount
            ? _value.creditSalesAmount
            : creditSalesAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        salesByCustomerType: null == salesByCustomerType
            ? _value._salesByCustomerType
            : salesByCustomerType // ignore: cast_nullable_to_non_nullable
                  as List<CustomerTypeTotalModel>,
        totalPurchasesAmount: null == totalPurchasesAmount
            ? _value.totalPurchasesAmount
            : totalPurchasesAmount // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReconciliationModelImpl implements _ReconciliationModel {
  const _$ReconciliationModelImpl({
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'collector_name') this.collectorName = '',
    this.date = '',
    @JsonKey(name: 'total_collected_litres') this.totalCollectedLitres = 0.0,
    @JsonKey(name: 'total_sold_litres') this.totalSoldLitres = 0.0,
    @JsonKey(name: 'total_spoiled_litres') this.totalSpoiledLitres = 0.0,
    @JsonKey(name: 'unaccounted_litres') this.unaccountedLitres = 0.0,
    @JsonKey(name: 'balance_status') this.balanceStatus = 'BALANCED',
    @JsonKey(name: 'total_sales_amount') this.totalSalesAmount = 0.0,
    @JsonKey(name: 'cash_received_amount') this.cashReceivedAmount = 0.0,
    @JsonKey(name: 'credit_sales_amount') this.creditSalesAmount = 0.0,
    @JsonKey(name: 'sales_by_customer_type')
    final List<CustomerTypeTotalModel> salesByCustomerType = const [],
    @JsonKey(name: 'total_purchases_amount') this.totalPurchasesAmount = 0.0,
  }) : _salesByCustomerType = salesByCustomerType;

  factory _$ReconciliationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReconciliationModelImplFromJson(json);

  @override
  @JsonKey(name: 'collector_id')
  final int collectorId;
  @override
  @JsonKey(name: 'collector_name')
  final String collectorName;
  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey(name: 'total_collected_litres')
  final double totalCollectedLitres;
  @override
  @JsonKey(name: 'total_sold_litres')
  final double totalSoldLitres;
  @override
  @JsonKey(name: 'total_spoiled_litres')
  final double totalSpoiledLitres;
  // collected - sold - spoiled; > 0 missing, < 0 oversold
  @override
  @JsonKey(name: 'unaccounted_litres')
  final double unaccountedLitres;
  @override
  @JsonKey(name: 'balance_status')
  final String balanceStatus;
  @override
  @JsonKey(name: 'total_sales_amount')
  final double totalSalesAmount;
  @override
  @JsonKey(name: 'cash_received_amount')
  final double cashReceivedAmount;
  @override
  @JsonKey(name: 'credit_sales_amount')
  final double creditSalesAmount;
  final List<CustomerTypeTotalModel> _salesByCustomerType;
  @override
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType {
    if (_salesByCustomerType is EqualUnmodifiableListView)
      return _salesByCustomerType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_salesByCustomerType);
  }

  @override
  @JsonKey(name: 'total_purchases_amount')
  final double totalPurchasesAmount;

  @override
  String toString() {
    return 'ReconciliationModel(collectorId: $collectorId, collectorName: $collectorName, date: $date, totalCollectedLitres: $totalCollectedLitres, totalSoldLitres: $totalSoldLitres, totalSpoiledLitres: $totalSpoiledLitres, unaccountedLitres: $unaccountedLitres, balanceStatus: $balanceStatus, totalSalesAmount: $totalSalesAmount, cashReceivedAmount: $cashReceivedAmount, creditSalesAmount: $creditSalesAmount, salesByCustomerType: $salesByCustomerType, totalPurchasesAmount: $totalPurchasesAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReconciliationModelImpl &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalCollectedLitres, totalCollectedLitres) ||
                other.totalCollectedLitres == totalCollectedLitres) &&
            (identical(other.totalSoldLitres, totalSoldLitres) ||
                other.totalSoldLitres == totalSoldLitres) &&
            (identical(other.totalSpoiledLitres, totalSpoiledLitres) ||
                other.totalSpoiledLitres == totalSpoiledLitres) &&
            (identical(other.unaccountedLitres, unaccountedLitres) ||
                other.unaccountedLitres == unaccountedLitres) &&
            (identical(other.balanceStatus, balanceStatus) ||
                other.balanceStatus == balanceStatus) &&
            (identical(other.totalSalesAmount, totalSalesAmount) ||
                other.totalSalesAmount == totalSalesAmount) &&
            (identical(other.cashReceivedAmount, cashReceivedAmount) ||
                other.cashReceivedAmount == cashReceivedAmount) &&
            (identical(other.creditSalesAmount, creditSalesAmount) ||
                other.creditSalesAmount == creditSalesAmount) &&
            const DeepCollectionEquality().equals(
              other._salesByCustomerType,
              _salesByCustomerType,
            ) &&
            (identical(other.totalPurchasesAmount, totalPurchasesAmount) ||
                other.totalPurchasesAmount == totalPurchasesAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    collectorId,
    collectorName,
    date,
    totalCollectedLitres,
    totalSoldLitres,
    totalSpoiledLitres,
    unaccountedLitres,
    balanceStatus,
    totalSalesAmount,
    cashReceivedAmount,
    creditSalesAmount,
    const DeepCollectionEquality().hash(_salesByCustomerType),
    totalPurchasesAmount,
  );

  /// Create a copy of ReconciliationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReconciliationModelImplCopyWith<_$ReconciliationModelImpl> get copyWith =>
      __$$ReconciliationModelImplCopyWithImpl<_$ReconciliationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReconciliationModelImplToJson(this);
  }
}

abstract class _ReconciliationModel implements ReconciliationModel {
  const factory _ReconciliationModel({
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'collector_name') final String collectorName,
    final String date,
    @JsonKey(name: 'total_collected_litres') final double totalCollectedLitres,
    @JsonKey(name: 'total_sold_litres') final double totalSoldLitres,
    @JsonKey(name: 'total_spoiled_litres') final double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') final double unaccountedLitres,
    @JsonKey(name: 'balance_status') final String balanceStatus,
    @JsonKey(name: 'total_sales_amount') final double totalSalesAmount,
    @JsonKey(name: 'cash_received_amount') final double cashReceivedAmount,
    @JsonKey(name: 'credit_sales_amount') final double creditSalesAmount,
    @JsonKey(name: 'sales_by_customer_type')
    final List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'total_purchases_amount') final double totalPurchasesAmount,
  }) = _$ReconciliationModelImpl;

  factory _ReconciliationModel.fromJson(Map<String, dynamic> json) =
      _$ReconciliationModelImpl.fromJson;

  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'collector_name')
  String get collectorName;
  @override
  String get date;
  @override
  @JsonKey(name: 'total_collected_litres')
  double get totalCollectedLitres;
  @override
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres;
  @override
  @JsonKey(name: 'total_spoiled_litres')
  double get totalSpoiledLitres; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @override
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres;
  @override
  @JsonKey(name: 'balance_status')
  String get balanceStatus;
  @override
  @JsonKey(name: 'total_sales_amount')
  double get totalSalesAmount;
  @override
  @JsonKey(name: 'cash_received_amount')
  double get cashReceivedAmount;
  @override
  @JsonKey(name: 'credit_sales_amount')
  double get creditSalesAmount;
  @override
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType;
  @override
  @JsonKey(name: 'total_purchases_amount')
  double get totalPurchasesAmount;

  /// Create a copy of ReconciliationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReconciliationModelImplCopyWith<_$ReconciliationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
