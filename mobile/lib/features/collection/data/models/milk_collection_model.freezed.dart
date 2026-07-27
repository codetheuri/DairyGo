// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'milk_collection_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MilkPriceModel _$MilkPriceModelFromJson(Map<String, dynamic> json) {
  return _MilkPriceModel.fromJson(json);
}

/// @nodoc
mixin _$MilkPriceModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre => throw _privateConstructorUsedError;
  @JsonKey(name: 'effective_date')
  String? get effectiveDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this MilkPriceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilkPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilkPriceModelCopyWith<MilkPriceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilkPriceModelCopyWith<$Res> {
  factory $MilkPriceModelCopyWith(
    MilkPriceModel value,
    $Res Function(MilkPriceModel) then,
  ) = _$MilkPriceModelCopyWithImpl<$Res, MilkPriceModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
    @JsonKey(name: 'is_active') bool isActive,
  });
}

/// @nodoc
class _$MilkPriceModelCopyWithImpl<$Res, $Val extends MilkPriceModel>
    implements $MilkPriceModelCopyWith<$Res> {
  _$MilkPriceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilkPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? pricePerLitre = null,
    Object? effectiveDate = freezed,
    Object? isActive = null,
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
            pricePerLitre: null == pricePerLitre
                ? _value.pricePerLitre
                : pricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double,
            effectiveDate: freezed == effectiveDate
                ? _value.effectiveDate
                : effectiveDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilkPriceModelImplCopyWith<$Res>
    implements $MilkPriceModelCopyWith<$Res> {
  factory _$$MilkPriceModelImplCopyWith(
    _$MilkPriceModelImpl value,
    $Res Function(_$MilkPriceModelImpl) then,
  ) = __$$MilkPriceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
    @JsonKey(name: 'is_active') bool isActive,
  });
}

/// @nodoc
class __$$MilkPriceModelImplCopyWithImpl<$Res>
    extends _$MilkPriceModelCopyWithImpl<$Res, _$MilkPriceModelImpl>
    implements _$$MilkPriceModelImplCopyWith<$Res> {
  __$$MilkPriceModelImplCopyWithImpl(
    _$MilkPriceModelImpl _value,
    $Res Function(_$MilkPriceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilkPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? pricePerLitre = null,
    Object? effectiveDate = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _$MilkPriceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        pricePerLitre: null == pricePerLitre
            ? _value.pricePerLitre
            : pricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double,
        effectiveDate: freezed == effectiveDate
            ? _value.effectiveDate
            : effectiveDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MilkPriceModelImpl implements _MilkPriceModel {
  const _$MilkPriceModelImpl({
    required this.id,
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'price_per_litre') this.pricePerLitre = 0.0,
    @JsonKey(name: 'effective_date') this.effectiveDate,
    @JsonKey(name: 'is_active') this.isActive = true,
  });

  factory _$MilkPriceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilkPriceModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;
  @override
  @JsonKey(name: 'effective_date')
  final String? effectiveDate;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  @override
  String toString() {
    return 'MilkPriceModel(id: $id, saccoId: $saccoId, pricePerLitre: $pricePerLitre, effectiveDate: $effectiveDate, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilkPriceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.pricePerLitre, pricePerLitre) ||
                other.pricePerLitre == pricePerLitre) &&
            (identical(other.effectiveDate, effectiveDate) ||
                other.effectiveDate == effectiveDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    saccoId,
    pricePerLitre,
    effectiveDate,
    isActive,
  );

  /// Create a copy of MilkPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilkPriceModelImplCopyWith<_$MilkPriceModelImpl> get copyWith =>
      __$$MilkPriceModelImplCopyWithImpl<_$MilkPriceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MilkPriceModelImplToJson(this);
  }
}

abstract class _MilkPriceModel implements MilkPriceModel {
  const factory _MilkPriceModel({
    required final String id,
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'price_per_litre') final double pricePerLitre,
    @JsonKey(name: 'effective_date') final String? effectiveDate,
    @JsonKey(name: 'is_active') final bool isActive,
  }) = _$MilkPriceModelImpl;

  factory _MilkPriceModel.fromJson(Map<String, dynamic> json) =
      _$MilkPriceModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre;
  @override
  @JsonKey(name: 'effective_date')
  String? get effectiveDate;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;

  /// Create a copy of MilkPriceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilkPriceModelImplCopyWith<_$MilkPriceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MilkCollectionModel _$MilkCollectionModelFromJson(Map<String, dynamic> json) {
  return _MilkCollectionModel.fromJson(json);
}

