// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MilkTransferModel _$MilkTransferModelFromJson(Map<String, dynamic> json) {
  return _MilkTransferModel.fromJson(json);
}

/// @nodoc
mixin _$MilkTransferModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_collector_id')
  int get fromCollectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_collector_id')
  int get toCollectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_collector_name')
  String get fromCollectorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_collector_name')
  String get toCollectorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'transfer_date')
  String get transferDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'recorded_by_id')
  int get recordedById => throw _privateConstructorUsedError;
  @JsonKey(name: 'voided_at')
  String? get voidedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'void_reason')
  String? get voidReason => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError; // Set when DairyGo support entered the record after its day.
  @JsonKey(name: 'late_reason')
  String? get lateReason => throw _privateConstructorUsedError;

  /// Serializes this MilkTransferModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilkTransferModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilkTransferModelCopyWith<MilkTransferModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilkTransferModelCopyWith<$Res> {
  factory $MilkTransferModelCopyWith(
    MilkTransferModel value,
    $Res Function(MilkTransferModel) then,
  ) = _$MilkTransferModelCopyWithImpl<$Res, MilkTransferModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'from_collector_id') int fromCollectorId,
    @JsonKey(name: 'to_collector_id') int toCollectorId,
    @JsonKey(name: 'from_collector_name') String fromCollectorName,
    @JsonKey(name: 'to_collector_name') String toCollectorName,
    @JsonKey(name: 'transfer_date') String transferDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String? notes,
    @JsonKey(name: 'recorded_by_id') int recordedById,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'late_reason') String? lateReason,
  });
}

/// @nodoc
class _$MilkTransferModelCopyWithImpl<$Res, $Val extends MilkTransferModel>
    implements $MilkTransferModelCopyWith<$Res> {
  _$MilkTransferModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilkTransferModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromCollectorId = null,
    Object? toCollectorId = null,
    Object? fromCollectorName = null,
    Object? toCollectorName = null,
    Object? transferDate = null,
    Object? quantityLitres = null,
    Object? notes = freezed,
    Object? recordedById = null,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? createdAt = freezed,
    Object? lateReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fromCollectorId: null == fromCollectorId
                ? _value.fromCollectorId
                : fromCollectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            toCollectorId: null == toCollectorId
                ? _value.toCollectorId
                : toCollectorId // ignore: cast_nullable_to_non_nullable
                      as int,
            fromCollectorName: null == fromCollectorName
                ? _value.fromCollectorName
                : fromCollectorName // ignore: cast_nullable_to_non_nullable
                      as String,
            toCollectorName: null == toCollectorName
                ? _value.toCollectorName
                : toCollectorName // ignore: cast_nullable_to_non_nullable
                      as String,
            transferDate: null == transferDate
                ? _value.transferDate
                : transferDate // ignore: cast_nullable_to_non_nullable
                      as String,
            quantityLitres: null == quantityLitres
                ? _value.quantityLitres
                : quantityLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            recordedById: null == recordedById
                ? _value.recordedById
                : recordedById // ignore: cast_nullable_to_non_nullable
                      as int,
            voidedAt: freezed == voidedAt
                ? _value.voidedAt
                : voidedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            lateReason: freezed == lateReason
                ? _value.lateReason
                : lateReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MilkTransferModelImplCopyWith<$Res>
    implements $MilkTransferModelCopyWith<$Res> {
  factory _$$MilkTransferModelImplCopyWith(
    _$MilkTransferModelImpl value,
    $Res Function(_$MilkTransferModelImpl) then,
  ) = __$$MilkTransferModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'from_collector_id') int fromCollectorId,
    @JsonKey(name: 'to_collector_id') int toCollectorId,
    @JsonKey(name: 'from_collector_name') String fromCollectorName,
    @JsonKey(name: 'to_collector_name') String toCollectorName,
    @JsonKey(name: 'transfer_date') String transferDate,
    @JsonKey(name: 'quantity_litres') double quantityLitres,
    String? notes,
    @JsonKey(name: 'recorded_by_id') int recordedById,
    @JsonKey(name: 'voided_at') String? voidedAt,
    @JsonKey(name: 'void_reason') String? voidReason,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'late_reason') String? lateReason,
  });
}

