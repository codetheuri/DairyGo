// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FarmerPayoutStatementModel _$FarmerPayoutStatementModelFromJson(
  Map<String, dynamic> json,
) {
  return _FarmerPayoutStatementModel.fromJson(json);
}

/// @nodoc
mixin _$FarmerPayoutStatementModel {
  @JsonKey(name: 'member_id')
  String get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'membership_number')
  String get membershipNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'farmer_name')
  String get farmerName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'bank_account_number')
  String? get bankAccountNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'bank_name')
  String? get bankName => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_litres')
  double get totalLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'average_price_per_litre')
  double get averagePricePerLitre => throw _privateConstructorUsedError;
  @JsonKey(name: 'gross_amount_owed')
  double get grossAmountOwed => throw _privateConstructorUsedError;
  @JsonKey(name: 'collections_count')
  int get collectionsCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_date')
  String? get fromDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_date')
  String? get toDate => throw _privateConstructorUsedError;

  /// Serializes this FarmerPayoutStatementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FarmerPayoutStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FarmerPayoutStatementModelCopyWith<FarmerPayoutStatementModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FarmerPayoutStatementModelCopyWith<$Res> {
  factory $FarmerPayoutStatementModelCopyWith(
    FarmerPayoutStatementModel value,
    $Res Function(FarmerPayoutStatementModel) then,
  ) =
      _$FarmerPayoutStatementModelCopyWithImpl<
        $Res,
        FarmerPayoutStatementModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'membership_number') String membershipNumber,
    @JsonKey(name: 'farmer_name') String farmerName,
    String phone,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'total_litres') double totalLitres,
    @JsonKey(name: 'average_price_per_litre') double averagePricePerLitre,
    @JsonKey(name: 'gross_amount_owed') double grossAmountOwed,
    @JsonKey(name: 'collections_count') int collectionsCount,
    @JsonKey(name: 'from_date') String? fromDate,
    @JsonKey(name: 'to_date') String? toDate,
  });
}

/// @nodoc
class _$FarmerPayoutStatementModelCopyWithImpl<
  $Res,
  $Val extends FarmerPayoutStatementModel
>
    implements $FarmerPayoutStatementModelCopyWith<$Res> {
  _$FarmerPayoutStatementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FarmerPayoutStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? membershipNumber = null,
    Object? farmerName = null,
    Object? phone = null,
    Object? mpesaNumber = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankName = freezed,
    Object? totalLitres = null,
    Object? averagePricePerLitre = null,
    Object? grossAmountOwed = null,
    Object? collectionsCount = null,
    Object? fromDate = freezed,
    Object? toDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            memberId: null == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String,
            membershipNumber: null == membershipNumber
                ? _value.membershipNumber
                : membershipNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            farmerName: null == farmerName
                ? _value.farmerName
                : farmerName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            mpesaNumber: freezed == mpesaNumber
                ? _value.mpesaNumber
                : mpesaNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankAccountNumber: freezed == bankAccountNumber
                ? _value.bankAccountNumber
                : bankAccountNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankName: freezed == bankName
                ? _value.bankName
                : bankName // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalLitres: null == totalLitres
                ? _value.totalLitres
                : totalLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            averagePricePerLitre: null == averagePricePerLitre
                ? _value.averagePricePerLitre
                : averagePricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double,
            grossAmountOwed: null == grossAmountOwed
                ? _value.grossAmountOwed
                : grossAmountOwed // ignore: cast_nullable_to_non_nullable
                      as double,
            collectionsCount: null == collectionsCount
                ? _value.collectionsCount
                : collectionsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            fromDate: freezed == fromDate
                ? _value.fromDate
                : fromDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            toDate: freezed == toDate
                ? _value.toDate
                : toDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FarmerPayoutStatementModelImplCopyWith<$Res>
    implements $FarmerPayoutStatementModelCopyWith<$Res> {
  factory _$$FarmerPayoutStatementModelImplCopyWith(
    _$FarmerPayoutStatementModelImpl value,
    $Res Function(_$FarmerPayoutStatementModelImpl) then,
  ) = __$$FarmerPayoutStatementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'membership_number') String membershipNumber,
    @JsonKey(name: 'farmer_name') String farmerName,
    String phone,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'total_litres') double totalLitres,
    @JsonKey(name: 'average_price_per_litre') double averagePricePerLitre,
    @JsonKey(name: 'gross_amount_owed') double grossAmountOwed,
    @JsonKey(name: 'collections_count') int collectionsCount,
    @JsonKey(name: 'from_date') String? fromDate,
    @JsonKey(name: 'to_date') String? toDate,
  });
}