/// @nodoc
mixin _$MilkCollectionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_id')
  String get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collection_date')
  String get collectionDate => throw _privateConstructorUsedError;
  String get shift => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError; // Optional populated member & collector fields
  @JsonKey(name: 'member_name')
  String? get memberName => throw _privateConstructorUsedError;
  @JsonKey(name: 'membership_number')
  String? get membershipNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String? get collectorName => throw _privateConstructorUsedError;

  /// Serializes this MilkCollectionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilkCollectionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilkCollectionModelCopyWith<MilkCollectionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilkCollectionModelCopyWith<$Res> {
  factory $MilkCollectionModelCopyWith(
    MilkCollectionModel value,
    $Res Function(MilkCollectionModel) then,
  ) = _$MilkCollectionModelCopyWithImpl<$Res, MilkCollectionModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collection_date') String collectionDate,
    String shift,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'total_amount') double totalAmount,
    String status,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'member_name') String? memberName,
    @JsonKey(name: 'membership_number') String? membershipNumber,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class _$MilkCollectionModelCopyWithImpl<$Res, $Val extends MilkCollectionModel>
    implements $MilkCollectionModelCopyWith<$Res> {
  _$MilkCollectionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilkCollectionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? memberId = null,
    Object? collectorId = null,
    Object? collectionDate = null,
    Object? shift = null,
    Object? quantityLitres = null,
    Object? pricePerLitre = null,
    Object? totalAmount = null,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? memberName = freezed,
    Object? membershipNumber = freezed,
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
            memberId: null == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String,
            collectorId: null == collectorId
                ? _value.collectorId
                : collectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            collectionDate: null == collectionDate
                ? _value.collectionDate
                : collectionDate // ignore: cast_nullable_to_non_nullable
                      as String,
            shift: null == shift
                ? _value.shift
                : shift // ignore: cast_nullable_to_non_nullable
                      as String,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            pricePerLitre: null == pricePerLitre
                ? _value.pricePerLitre
                : pricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberName: freezed == memberName
                ? _value.memberName
                : memberName // ignore: cast_nullable_to_non_nullable
                      as String?,
            membershipNumber: freezed == membershipNumber
                ? _value.membershipNumber
                : membershipNumber // ignore: cast_nullable_to_non_nullable
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
abstract class _$$MilkCollectionModelImplCopyWith<$Res>
    implements $MilkCollectionModelCopyWith<$Res> {
  factory _$$MilkCollectionModelImplCopyWith(
    _$MilkCollectionModelImpl value,
    $Res Function(_$MilkCollectionModelImpl) then,
  ) = __$$MilkCollectionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collection_date') String collectionDate,
    String shift,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'total_amount') double totalAmount,
    String status,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'member_name') String? memberName,
    @JsonKey(name: 'membership_number') String? membershipNumber,
    @JsonKey(name: 'collector_name') String? collectorName,
  });
}