/// @nodoc
class __$$MilkTransferModelImplCopyWithImpl<$Res>
    extends _$MilkTransferModelCopyWithImpl<$Res, _$MilkTransferModelImpl>
    implements _$$MilkTransferModelImplCopyWith<$Res> {
  __$$MilkTransferModelImplCopyWithImpl(
    _$MilkTransferModelImpl _value,
    $Res Function(_$MilkTransferModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MilkTransferModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromCollectorId = null,
    Object? toCollectorId = null,
    Object? fromCollectorName = null,
    Object? toCollectorName = null,
    Object? transferDate = null,
    Object? quantityLitres = null,
    Object? notes = freezed,
    Object? recordedById = null,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? createdAt = freezed,
    Object? lateReason = freezed,
  }) {
    return _then(
      _$MilkTransferModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fromCollectorId: null == fromCollectorId
            ? _value.fromCollectorId
            : fromCollectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        toCollectorId: null == toCollectorId
            ? _value.toCollectorId
            : toCollectorId // ignore: cast_nullable_to_non_nullable
                  as int,
        fromCollectorName: null == fromCollectorName
            ? _value.fromCollectorName
            : fromCollectorName // ignore: cast_nullable_to_non_nullable
                  as String,
        toCollectorName: null == toCollectorName
            ? _value.toCollectorName
            : toCollectorName // ignore: cast_nullable_to_non_nullable
                  as String,
        transferDate: null == transferDate
            ? _value.transferDate
            : transferDate // ignore: cast_nullable_to_non_nullable
                  as String,
        quantityLitres: null == quantityLitres
            ? _value.quantityLitres
            : quantityLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        recordedById: null == recordedById
            ? _value.recordedById
            : recordedById // ignore: cast_nullable_to_non_nullable
                  as int,
        voidedAt: freezed == voidedAt
            ? _value.voidedAt
            : voidedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        lateReason: freezed == lateReason
            ? _value.lateReason
            : lateReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MilkTransferModelImpl extends _MilkTransferModel {
  const _$MilkTransferModelImpl({
    required this.id,
    @JsonKey(name: 'from_collector_id') this.fromCollectorId = 0,
    @JsonKey(name: 'to_collector_id') this.toCollectorId = 0,
    @JsonKey(name: 'from_collector_name') this.fromCollectorName = '',
    @JsonKey(name: 'to_collector_name') this.toCollectorName = '',
    @JsonKey(name: 'transfer_date') required this.transferDate,
    @JsonKey(name: 'quantity_litres') this.quantityLitres = 0.0,
    this.notes,
    @JsonKey(name: 'recorded_by_id') this.recordedById = 0,
    @JsonKey(name: 'voided_at') this.voidedAt,
    @JsonKey(name: 'void_reason') this.voidReason,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'late_reason') this.lateReason,
  }) : super._();

  factory _$MilkTransferModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilkTransferModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'from_collector_id')
  final int fromCollectorId;
  @override
  @JsonKey(name: 'to_collector_id')
  final int toCollectorId;
  @override
  @JsonKey(name: 'from_collector_name')
  final String fromCollectorName;
  @override
  @JsonKey(name: 'to_collector_name')
  final String toCollectorName;
  @override
  @JsonKey(name: 'transfer_date')
  final String transferDate;
  @override
  @JsonKey(name: 'quantity_litres')
  final double quantityLitres;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'recorded_by_id')
  final int recordedById;
  @override
  @JsonKey(name: 'voided_at')
  final String? voidedAt;
  @override
  @JsonKey(name: 'void_reason')
  final String? voidReason;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  // Set when DairyGo support entered the record after its day.
  @override
  @JsonKey(name: 'late_reason')
  final String? lateReason;

  @override
  String toString() {
    return 'MilkTransferModel(id: $id, fromCollectorId: $fromCollectorId, toCollectorId: $toCollectorId, fromCollectorName: $fromCollectorName, toCollectorName: $toCollectorName, transferDate: $transferDate, quantityLitres: $quantityLitres, notes: $notes, recordedById: $recordedById, voidedAt: $voidedAt, voidReason: $voidReason, createdAt: $createdAt, lateReason: $lateReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilkTransferModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromCollectorId, fromCollectorId) ||
                other.fromCollectorId == fromCollectorId) &&
            (identical(other.toCollectorId, toCollectorId) ||
                other.toCollectorId == toCollectorId) &&
            (identical(other.fromCollectorName, fromCollectorName) ||
                other.fromCollectorName == fromCollectorName) &&
            (identical(other.toCollectorName, toCollectorName) ||
                other.toCollectorName == toCollectorName) &&
            (identical(other.transferDate, transferDate) ||
                other.transferDate == transferDate) &&
            (identical(other.quantityLitres, quantityLitres) ||
                other.quantityLitres == quantityLitres) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.recordedById, recordedById) ||
                other.recordedById == recordedById) &&
            (identical(other.voidedAt, voidedAt) ||
                other.voidedAt == voidedAt) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lateReason, lateReason) ||
                other.lateReason == lateReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fromCollectorId,
    toCollectorId,
    fromCollectorName,
    toCollectorName,
    transferDate,
    quantityLitres,
    notes,
    recordedById,
    voidedAt,
    voidReason,
    createdAt,
    lateReason,
  );

  /// Create a copy of MilkTransferModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilkTransferModelImplCopyWith<_$MilkTransferModelImpl> get copyWith =>
      __$$MilkTransferModelImplCopyWithImpl<_$MilkTransferModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MilkTransferModelImplToJson(this);
  }
}