/// @nodoc
class __$$FarmerPayoutStatementModelImplCopyWithImpl<$Res>
    extends
        _$FarmerPayoutStatementModelCopyWithImpl<
          $Res,
          _$FarmerPayoutStatementModelImpl
        >
    implements _$$FarmerPayoutStatementModelImplCopyWith<$Res> {
  __$$FarmerPayoutStatementModelImplCopyWithImpl(
    _$FarmerPayoutStatementModelImpl _value,
    $Res Function(_$FarmerPayoutStatementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FarmerPayoutStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? membershipNumber = null,
    Object? farmerName = null,
    Object? phone = null,
    Object? mpesaNumber = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankName = freezed,
    Object? totalLitres = null,
    Object? averagePricePerLitre = null,
    Object? grossAmountOwed = null,
    Object? collectionsCount = null,
    Object? fromDate = freezed,
    Object? toDate = freezed,
  }) {
    return _then(
      _$FarmerPayoutStatementModelImpl(
        memberId: null == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String,
        membershipNumber: null == membershipNumber
            ? _value.membershipNumber
            : membershipNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        farmerName: null == farmerName
            ? _value.farmerName
            : farmerName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        mpesaNumber: freezed == mpesaNumber
            ? _value.mpesaNumber
            : mpesaNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankAccountNumber: freezed == bankAccountNumber
            ? _value.bankAccountNumber
            : bankAccountNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankName: freezed == bankName
            ? _value.bankName
            : bankName // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalLitres: null == totalLitres
            ? _value.totalLitres
            : totalLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        averagePricePerLitre: null == averagePricePerLitre
            ? _value.averagePricePerLitre
            : averagePricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double,
        grossAmountOwed: null == grossAmountOwed
            ? _value.grossAmountOwed
            : grossAmountOwed // ignore: cast_nullable_to_non_nullable
                  as double,
        collectionsCount: null == collectionsCount
            ? _value.collectionsCount
            : collectionsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        fromDate: freezed == fromDate
            ? _value.fromDate
            : fromDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        toDate: freezed == toDate
            ? _value.toDate
            : toDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FarmerPayoutStatementModelImpl implements _FarmerPayoutStatementModel {
  const _$FarmerPayoutStatementModelImpl({
    @JsonKey(name: 'member_id') required this.memberId,
    @JsonKey(name: 'membership_number') required this.membershipNumber,
    @JsonKey(name: 'farmer_name') required this.farmerName,
    this.phone = '',
    @JsonKey(name: 'mpesa_number') this.mpesaNumber,
    @JsonKey(name: 'bank_account_number') this.bankAccountNumber,
    @JsonKey(name: 'bank_name') this.bankName,
    @JsonKey(name: 'total_litres') this.totalLitres = 0.0,
    @JsonKey(name: 'average_price_per_litre') this.averagePricePerLitre = 0.0,
    @JsonKey(name: 'gross_amount_owed') this.grossAmountOwed = 0.0,
    @JsonKey(name: 'collections_count') this.collectionsCount = 0,
    @JsonKey(name: 'from_date') this.fromDate,
    @JsonKey(name: 'to_date') this.toDate,
  });

  factory _$FarmerPayoutStatementModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$FarmerPayoutStatementModelImplFromJson(json);

  @override
  @JsonKey(name: 'member_id')
  final String memberId;
  @override
  @JsonKey(name: 'membership_number')
  final String membershipNumber;
  @override
  @JsonKey(name: 'farmer_name')
  final String farmerName;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey(name: 'mpesa_number')
  final String? mpesaNumber;
  @override
  @JsonKey(name: 'bank_account_number')
  final String? bankAccountNumber;
  @override
  @JsonKey(name: 'bank_name')
  final String? bankName;
  @override
  @JsonKey(name: 'total_litres')
  final double totalLitres;
  @override
  @JsonKey(name: 'average_price_per_litre')
  final double averagePricePerLitre;
  @override
  @JsonKey(name: 'gross_amount_owed')
  final double grossAmountOwed;
  @override
  @JsonKey(name: 'collections_count')
  final int collectionsCount;
  @override
  @JsonKey(name: 'from_date')
  final String? fromDate;
  @override
  @JsonKey(name: 'to_date')
  final String? toDate;

  @override
  String toString() {
    return 'FarmerPayoutStatementModel(memberId: $memberId, membershipNumber: $membershipNumber, farmerName: $farmerName, phone: $phone, mpesaNumber: $mpesaNumber, bankAccountNumber: $bankAccountNumber, bankName: $bankName, totalLitres: $totalLitres, averagePricePerLitre: $averagePricePerLitre, grossAmountOwed: $grossAmountOwed, collectionsCount: $collectionsCount, fromDate: $fromDate, toDate: $toDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FarmerPayoutStatementModelImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.membershipNumber, membershipNumber) ||
                other.membershipNumber == membershipNumber) &&
            (identical(other.farmerName, farmerName) ||
                other.farmerName == farmerName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.mpesaNumber, mpesaNumber) ||
                other.mpesaNumber == mpesaNumber) &&
            (identical(other.bankAccountNumber, bankAccountNumber) ||
                other.bankAccountNumber == bankAccountNumber) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.totalLitres, totalLitres) ||
                other.totalLitres == totalLitres) &&
            (identical(other.averagePricePerLitre, averagePricePerLitre) ||
                other.averagePricePerLitre == averagePricePerLitre) &&
            (identical(other.grossAmountOwed, grossAmountOwed) ||
                other.grossAmountOwed == grossAmountOwed) &&
            (identical(other.collectionsCount, collectionsCount) ||
                other.collectionsCount == collectionsCount) &&
            (identical(other.fromDate, fromDate) ||
                other.fromDate == fromDate) &&
            (identical(other.toDate, toDate) || other.toDate == toDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    memberId,
    membershipNumber,
    farmerName,
    phone,
    mpesaNumber,
    bankAccountNumber,
    bankName,
    totalLitres,
    averagePricePerLitre,
    grossAmountOwed,
    collectionsCount,
    fromDate,
    toDate,
  );

  /// Create a copy of FarmerPayoutStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FarmerPayoutStatementModelImplCopyWith<_$FarmerPayoutStatementModelImpl>
  get copyWith =>
      __$$FarmerPayoutStatementModelImplCopyWithImpl<
        _$FarmerPayoutStatementModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FarmerPayoutStatementModelImplToJson(this);
  }
}

abstract class _FarmerPayoutStatementModel
    implements FarmerPayoutStatementModel {
  const factory _FarmerPayoutStatementModel({
    @JsonKey(name: 'member_id') required final String memberId,
    @JsonKey(name: 'membership_number') required final String membershipNumber,
    @JsonKey(name: 'farmer_name') required final String farmerName,
    final String phone,
    @JsonKey(name: 'mpesa_number') final String? mpesaNumber,
    @JsonKey(name: 'bank_account_number') final String? bankAccountNumber,
    @JsonKey(name: 'bank_name') final String? bankName,
    @JsonKey(name: 'total_litres') final double totalLitres,
    @JsonKey(name: 'average_price_per_litre') final double averagePricePerLitre,
    @JsonKey(name: 'gross_amount_owed') final double grossAmountOwed,
    @JsonKey(name: 'collections_count') final int collectionsCount,
    @JsonKey(name: 'from_date') final String? fromDate,
    @JsonKey(name: 'to_date') final String? toDate,
  }) = _$FarmerPayoutStatementModelImpl;

  factory _FarmerPayoutStatementModel.fromJson(Map<String, dynamic> json) =
      _$FarmerPayoutStatementModelImpl.fromJson;

  @override
  @JsonKey(name: 'member_id')
  String get memberId;
  @override
  @JsonKey(name: 'membership_number')
  String get membershipNumber;
  @override
  @JsonKey(name: 'farmer_name')
  String get farmerName;
  @override
  String get phone;
  @override
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber;
  @override
  @JsonKey(name: 'bank_account_number')
  String? get bankAccountNumber;
  @override
  @JsonKey(name: 'bank_name')
  String? get bankName;
  @override
  @JsonKey(name: 'total_litres')
  double get totalLitres;
  @override
  @JsonKey(name: 'average_price_per_litre')
  double get averagePricePerLitre;
  @override
  @JsonKey(name: 'gross_amount_owed')
  double get grossAmountOwed;
  @override
  @JsonKey(name: 'collections_count')
  int get collectionsCount;
  @override
  @JsonKey(name: 'from_date')
  String? get fromDate;
  @override
  @JsonKey(name: 'to_date')
  String? get toDate;

  /// Create a copy of FarmerPayoutStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FarmerPayoutStatementModelImplCopyWith<_$FarmerPayoutStatementModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CollectorAuditSummaryModel _$CollectorAuditSummaryModelFromJson(
  Map<String, dynamic> json,
) {
  return _CollectorAuditSummaryModel.fromJson(json);
}