/// @nodoc
class __$$MilkCollectionModelImplCopyWithImpl<$Res>
    extends _$MilkCollectionModelCopyWithImpl<$Res, _$MilkCollectionModelImpl>
    implements _$$MilkCollectionModelImplCopyWith<$Res> {
  __$$MilkCollectionModelImplCopyWithImpl(
    _$MilkCollectionModelImpl _value,
    $Res Function(_$MilkCollectionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilkCollectionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? memberId = null,
    Object? collectorId = null,
    Object? collectionDate = null,
    Object? shift = null,
    Object? quantityLitres = null,
    Object? pricePerLitre = null,
    Object? totalAmount = null,
    Object? status = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? memberName = freezed,
    Object? membershipNumber = freezed,
    Object? collectorName = freezed,
  }) {
    return _then(
      _$MilkCollectionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        memberId: null == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String,
        collectorId: null == collectorId
            ? _value.collectorId
            : collectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        collectionDate: null == collectionDate
            ? _value.collectionDate
            : collectionDate // ignore: cast_nullable_to_non_nullable
                  as String,
        shift: null == shift
            ? _value.shift
            : shift // ignore: cast_nullable_to_non_nullable
                  as String,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        pricePerLitre: null == pricePerLitre
            ? _value.pricePerLitre
            : pricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberName: freezed == memberName
            ? _value.memberName
            : memberName // ignore: cast_nullable_to_non_nullable
                  as String?,
        membershipNumber: freezed == membershipNumber
            ? _value.membershipNumber
            : membershipNumber // ignore: cast_nullable_to_non_nullable
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
class _$MilkCollectionModelImpl extends _MilkCollectionModel {
  const _$MilkCollectionModelImpl({
    required this.id,
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'member_id') required this.memberId,
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'collection_date') required this.collectionDate,
    this.shift = 'MORNING',
    @JsonKey(name: 'quantity_litres') this.quantityLitres = 0.0,
    @JsonKey(name: 'price_per_litre') this.pricePerLitre = 0.0,
    @JsonKey(name: 'total_amount') this.totalAmount = 0.0,
    this.status = 'SUBMITTED',
    this.notes,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'member_name') this.memberName,
    @JsonKey(name: 'membership_number') this.membershipNumber,
    @JsonKey(name: 'collector_name') this.collectorName,
  }) : super._();

  factory _$MilkCollectionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilkCollectionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'member_id')
  final String memberId;
  @override
  @JsonKey(name: 'collector_id')
  final int collectorId;
  @override
  @JsonKey(name: 'collection_date')
  final String collectionDate;
  @override
  @JsonKey()
  final String shift;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  // Optional populated member & collector fields
  @override
  @JsonKey(name: 'member_name')
  final String? memberName;
  @override
  @JsonKey(name: 'membership_number')
  final String? membershipNumber;
  @override
  @JsonKey(name: 'collector_name')
  final String? collectorName;

  @override
  String toString() {
    return 'MilkCollectionModel(id: $id, saccoId: $saccoId, memberId: $memberId, collectorId: $collectorId, collectionDate: $collectionDate, shift: $shift, quantityLitres: $quantityLitres, pricePerLitre: $pricePerLitre, totalAmount: $totalAmount, status: $status, notes: $notes, createdAt: $createdAt, memberName: $memberName, membershipNumber: $membershipNumber, collectorName: $collectorName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilkCollectionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.collectionDate, collectionDate) ||
                other.collectionDate == collectionDate) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.pricePerLitre, pricePerLitre) ||
                other.pricePerLitre == pricePerLitre) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.memberName, memberName) ||
                other.memberName == memberName) &&
            (identical(other.membershipNumber, membershipNumber) ||
                other.membershipNumber == membershipNumber) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    saccoId,
    memberId,
    collectorId,
    collectionDate,
    shift,
    quantityLitres,
    pricePerLitre,
    totalAmount,
    status,
    notes,
    createdAt,
    memberName,
    membershipNumber,
    collectorName,
  );

  /// Create a copy of MilkCollectionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilkCollectionModelImplCopyWith<_$MilkCollectionModelImpl> get copyWith =>
      __$$MilkCollectionModelImplCopyWithImpl<_$MilkCollectionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MilkCollectionModelImplToJson(this);
  }
}