abstract class _MilkTransferModel extends MilkTransferModel {
  const factory _MilkTransferModel({
    required final String id,
    @JsonKey(name: 'from_collector_id') final int fromCollectorId,
    @JsonKey(name: 'to_collector_id') final int toCollectorId,
    @JsonKey(name: 'from_collector_name') final String fromCollectorName,
    @JsonKey(name: 'to_collector_name') final String toCollectorName,
    @JsonKey(name: 'transfer_date') required final String transferDate,
    @JsonKey(name: 'quantity_litres') final double quantityLitres,
    final String? notes,
    @JsonKey(name: 'recorded_by_id') final int recordedById,
    @JsonKey(name: 'voided_at') final String? voidedAt,
    @JsonKey(name: 'void_reason') final String? voidReason,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'late_reason') final String? lateReason,
  }) = _$MilkTransferModelImpl;
  const _MilkTransferModel._() : super._();

  factory _MilkTransferModel.fromJson(Map<String, dynamic> json) =
      _$MilkTransferModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'from_collector_id')
  int get fromCollectorId;
  @override
  @JsonKey(name: 'to_collector_id')
  int get toCollectorId;
  @override
  @JsonKey(name: 'from_collector_name')
  String get fromCollectorName;
  @override
  @JsonKey(name: 'to_collector_name')
  String get toCollectorName;
  @override
  @JsonKey(name: 'transfer_date')
  String get transferDate;
  @override
  @JsonKey(name: 'quantity_litres')
  double get quantityLitres;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'recorded_by_id')
  int get recordedById;
  @override
  @JsonKey(name: 'voided_at')
  String? get voidedAt;
  @override
  @JsonKey(name: 'void_reason')
  String? get voidReason;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt; // Set when DairyGo support entered the record after its day.
  @override
  @JsonKey(name: 'late_reason')
  String? get lateReason;

  /// Create a copy of MilkTransferModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilkTransferModelImplCopyWith<_$MilkTransferModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransferRecipientModel _$TransferRecipientModelFromJson(
  Map<String, dynamic> json,
) {
  return _TransferRecipientModel.fromJson(json);
}

/// @nodoc
mixin _$TransferRecipientModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this TransferRecipientModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransferRecipientModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferRecipientModelCopyWith<TransferRecipientModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferRecipientModelCopyWith<$Res> {
  factory $TransferRecipientModelCopyWith(
    TransferRecipientModel value,
    $Res Function(TransferRecipientModel) then,
  ) = _$TransferRecipientModelCopyWithImpl<$Res, TransferRecipientModel>;
  @useResult
  $Res call({int id, String name, String username});
}

/// @nodoc
class _$TransferRecipientModelCopyWithImpl<
  $Res,
  $Val extends TransferRecipientModel
>
    implements $TransferRecipientModelCopyWith<$Res> {
  _$TransferRecipientModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransferRecipientModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? username = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransferRecipientModelImplCopyWith<$Res>
    implements $TransferRecipientModelCopyWith<$Res> {
  factory _$$TransferRecipientModelImplCopyWith(
    _$TransferRecipientModelImpl value,
    $Res Function(_$TransferRecipientModelImpl) then,
  ) = __$$TransferRecipientModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String username});
}

/// @nodoc
class __$$TransferRecipientModelImplCopyWithImpl<$Res>
    extends
        _$TransferRecipientModelCopyWithImpl<$Res, _$TransferRecipientModelImpl>
    implements _$$TransferRecipientModelImplCopyWith<$Res> {
  __$$TransferRecipientModelImplCopyWithImpl(
    _$TransferRecipientModelImpl _value,
    $Res Function(_$TransferRecipientModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransferRecipientModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? username = null}) {
    return _then(
      _$TransferRecipientModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransferRecipientModelImpl implements _TransferRecipientModel {
  const _$TransferRecipientModelImpl({
    required this.id,
    this.name = '',
    this.username = '',
  });

  factory _$TransferRecipientModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferRecipientModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String username;

  @override
  String toString() {
    return 'TransferRecipientModel(id: $id, name: $name, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferRecipientModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, username);

  /// Create a copy of TransferRecipientModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferRecipientModelImplCopyWith<_$TransferRecipientModelImpl>
  get copyWith =>
      __$$TransferRecipientModelImplCopyWithImpl<_$TransferRecipientModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransferRecipientModelImplToJson(this);
  }
}

abstract class _TransferRecipientModel implements TransferRecipientModel {
  const factory _TransferRecipientModel({
    required final int id,
    final String name,
    final String username,
  }) = _$TransferRecipientModelImpl;

  factory _TransferRecipientModel.fromJson(Map<String, dynamic> json) =
      _$TransferRecipientModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get username;

  /// Create a copy of TransferRecipientModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferRecipientModelImplCopyWith<_$TransferRecipientModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