/// @nodoc
mixin _$CollectorAuditSummaryModel {
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String get collectorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_collected_litres')
  double get totalCollectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_purchases_amount')
  double get totalPurchasesAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sales_revenue')
  double get totalSalesRevenue => throw _privateConstructorUsedError;
  @JsonKey(name: 'cash_received_amount')
  double get cashReceivedAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_spoiled_litres')
  double get totalSpoiledLitres => throw _privateConstructorUsedError; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'balance_status')
  String get balanceStatus => throw _privateConstructorUsedError; // Allowed difference per collector per day, to balance each day alike.
  @JsonKey(name: 'tolerance_litres')
  double get toleranceLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_days')
  int get activeDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'farmers_serviced_count')
  int get farmersServicedCount => throw _privateConstructorUsedError;

  /// Serializes this CollectorAuditSummaryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollectorAuditSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollectorAuditSummaryModelCopyWith<CollectorAuditSummaryModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollectorAuditSummaryModelCopyWith<$Res> {
  factory $CollectorAuditSummaryModelCopyWith(
    CollectorAuditSummaryModel value,
    $Res Function(CollectorAuditSummaryModel) then,
  ) =
      _$CollectorAuditSummaryModelCopyWithImpl<
        $Res,
        CollectorAuditSummaryModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    @JsonKey(name: 'total_collected_litres') double totalCollectedLitres,
    @JsonKey(name: 'total_purchases_amount') double totalPurchasesAmount,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue') double totalSalesRevenue,
    @JsonKey(name: 'cash_received_amount') double cashReceivedAmount,
    @JsonKey(name: 'total_spoiled_litres') double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'tolerance_litres') double toleranceLitres,
    @JsonKey(name: 'active_days') int activeDays,
    @JsonKey(name: 'farmers_serviced_count') int farmersServicedCount,
  });
}

/// @nodoc
class _$CollectorAuditSummaryModelCopyWithImpl<
  $Res,
  $Val extends CollectorAuditSummaryModel
>
    implements $CollectorAuditSummaryModelCopyWith<$Res> {
  _$CollectorAuditSummaryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollectorAuditSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? totalCollectedLitres = null,
    Object? totalPurchasesAmount = null,
    Object? totalSoldLitres = null,
    Object? totalSalesRevenue = null,
    Object? cashReceivedAmount = null,
    Object? totalSpoiledLitres = null,
    Object? unaccountedLitres = null,
    Object? balanceStatus = null,
    Object? toleranceLitres = null,
    Object? activeDays = null,
    Object? farmersServicedCount = null,
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
            totalCollectedLitres: null == totalCollectedLitres
                ? _value.totalCollectedLitres
                : totalCollectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPurchasesAmount: null == totalPurchasesAmount
                ? _value.totalPurchasesAmount
                : totalPurchasesAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSoldLitres: null == totalSoldLitres
                ? _value.totalSoldLitres
                : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSalesRevenue: null == totalSalesRevenue
                ? _value.totalSalesRevenue
                : totalSalesRevenue // ignore: cast_nullable_to_non_nullable
                      as double,
            cashReceivedAmount: null == cashReceivedAmount
                ? _value.cashReceivedAmount
                : cashReceivedAmount // ignore: cast_nullable_to_non_nullable
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
            toleranceLitres: null == toleranceLitres
                ? _value.toleranceLitres
                : toleranceLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            activeDays: null == activeDays
                ? _value.activeDays
                : activeDays // ignore: cast_nullable_to_non_nullable
                      as int,
            farmersServicedCount: null == farmersServicedCount
                ? _value.farmersServicedCount
                : farmersServicedCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollectorAuditSummaryModelImplCopyWith<$Res>
    implements $CollectorAuditSummaryModelCopyWith<$Res> {
  factory _$$CollectorAuditSummaryModelImplCopyWith(
    _$CollectorAuditSummaryModelImpl value,
    $Res Function(_$CollectorAuditSummaryModelImpl) then,
  ) = __$$CollectorAuditSummaryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    @JsonKey(name: 'total_collected_litres') double totalCollectedLitres,
    @JsonKey(name: 'total_purchases_amount') double totalPurchasesAmount,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue') double totalSalesRevenue,
    @JsonKey(name: 'cash_received_amount') double cashReceivedAmount,
    @JsonKey(name: 'total_spoiled_litres') double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'tolerance_litres') double toleranceLitres,
    @JsonKey(name: 'active_days') int activeDays,
    @JsonKey(name: 'farmers_serviced_count') int farmersServicedCount,
  });
}