abstract class _MilkCollectionModel extends MilkCollectionModel {
  const factory _MilkCollectionModel({
    required final String id,
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'member_id') required final String memberId,
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'collection_date') required final String collectionDate,
    final String shift,
    @JsonKey(name: 'quantity_litres') final double quantityLitres,
    @JsonKey(name: 'price_per_litre') final double pricePerLitre,
    @JsonKey(name: 'total_amount') final double totalAmount,
    final String status,
    final String? notes,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'member_name') final String? memberName,
    @JsonKey(name: 'membership_number') final String? membershipNumber,
    @JsonKey(name: 'collector_name') final String? collectorName,
  }) = _$MilkCollectionModelImpl;
  const _MilkCollectionModel._() : super._();

  factory _MilkCollectionModel.fromJson(Map<String, dynamic> json) =
      _$MilkCollectionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'member_id')
  String get memberId;
  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'collection_date')
  String get collectionDate;
  @override
  String get shift;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  String get status;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt; // Optional populated member & collector fields
  @override
  @JsonKey(name: 'member_name')
  String? get memberName;
  @override
  @JsonKey(name: 'membership_number')
  String? get membershipNumber;
  @override
  @JsonKey(name: 'collector_name')
  String? get collectorName;

  /// Create a copy of MilkCollectionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilkCollectionModelImplCopyWith<_$MilkCollectionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecordCollectionRequestModel _$RecordCollectionRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _RecordCollectionRequestModel.fromJson(json);
}

/// @nodoc
mixin _$RecordCollectionRequestModel {
  @JsonKey(name: 'member_id')
  String get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collection_date')
  String? get collectionDate => throw _privateConstructorUsedError;
  String get shift => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_litre')
  double? get pricePerLitre => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this RecordCollectionRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordCollectionRequestModelCopyWith<RecordCollectionRequestModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordCollectionRequestModelCopyWith<$Res> {
  factory $RecordCollectionRequestModelCopyWith(
    RecordCollectionRequestModel value,
    $Res Function(RecordCollectionRequestModel) then,
  ) =
      _$RecordCollectionRequestModelCopyWithImpl<
        $Res,
        RecordCollectionRequestModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'collection_date') String? collectionDate,
    String shift,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'price_per_litre') double? pricePerLitre,
    String? notes,
  });
}

/// @nodoc
class _$RecordCollectionRequestModelCopyWithImpl<
  $Res,
  $Val extends RecordCollectionRequestModel
>
    implements $RecordCollectionRequestModelCopyWith<$Res> {
  _$RecordCollectionRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? collectionDate = freezed,
    Object? shift = null,
    Object? quantityLitres = null,
    Object? pricePerLitre = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            memberId: null == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String,
            collectionDate: freezed == collectionDate
                ? _value.collectionDate
                : collectionDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            shift: null == shift
                ? _value.shift
                : shift // ignore: cast_nullable_to_non_nullable
                      as String,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            pricePerLitre: freezed == pricePerLitre
                ? _value.pricePerLitre
                : pricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double?,
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
abstract class _$$RecordCollectionRequestModelImplCopyWith<$Res>
    implements $RecordCollectionRequestModelCopyWith<$Res> {
  factory _$$RecordCollectionRequestModelImplCopyWith(
    _$RecordCollectionRequestModelImpl value,
    $Res Function(_$RecordCollectionRequestModelImpl) then,
  ) = __$$RecordCollectionRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'member_id') String memberId,
    @JsonKey(name: 'collection_date') String? collectionDate,
    String shift,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    @JsonKey(name: 'price_per_litre') double? pricePerLitre,
    String? notes,
  });
}