/// @nodoc
class __$$CollectorAuditSummaryModelImplCopyWithImpl<$Res>
    extends
        _$CollectorAuditSummaryModelCopyWithImpl<
          $Res,
          _$CollectorAuditSummaryModelImpl
        >
    implements _$$CollectorAuditSummaryModelImplCopyWith<$Res> {
  __$$CollectorAuditSummaryModelImplCopyWithImpl(
    _$CollectorAuditSummaryModelImpl _value,
    $Res Function(_$CollectorAuditSummaryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollectorAuditSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? totalCollectedLitres = null,
    Object? totalPurchasesAmount = null,
    Object? totalSoldLitres = null,
    Object? totalSalesRevenue = null,
    Object? cashReceivedAmount = null,
    Object? totalSpoiledLitres = null,
    Object? unaccountedLitres = null,
    Object? balanceStatus = null,
    Object? toleranceLitres = null,
    Object? activeDays = null,
    Object? farmersServicedCount = null,
  }) {
    return _then(
      _$CollectorAuditSummaryModelImpl(
        collectorId: null == collectorId
            ? _value.collectorId
            : collectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        collectorName: null == collectorName
            ? _value.collectorName
            : collectorName // ignore: cast_nullable_to_non_nullable
                  as String,
        totalCollectedLitres: null == totalCollectedLitres
            ? _value.totalCollectedLitres
            : totalCollectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPurchasesAmount: null == totalPurchasesAmount
            ? _value.totalPurchasesAmount
            : totalPurchasesAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSoldLitres: null == totalSoldLitres
            ? _value.totalSoldLitres
            : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSalesRevenue: null == totalSalesRevenue
            ? _value.totalSalesRevenue
            : totalSalesRevenue // ignore: cast_nullable_to_non_nullable
                  as double,
        cashReceivedAmount: null == cashReceivedAmount
            ? _value.cashReceivedAmount
            : cashReceivedAmount // ignore: cast_nullable_to_non_nullable
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
        toleranceLitres: null == toleranceLitres
            ? _value.toleranceLitres
            : toleranceLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        activeDays: null == activeDays
            ? _value.activeDays
            : activeDays // ignore: cast_nullable_to_non_nullable
                  as int,
        farmersServicedCount: null == farmersServicedCount
            ? _value.farmersServicedCount
            : farmersServicedCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollectorAuditSummaryModelImpl implements _CollectorAuditSummaryModel {
  const _$CollectorAuditSummaryModelImpl({
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'collector_name') this.collectorName = '',
    @JsonKey(name: 'total_collected_litres') this.totalCollectedLitres = 0.0,
    @JsonKey(name: 'total_purchases_amount') this.totalPurchasesAmount = 0.0,
    @JsonKey(name: 'total_sold_litres') this.totalSoldLitres = 0.0,
    @JsonKey(name: 'total_sales_revenue') this.totalSalesRevenue = 0.0,
    @JsonKey(name: 'cash_received_amount') this.cashReceivedAmount = 0.0,
    @JsonKey(name: 'total_spoiled_litres') this.totalSpoiledLitres = 0.0,
    @JsonKey(name: 'unaccounted_litres') this.unaccountedLitres = 0.0,
    @JsonKey(name: 'balance_status') this.balanceStatus = 'BALANCED',
    @JsonKey(name: 'tolerance_litres') this.toleranceLitres = 0.0,
    @JsonKey(name: 'active_days') this.activeDays = 0,
    @JsonKey(name: 'farmers_serviced_count') this.farmersServicedCount = 0,
  });

  factory _$CollectorAuditSummaryModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$CollectorAuditSummaryModelImplFromJson(json);

  @override
  @JsonKey(name: 'collector_id')
  final int collectorId;
  @override
  @JsonKey(name: 'collector_name')
  final String collectorName;
  @override
  @JsonKey(name: 'total_collected_litres')
  final double totalCollectedLitres;
  @override
  @JsonKey(name: 'total_purchases_amount')
  final double totalPurchasesAmount;
  @override
  @JsonKey(name: 'total_sold_litres')
  final double totalSoldLitres;
  @override
  @JsonKey(name: 'total_sales_revenue')
  final double totalSalesRevenue;
  @override
  @JsonKey(name: 'cash_received_amount')
  final double cashReceivedAmount;
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
  // Allowed difference per collector per day, to balance each day alike.
  @override
  @JsonKey(name: 'tolerance_litres')
  final double toleranceLitres;
  @override
  @JsonKey(name: 'active_days')
  final int activeDays;
  @override
  @JsonKey(name: 'farmers_serviced_count')
  final int farmersServicedCount;

  @override
  String toString() {
    return 'CollectorAuditSummaryModel(collectorId: $collectorId, collectorName: $collectorName, totalCollectedLitres: $totalCollectedLitres, totalPurchasesAmount: $totalPurchasesAmount, totalSoldLitres: $totalSoldLitres, totalSalesRevenue: $totalSalesRevenue, cashReceivedAmount: $cashReceivedAmount, totalSpoiledLitres: $totalSpoiledLitres, unaccountedLitres: $unaccountedLitres, balanceStatus: $balanceStatus, toleranceLitres: $toleranceLitres, activeDays: $activeDays, farmersServicedCount: $farmersServicedCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollectorAuditSummaryModelImpl &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName) &&
            (identical(other.totalCollectedLitres, totalCollectedLitres) ||
                other.totalCollectedLitres == totalCollectedLitres) &&
            (identical(other.totalPurchasesAmount, totalPurchasesAmount) ||
                other.totalPurchasesAmount == totalPurchasesAmount) &&
            (identical(other.totalSoldLitres, totalSoldLitres) ||
                other.totalSoldLitres == totalSoldLitres) &&
            (identical(other.totalSalesRevenue, totalSalesRevenue) ||
                other.totalSalesRevenue == totalSalesRevenue) &&
            (identical(other.cashReceivedAmount, cashReceivedAmount) ||
                other.cashReceivedAmount == cashReceivedAmount) &&
            (identical(other.totalSpoiledLitres, totalSpoiledLitres) ||
                other.totalSpoiledLitres == totalSpoiledLitres) &&
            (identical(other.unaccountedLitres, unaccountedLitres) ||
                other.unaccountedLitres == unaccountedLitres) &&
            (identical(other.balanceStatus, balanceStatus) ||
                other.balanceStatus == balanceStatus) &&
            (identical(other.toleranceLitres, toleranceLitres) ||
                other.toleranceLitres == toleranceLitres) &&
            (identical(other.activeDays, activeDays) ||
                other.activeDays == activeDays) &&
            (identical(other.farmersServicedCount, farmersServicedCount) ||
                other.farmersServicedCount == farmersServicedCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    collectorId,
    collectorName,
    totalCollectedLitres,
    totalPurchasesAmount,
    totalSoldLitres,
    totalSalesRevenue,
    cashReceivedAmount,
    totalSpoiledLitres,
    unaccountedLitres,
    balanceStatus,
    toleranceLitres,
    activeDays,
    farmersServicedCount,
  );

  /// Create a copy of CollectorAuditSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollectorAuditSummaryModelImplCopyWith<_$CollectorAuditSummaryModelImpl>
  get copyWith =>
      __$$CollectorAuditSummaryModelImplCopyWithImpl<
        _$CollectorAuditSummaryModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollectorAuditSummaryModelImplToJson(this);
  }
}

abstract class _CollectorAuditSummaryModel
    implements CollectorAuditSummaryModel {
  const factory _CollectorAuditSummaryModel({
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'collector_name') final String collectorName,
    @JsonKey(name: 'total_collected_litres') final double totalCollectedLitres,
    @JsonKey(name: 'total_purchases_amount') final double totalPurchasesAmount,
    @JsonKey(name: 'total_sold_litres') final double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue') final double totalSalesRevenue,
    @JsonKey(name: 'cash_received_amount') final double cashReceivedAmount,
    @JsonKey(name: 'total_spoiled_litres') final double totalSpoiledLitres,
    @JsonKey(name: 'unaccounted_litres') final double unaccountedLitres,
    @JsonKey(name: 'balance_status') final String balanceStatus,
    @JsonKey(name: 'tolerance_litres') final double toleranceLitres,
    @JsonKey(name: 'active_days') final int activeDays,
    @JsonKey(name: 'farmers_serviced_count') final int farmersServicedCount,
  }) = _$CollectorAuditSummaryModelImpl;

  factory _CollectorAuditSummaryModel.fromJson(Map<String, dynamic> json) =
      _$CollectorAuditSummaryModelImpl.fromJson;

  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'collector_name')
  String get collectorName;
  @override
  @JsonKey(name: 'total_collected_litres')
  double get totalCollectedLitres;
  @override
  @JsonKey(name: 'total_purchases_amount')
  double get totalPurchasesAmount;
  @override
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres;
  @override
  @JsonKey(name: 'total_sales_revenue')
  double get totalSalesRevenue;
  @override
  @JsonKey(name: 'cash_received_amount')
  double get cashReceivedAmount;
  @override
  @JsonKey(name: 'total_spoiled_litres')
  double get totalSpoiledLitres; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @override
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres;
  @override
  @JsonKey(name: 'balance_status')
  String get balanceStatus; // Allowed difference per collector per day, to balance each day alike.
  @override
  @JsonKey(name: 'tolerance_litres')
  double get toleranceLitres;
  @override
  @JsonKey(name: 'active_days')
  int get activeDays;
  @override
  @JsonKey(name: 'farmers_serviced_count')
  int get farmersServicedCount;

  /// Create a copy of CollectorAuditSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollectorAuditSummaryModelImplCopyWith<_$CollectorAuditSummaryModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SaccoReconciliationLedgerModel _$SaccoReconciliationLedgerModelFromJson(
  Map<String, dynamic> json,
) {
  return _SaccoReconciliationLedgerModel.fromJson(json);
}

/// @nodoc
mixin _$SaccoReconciliationLedgerModel {
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_name')
  String? get saccoName => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_date')
  String get fromDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_date')
  String get toDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_farmer_intake_litres')
  double get totalFarmerIntakeLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_farmer_liability_kes')
  double get totalFarmerLiabilityKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sales_revenue_kes')
  double get totalSalesRevenueKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'cash_received_kes')
  double get cashReceivedKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'credit_sales_kes')
  double get creditSalesKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_spoilage_litres')
  double get totalSpoilageLitres => throw _privateConstructorUsedError; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'allowance_litres')
  double get allowanceLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_balanced')
  bool get isBalanced => throw _privateConstructorUsedError;
  @JsonKey(name: 'balance_status')
  String get balanceStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'gross_margin_kes')
  double get grossMarginKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'receivables_kes')
  double get receivablesKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'collectors_summary')
  List<CollectorAuditSummaryModel> get collectorsSummary =>
      throw _privateConstructorUsedError;

  /// Serializes this SaccoReconciliationLedgerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaccoReconciliationLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaccoReconciliationLedgerModelCopyWith<SaccoReconciliationLedgerModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaccoReconciliationLedgerModelCopyWith<$Res> {
  factory $SaccoReconciliationLedgerModelCopyWith(
    SaccoReconciliationLedgerModel value,
    $Res Function(SaccoReconciliationLedgerModel) then,
  ) =
      _$SaccoReconciliationLedgerModelCopyWithImpl<
        $Res,
        SaccoReconciliationLedgerModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'sacco_name') String? saccoName,
    @JsonKey(name: 'from_date') String fromDate,
    @JsonKey(name: 'to_date') String toDate,
    @JsonKey(name: 'total_farmer_intake_litres') double totalFarmerIntakeLitres,
    @JsonKey(name: 'total_farmer_liability_kes') double totalFarmerLiabilityKes,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue_kes') double totalSalesRevenueKes,
    @JsonKey(name: 'cash_received_kes') double cashReceivedKes,
    @JsonKey(name: 'credit_sales_kes') double creditSalesKes,
    @JsonKey(name: 'total_spoilage_litres') double totalSpoilageLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'allowance_litres') double allowanceLitres,
    @JsonKey(name: 'is_balanced') bool isBalanced,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'gross_margin_kes') double grossMarginKes,
    @JsonKey(name: 'receivables_kes') double receivablesKes,
    @JsonKey(name: 'sales_by_customer_type')
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'collectors_summary')
    List<CollectorAuditSummaryModel> collectorsSummary,
  });
}

/// @nodoc
class _$SaccoReconciliationLedgerModelCopyWithImpl<
  $Res,
  $Val extends SaccoReconciliationLedgerModel
>
    implements $SaccoReconciliationLedgerModelCopyWith<$Res> {
  _$SaccoReconciliationLedgerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaccoReconciliationLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saccoId = null,
    Object? saccoName = freezed,
    Object? fromDate = null,
    Object? toDate = null,
    Object? totalFarmerIntakeLitres = null,
    Object? totalFarmerLiabilityKes = null,
    Object? totalSoldLitres = null,
    Object? totalSalesRevenueKes = null,
    Object? cashReceivedKes = null,
    Object? creditSalesKes = null,
    Object? totalSpoilageLitres = null,
    Object? unaccountedLitres = null,
    Object? allowanceLitres = null,
    Object? isBalanced = null,
    Object? balanceStatus = null,
    Object? grossMarginKes = null,
    Object? receivablesKes = null,
    Object? salesByCustomerType = null,
    Object? collectorsSummary = null,
  }) {
    return _then(
      _value.copyWith(
            saccoId: null == saccoId
                ? _value.saccoId
                : saccoId // ignore: cast_nullable_to_non_nullable
                      as String,
            saccoName: freezed == saccoName
                ? _value.saccoName
                : saccoName // ignore: cast_nullable_to_non_nullable
                      as String?,
            fromDate: null == fromDate
                ? _value.fromDate
                : fromDate // ignore: cast_nullable_to_non_nullable
                      as String,
            toDate: null == toDate
                ? _value.toDate
                : toDate // ignore: cast_nullable_to_non_nullable
                      as String,
            totalFarmerIntakeLitres: null == totalFarmerIntakeLitres
                ? _value.totalFarmerIntakeLitres
                : totalFarmerIntakeLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalFarmerLiabilityKes: null == totalFarmerLiabilityKes
                ? _value.totalFarmerLiabilityKes
                : totalFarmerLiabilityKes // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSoldLitres: null == totalSoldLitres
                ? _value.totalSoldLitres
                : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSalesRevenueKes: null == totalSalesRevenueKes
                ? _value.totalSalesRevenueKes
                : totalSalesRevenueKes // ignore: cast_nullable_to_non_nullable
                      as double,
            cashReceivedKes: null == cashReceivedKes
                ? _value.cashReceivedKes
                : cashReceivedKes // ignore: cast_nullable_to_non_nullable
                      as double,
            creditSalesKes: null == creditSalesKes
                ? _value.creditSalesKes
                : creditSalesKes // ignore: cast_nullable_to_non_nullable
                      as double,
            totalSpoilageLitres: null == totalSpoilageLitres
                ? _value.totalSpoilageLitres
                : totalSpoilageLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            unaccountedLitres: null == unaccountedLitres
                ? _value.unaccountedLitres
                : unaccountedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            allowanceLitres: null == allowanceLitres
                ? _value.allowanceLitres
                : allowanceLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            isBalanced: null == isBalanced
                ? _value.isBalanced
                : isBalanced // ignore: cast_nullable_to_non_nullable
                      as bool,
            balanceStatus: null == balanceStatus
                ? _value.balanceStatus
                : balanceStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            grossMarginKes: null == grossMarginKes
                ? _value.grossMarginKes
                : grossMarginKes // ignore: cast_nullable_to_non_nullable
                      as double,
            receivablesKes: null == receivablesKes
                ? _value.receivablesKes
                : receivablesKes // ignore: cast_nullable_to_non_nullable
                      as double,
            salesByCustomerType: null == salesByCustomerType
                ? _value.salesByCustomerType
                : salesByCustomerType // ignore: cast_nullable_to_non_nullable
                      as List<CustomerTypeTotalModel>,
            collectorsSummary: null == collectorsSummary
                ? _value.collectorsSummary
                : collectorsSummary // ignore: cast_nullable_to_non_nullable
                      as List<CollectorAuditSummaryModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SaccoReconciliationLedgerModelImplCopyWith<$Res>
    implements $SaccoReconciliationLedgerModelCopyWith<$Res> {
  factory _$$SaccoReconciliationLedgerModelImplCopyWith(
    _$SaccoReconciliationLedgerModelImpl value,
    $Res Function(_$SaccoReconciliationLedgerModelImpl) then,
  ) = __$$SaccoReconciliationLedgerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'sacco_name') String? saccoName,
    @JsonKey(name: 'from_date') String fromDate,
    @JsonKey(name: 'to_date') String toDate,
    @JsonKey(name: 'total_farmer_intake_litres') double totalFarmerIntakeLitres,
    @JsonKey(name: 'total_farmer_liability_kes') double totalFarmerLiabilityKes,
    @JsonKey(name: 'total_sold_litres') double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue_kes') double totalSalesRevenueKes,
    @JsonKey(name: 'cash_received_kes') double cashReceivedKes,
    @JsonKey(name: 'credit_sales_kes') double creditSalesKes,
    @JsonKey(name: 'total_spoilage_litres') double totalSpoilageLitres,
    @JsonKey(name: 'unaccounted_litres') double unaccountedLitres,
    @JsonKey(name: 'allowance_litres') double allowanceLitres,
    @JsonKey(name: 'is_balanced') bool isBalanced,
    @JsonKey(name: 'balance_status') String balanceStatus,
    @JsonKey(name: 'gross_margin_kes') double grossMarginKes,
    @JsonKey(name: 'receivables_kes') double receivablesKes,
    @JsonKey(name: 'sales_by_customer_type')
    List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'collectors_summary')
    List<CollectorAuditSummaryModel> collectorsSummary,
  });
}