/// @nodoc
class __$$RecordCollectionRequestModelImplCopyWithImpl<$Res>
    extends
        _$RecordCollectionRequestModelCopyWithImpl<
          $Res,
          _$RecordCollectionRequestModelImpl
        >
    implements _$$RecordCollectionRequestModelImplCopyWith<$Res> {
  __$$RecordCollectionRequestModelImplCopyWithImpl(
    _$RecordCollectionRequestModelImpl _value,
    $Res Function(_$RecordCollectionRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? collectionDate = freezed,
    Object? shift = null,
    Object? quantityLitres = null,
    Object? pricePerLitre = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$RecordCollectionRequestModelImpl(
        memberId: null == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String,
        collectionDate: freezed == collectionDate
            ? _value.collectionDate
            : collectionDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        shift: null == shift
            ? _value.shift
            : shift // ignore: cast_nullable_to_non_nullable
                  as String,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        pricePerLitre: freezed == pricePerLitre
            ? _value.pricePerLitre
            : pricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double?,
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
class _$RecordCollectionRequestModelImpl
    implements _RecordCollectionRequestModel {
  const _$RecordCollectionRequestModelImpl({
    @JsonKey(name: 'member_id') required this.memberId,
    @JsonKey(name: 'collection_date') this.collectionDate,
    this.shift = 'MORNING',
    @JsonKey(name: 'quantity_litres') required this.quantityLitres,
    @JsonKey(name: 'price_per_litre') this.pricePerLitre,
    this.notes,
  });

  factory _$RecordCollectionRequestModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RecordCollectionRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'member_id')
  final String memberId;
  @override
  @JsonKey(name: 'collection_date')
  final String? collectionDate;
  @override
  @JsonKey()
  final String shift;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  @JsonKey(name: 'price_per_litre')
  final double? pricePerLitre;
  @override
  final String? notes;

  @override
  String toString() {
    return 'RecordCollectionRequestModel(memberId: $memberId, collectionDate: $collectionDate, shift: $shift, quantityLitres: $quantityLitres, pricePerLitre: $pricePerLitre, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordCollectionRequestModelImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.collectionDate, collectionDate) ||
                other.collectionDate == collectionDate) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.pricePerLitre, pricePerLitre) ||
                other.pricePerLitre == pricePerLitre) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    memberId,
    collectionDate,
    shift,
    quantityLitres,
    pricePerLitre,
    notes,
  );

  /// Create a copy of RecordCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordCollectionRequestModelImplCopyWith<
    _$RecordCollectionRequestModelImpl
  >
  get copyWith =>
      __$$RecordCollectionRequestModelImplCopyWithImpl<
        _$RecordCollectionRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordCollectionRequestModelImplToJson(this);
  }
}

abstract class _RecordCollectionRequestModel
    implements RecordCollectionRequestModel {
  const factory _RecordCollectionRequestModel({
    @JsonKey(name: 'member_id') required final String memberId,
    @JsonKey(name: 'collection_date') final String? collectionDate,
    final String shift,
    @JsonKey(name: 'quantity_litres') required final double quantityLitres,
    @JsonKey(name: 'price_per_litre') final double? pricePerLitre,
    final String? notes,
  }) = _$RecordCollectionRequestModelImpl;

  factory _RecordCollectionRequestModel.fromJson(Map<String, dynamic> json) =
      _$RecordCollectionRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'member_id')
  String get memberId;
  @override
  @JsonKey(name: 'collection_date')
  String? get collectionDate;
  @override
  String get shift;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  @JsonKey(name: 'price_per_litre')
  double? get pricePerLitre;
  @override
  String? get notes;

  /// Create a copy of RecordCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordCollectionRequestModelImplCopyWith<
    _$RecordCollectionRequestModelImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

UpdateCollectionRequestModel _$UpdateCollectionRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _UpdateCollectionRequestModel.fromJson(json);
}