/// @nodoc
class __$$SaccoReconciliationLedgerModelImplCopyWithImpl<$Res>
    extends
        _$SaccoReconciliationLedgerModelCopyWithImpl<
          $Res,
          _$SaccoReconciliationLedgerModelImpl
        >
    implements _$$SaccoReconciliationLedgerModelImplCopyWith<$Res> {
  __$$SaccoReconciliationLedgerModelImplCopyWithImpl(
    _$SaccoReconciliationLedgerModelImpl _value,
    $Res Function(_$SaccoReconciliationLedgerModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaccoReconciliationLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saccoId = null,
    Object? saccoName = freezed,
    Object? fromDate = null,
    Object? toDate = null,
    Object? totalFarmerIntakeLitres = null,
    Object? totalFarmerLiabilityKes = null,
    Object? totalSoldLitres = null,
    Object? totalSalesRevenueKes = null,
    Object? cashReceivedKes = null,
    Object? creditSalesKes = null,
    Object? totalSpoilageLitres = null,
    Object? unaccountedLitres = null,
    Object? allowanceLitres = null,
    Object? isBalanced = null,
    Object? balanceStatus = null,
    Object? grossMarginKes = null,
    Object? receivablesKes = null,
    Object? salesByCustomerType = null,
    Object? collectorsSummary = null,
  }) {
    return _then(
      _$SaccoReconciliationLedgerModelImpl(
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoName: freezed == saccoName
            ? _value.saccoName
            : saccoName // ignore: cast_nullable_to_non_nullable
                  as String?,
        fromDate: null == fromDate
            ? _value.fromDate
            : fromDate // ignore: cast_nullable_to_non_nullable
                  as String,
        toDate: null == toDate
            ? _value.toDate
            : toDate // ignore: cast_nullable_to_non_nullable
                  as String,
        totalFarmerIntakeLitres: null == totalFarmerIntakeLitres
            ? _value.totalFarmerIntakeLitres
            : totalFarmerIntakeLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalFarmerLiabilityKes: null == totalFarmerLiabilityKes
            ? _value.totalFarmerLiabilityKes
            : totalFarmerLiabilityKes // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSoldLitres: null == totalSoldLitres
            ? _value.totalSoldLitres
            : totalSoldLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSalesRevenueKes: null == totalSalesRevenueKes
            ? _value.totalSalesRevenueKes
            : totalSalesRevenueKes // ignore: cast_nullable_to_non_nullable
                  as double,
        cashReceivedKes: null == cashReceivedKes
            ? _value.cashReceivedKes
            : cashReceivedKes // ignore: cast_nullable_to_non_nullable
                  as double,
        creditSalesKes: null == creditSalesKes
            ? _value.creditSalesKes
            : creditSalesKes // ignore: cast_nullable_to_non_nullable
                  as double,
        totalSpoilageLitres: null == totalSpoilageLitres
            ? _value.totalSpoilageLitres
            : totalSpoilageLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        unaccountedLitres: null == unaccountedLitres
            ? _value.unaccountedLitres
            : unaccountedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        allowanceLitres: null == allowanceLitres
            ? _value.allowanceLitres
            : allowanceLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        isBalanced: null == isBalanced
            ? _value.isBalanced
            : isBalanced // ignore: cast_nullable_to_non_nullable
                  as bool,
        balanceStatus: null == balanceStatus
            ? _value.balanceStatus
            : balanceStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        grossMarginKes: null == grossMarginKes
            ? _value.grossMarginKes
            : grossMarginKes // ignore: cast_nullable_to_non_nullable
                  as double,
        receivablesKes: null == receivablesKes
            ? _value.receivablesKes
            : receivablesKes // ignore: cast_nullable_to_non_nullable
                  as double,
        salesByCustomerType: null == salesByCustomerType
            ? _value._salesByCustomerType
            : salesByCustomerType // ignore: cast_nullable_to_non_nullable
                  as List<CustomerTypeTotalModel>,
        collectorsSummary: null == collectorsSummary
            ? _value._collectorsSummary
            : collectorsSummary // ignore: cast_nullable_to_non_nullable
                  as List<CollectorAuditSummaryModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SaccoReconciliationLedgerModelImpl
    implements _SaccoReconciliationLedgerModel {
  const _$SaccoReconciliationLedgerModelImpl({
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'sacco_name') this.saccoName,
    @JsonKey(name: 'from_date') this.fromDate = '',
    @JsonKey(name: 'to_date') this.toDate = '',
    @JsonKey(name: 'total_farmer_intake_litres')
    this.totalFarmerIntakeLitres = 0.0,
    @JsonKey(name: 'total_farmer_liability_kes')
    this.totalFarmerLiabilityKes = 0.0,
    @JsonKey(name: 'total_sold_litres') this.totalSoldLitres = 0.0,
    @JsonKey(name: 'total_sales_revenue_kes') this.totalSalesRevenueKes = 0.0,
    @JsonKey(name: 'cash_received_kes') this.cashReceivedKes = 0.0,
    @JsonKey(name: 'credit_sales_kes') this.creditSalesKes = 0.0,
    @JsonKey(name: 'total_spoilage_litres') this.totalSpoilageLitres = 0.0,
    @JsonKey(name: 'unaccounted_litres') this.unaccountedLitres = 0.0,
    @JsonKey(name: 'allowance_litres') this.allowanceLitres = 0.0,
    @JsonKey(name: 'is_balanced') this.isBalanced = true,
    @JsonKey(name: 'balance_status') this.balanceStatus = 'BALANCED',
    @JsonKey(name: 'gross_margin_kes') this.grossMarginKes = 0.0,
    @JsonKey(name: 'receivables_kes') this.receivablesKes = 0.0,
    @JsonKey(name: 'sales_by_customer_type')
    final List<CustomerTypeTotalModel> salesByCustomerType = const [],
    @JsonKey(name: 'collectors_summary')
    final List<CollectorAuditSummaryModel> collectorsSummary = const [],
  }) : _salesByCustomerType = salesByCustomerType,
       _collectorsSummary = collectorsSummary;

  factory _$SaccoReconciliationLedgerModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$SaccoReconciliationLedgerModelImplFromJson(json);

  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'sacco_name')
  final String? saccoName;
  @override
  @JsonKey(name: 'from_date')
  final String fromDate;
  @override
  @JsonKey(name: 'to_date')
  final String toDate;
  @override
  @JsonKey(name: 'total_farmer_intake_litres')
  final double totalFarmerIntakeLitres;
  @override
  @JsonKey(name: 'total_farmer_liability_kes')
  final double totalFarmerLiabilityKes;
  @override
  @JsonKey(name: 'total_sold_litres')
  final double totalSoldLitres;
  @override
  @JsonKey(name: 'total_sales_revenue_kes')
  final double totalSalesRevenueKes;
  @override
  @JsonKey(name: 'cash_received_kes')
  final double cashReceivedKes;
  @override
  @JsonKey(name: 'credit_sales_kes')
  final double creditSalesKes;
  @override
  @JsonKey(name: 'total_spoilage_litres')
  final double totalSpoilageLitres;
  // collected - sold - spoiled; > 0 missing, < 0 oversold
  @override
  @JsonKey(name: 'unaccounted_litres')
  final double unaccountedLitres;
  @override
  @JsonKey(name: 'allowance_litres')
  final double allowanceLitres;
  @override
  @JsonKey(name: 'is_balanced')
  final bool isBalanced;
  @override
  @JsonKey(name: 'balance_status')
  final String balanceStatus;
  @override
  @JsonKey(name: 'gross_margin_kes')
  final double grossMarginKes;
  @override
  @JsonKey(name: 'receivables_kes')
  final double receivablesKes;
  final List<CustomerTypeTotalModel> _salesByCustomerType;
  @override
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType {
    if (_salesByCustomerType is EqualUnmodifiableListView)
      return _salesByCustomerType;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_salesByCustomerType);
  }

  final List<CollectorAuditSummaryModel> _collectorsSummary;
  @override
  @JsonKey(name: 'collectors_summary')
  List<CollectorAuditSummaryModel> get collectorsSummary {
    if (_collectorsSummary is EqualUnmodifiableListView)
      return _collectorsSummary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collectorsSummary);
  }

  @override
  String toString() {
    return 'SaccoReconciliationLedgerModel(saccoId: $saccoId, saccoName: $saccoName, fromDate: $fromDate, toDate: $toDate, totalFarmerIntakeLitres: $totalFarmerIntakeLitres, totalFarmerLiabilityKes: $totalFarmerLiabilityKes, totalSoldLitres: $totalSoldLitres, totalSalesRevenueKes: $totalSalesRevenueKes, cashReceivedKes: $cashReceivedKes, creditSalesKes: $creditSalesKes, totalSpoilageLitres: $totalSpoilageLitres, unaccountedLitres: $unaccountedLitres, allowanceLitres: $allowanceLitres, isBalanced: $isBalanced, balanceStatus: $balanceStatus, grossMarginKes: $grossMarginKes, receivablesKes: $receivablesKes, salesByCustomerType: $salesByCustomerType, collectorsSummary: $collectorsSummary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaccoReconciliationLedgerModelImpl &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.saccoName, saccoName) ||
                other.saccoName == saccoName) &&
            (identical(other.fromDate, fromDate) ||
                other.fromDate == fromDate) &&
            (identical(other.toDate, toDate) || other.toDate == toDate) &&
            (identical(
                  other.totalFarmerIntakeLitres,
                  totalFarmerIntakeLitres,
                ) ||
                other.totalFarmerIntakeLitres == totalFarmerIntakeLitres) &&
            (identical(
                  other.totalFarmerLiabilityKes,
                  totalFarmerLiabilityKes,
                ) ||
                other.totalFarmerLiabilityKes == totalFarmerLiabilityKes) &&
            (identical(other.totalSoldLitres, totalSoldLitres) ||
                other.totalSoldLitres == totalSoldLitres) &&
            (identical(other.totalSalesRevenueKes, totalSalesRevenueKes) ||
                other.totalSalesRevenueKes == totalSalesRevenueKes) &&
            (identical(other.cashReceivedKes, cashReceivedKes) ||
                other.cashReceivedKes == cashReceivedKes) &&
            (identical(other.creditSalesKes, creditSalesKes) ||
                other.creditSalesKes == creditSalesKes) &&
            (identical(other.totalSpoilageLitres, totalSpoilageLitres) ||
                other.totalSpoilageLitres == totalSpoilageLitres) &&
            (identical(other.unaccountedLitres, unaccountedLitres) ||
                other.unaccountedLitres == unaccountedLitres) &&
            (identical(other.allowanceLitres, allowanceLitres) ||
                other.allowanceLitres == allowanceLitres) &&
            (identical(other.isBalanced, isBalanced) ||
                other.isBalanced == isBalanced) &&
            (identical(other.balanceStatus, balanceStatus) ||
                other.balanceStatus == balanceStatus) &&
            (identical(other.grossMarginKes, grossMarginKes) ||
                other.grossMarginKes == grossMarginKes) &&
            (identical(other.receivablesKes, receivablesKes) ||
                other.receivablesKes == receivablesKes) &&
            const DeepCollectionEquality().equals(
              other._salesByCustomerType,
              _salesByCustomerType,
            ) &&
            const DeepCollectionEquality().equals(
              other._collectorsSummary,
              _collectorsSummary,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    saccoId,
    saccoName,
    fromDate,
    toDate,
    totalFarmerIntakeLitres,
    totalFarmerLiabilityKes,
    totalSoldLitres,
    totalSalesRevenueKes,
    cashReceivedKes,
    creditSalesKes,
    totalSpoilageLitres,
    unaccountedLitres,
    allowanceLitres,
    isBalanced,
    balanceStatus,
    grossMarginKes,
    receivablesKes,
    const DeepCollectionEquality().hash(_salesByCustomerType),
    const DeepCollectionEquality().hash(_collectorsSummary),
  ]);

  /// Create a copy of SaccoReconciliationLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaccoReconciliationLedgerModelImplCopyWith<
    _$SaccoReconciliationLedgerModelImpl
  >
  get copyWith =>
      __$$SaccoReconciliationLedgerModelImplCopyWithImpl<
        _$SaccoReconciliationLedgerModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaccoReconciliationLedgerModelImplToJson(this);
  }
}

abstract class _SaccoReconciliationLedgerModel
    implements SaccoReconciliationLedgerModel {
  const factory _SaccoReconciliationLedgerModel({
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'sacco_name') final String? saccoName,
    @JsonKey(name: 'from_date') final String fromDate,
    @JsonKey(name: 'to_date') final String toDate,
    @JsonKey(name: 'total_farmer_intake_litres')
    final double totalFarmerIntakeLitres,
    @JsonKey(name: 'total_farmer_liability_kes')
    final double totalFarmerLiabilityKes,
    @JsonKey(name: 'total_sold_litres') final double totalSoldLitres,
    @JsonKey(name: 'total_sales_revenue_kes') final double totalSalesRevenueKes,
    @JsonKey(name: 'cash_received_kes') final double cashReceivedKes,
    @JsonKey(name: 'credit_sales_kes') final double creditSalesKes,
    @JsonKey(name: 'total_spoilage_litres') final double totalSpoilageLitres,
    @JsonKey(name: 'unaccounted_litres') final double unaccountedLitres,
    @JsonKey(name: 'allowance_litres') final double allowanceLitres,
    @JsonKey(name: 'is_balanced') final bool isBalanced,
    @JsonKey(name: 'balance_status') final String balanceStatus,
    @JsonKey(name: 'gross_margin_kes') final double grossMarginKes,
    @JsonKey(name: 'receivables_kes') final double receivablesKes,
    @JsonKey(name: 'sales_by_customer_type')
    final List<CustomerTypeTotalModel> salesByCustomerType,
    @JsonKey(name: 'collectors_summary')
    final List<CollectorAuditSummaryModel> collectorsSummary,
  }) = _$SaccoReconciliationLedgerModelImpl;

  factory _SaccoReconciliationLedgerModel.fromJson(Map<String, dynamic> json) =
      _$SaccoReconciliationLedgerModelImpl.fromJson;

  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'sacco_name')
  String? get saccoName;
  @override
  @JsonKey(name: 'from_date')
  String get fromDate;
  @override
  @JsonKey(name: 'to_date')
  String get toDate;
  @override
  @JsonKey(name: 'total_farmer_intake_litres')
  double get totalFarmerIntakeLitres;
  @override
  @JsonKey(name: 'total_farmer_liability_kes')
  double get totalFarmerLiabilityKes;
  @override
  @JsonKey(name: 'total_sold_litres')
  double get totalSoldLitres;
  @override
  @JsonKey(name: 'total_sales_revenue_kes')
  double get totalSalesRevenueKes;
  @override
  @JsonKey(name: 'cash_received_kes')
  double get cashReceivedKes;
  @override
  @JsonKey(name: 'credit_sales_kes')
  double get creditSalesKes;
  @override
  @JsonKey(name: 'total_spoilage_litres')
  double get totalSpoilageLitres; // collected - sold - spoiled; > 0 missing, < 0 oversold
  @override
  @JsonKey(name: 'unaccounted_litres')
  double get unaccountedLitres;
  @override
  @JsonKey(name: 'allowance_litres')
  double get allowanceLitres;
  @override
  @JsonKey(name: 'is_balanced')
  bool get isBalanced;
  @override
  @JsonKey(name: 'balance_status')
  String get balanceStatus;
  @override
  @JsonKey(name: 'gross_margin_kes')
  double get grossMarginKes;
  @override
  @JsonKey(name: 'receivables_kes')
  double get receivablesKes;
  @override
  @JsonKey(name: 'sales_by_customer_type')
  List<CustomerTypeTotalModel> get salesByCustomerType;
  @override
  @JsonKey(name: 'collectors_summary')
  List<CollectorAuditSummaryModel> get collectorsSummary;

  /// Create a copy of SaccoReconciliationLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaccoReconciliationLedgerModelImplCopyWith<
    _$SaccoReconciliationLedgerModelImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