/// @nodoc
mixin _$UpdateCollectionRequestModel {
  @JsonKey(name: 'quantity_litres')
  double? get quantityLitres => throw _privateConstructorUsedError;
  String? get shift => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this UpdateCollectionRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateCollectionRequestModelCopyWith<UpdateCollectionRequestModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateCollectionRequestModelCopyWith<$Res> {
  factory $UpdateCollectionRequestModelCopyWith(
    UpdateCollectionRequestModel value,
    $Res Function(UpdateCollectionRequestModel) then,
  ) =
      _$UpdateCollectionRequestModelCopyWithImpl<
        $Res,
        UpdateCollectionRequestModel
      >;
  @useResult
  $Res call({
    @JsonKey(name: 'quantity_litres') double? quantityLitres,
    String? shift,
    String? notes,
  });
}

/// @nodoc
class _$UpdateCollectionRequestModelCopyWithImpl<
  $Res,
  $Val extends UpdateCollectionRequestModel
>
    implements $UpdateCollectionRequestModelCopyWith<$Res> {
  _$UpdateCollectionRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? quantityLitres = freezed,
    Object? shift = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            quantityLitres: freezed == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double?,
            shift: freezed == shift
                ? _value.shift
                : shift // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$UpdateCollectionRequestModelImplCopyWith<$Res>
    implements $UpdateCollectionRequestModelCopyWith<$Res> {
  factory _$$UpdateCollectionRequestModelImplCopyWith(
    _$UpdateCollectionRequestModelImpl value,
    $Res Function(_$UpdateCollectionRequestModelImpl) then,
  ) = __$$UpdateCollectionRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'quantity_litres') double? quantityLitres,
    String? shift,
    String? notes,
  });
}

/// @nodoc
class __$$UpdateCollectionRequestModelImplCopyWithImpl<$Res>
    extends
        _$UpdateCollectionRequestModelCopyWithImpl<
          $Res,
          _$UpdateCollectionRequestModelImpl
        >
    implements _$$UpdateCollectionRequestModelImplCopyWith<$Res> {
  __$$UpdateCollectionRequestModelImplCopyWithImpl(
    _$UpdateCollectionRequestModelImpl _value,
    $Res Function(_$UpdateCollectionRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdateCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? quantityLitres = freezed,
    Object? shift = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$UpdateCollectionRequestModelImpl(
        quantityLitres: freezed == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double?,
        shift: freezed == shift
            ? _value.shift
            : shift // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$UpdateCollectionRequestModelImpl
    implements _UpdateCollectionRequestModel {
  const _$UpdateCollectionRequestModelImpl({
    @JsonKey(name: 'quantity_litres') this.quantityLitres,
    this.shift,
    this.notes,
  });

  factory _$UpdateCollectionRequestModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$UpdateCollectionRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'quantity_litres')
  final double? quantityLitres;
  @override
  final String? shift;
  @override
  final String? notes;

  @override
  String toString() {
    return 'UpdateCollectionRequestModel(quantityLitres: $quantityLitres, shift: $shift, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateCollectionRequestModelImpl &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, quantityLitres, shift, notes);

  /// Create a copy of UpdateCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateCollectionRequestModelImplCopyWith<
    _$UpdateCollectionRequestModelImpl
  >
  get copyWith =>
      __$$UpdateCollectionRequestModelImplCopyWithImpl<
        _$UpdateCollectionRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateCollectionRequestModelImplToJson(this);
  }
}

abstract class _UpdateCollectionRequestModel
    implements UpdateCollectionRequestModel {
  const factory _UpdateCollectionRequestModel({
    @JsonKey(name: 'quantity_litres') final double? quantityLitres,
    final String? shift,
    final String? notes,
  }) = _$UpdateCollectionRequestModelImpl;

  factory _UpdateCollectionRequestModel.fromJson(Map<String, dynamic> json) =
      _$UpdateCollectionRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'quantity_litres')
  double? get quantityLitres;
  @override
  String? get shift;
  @override
  String? get notes;

  /// Create a copy of UpdateCollectionRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateCollectionRequestModelImplCopyWith<
    _$UpdateCollectionRequestModelImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
