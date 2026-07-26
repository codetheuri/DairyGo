// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SaccoProfileModel _$SaccoProfileModelFromJson(Map<String, dynamic> json) {
  return _SaccoProfileModel.fromJson(json);
}

/// @nodoc
mixin _$SaccoProfileModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SaccoProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaccoProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaccoProfileModelCopyWith<SaccoProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaccoProfileModelCopyWith<$Res> {
  factory $SaccoProfileModelCopyWith(
    SaccoProfileModel value,
    $Res Function(SaccoProfileModel) then,
  ) = _$SaccoProfileModelCopyWithImpl<$Res, SaccoProfileModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String code,
    String? email,
    String? phone,
    String? address,
    String status,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$SaccoProfileModelCopyWithImpl<$Res, $Val extends SaccoProfileModel>
    implements $SaccoProfileModelCopyWith<$Res> {
  _$SaccoProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaccoProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? code = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? address = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SaccoProfileModelImplCopyWith<$Res>
    implements $SaccoProfileModelCopyWith<$Res> {
  factory _$$SaccoProfileModelImplCopyWith(
    _$SaccoProfileModelImpl value,
    $Res Function(_$SaccoProfileModelImpl) then,
  ) = __$$SaccoProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String code,
    String? email,
    String? phone,
    String? address,
    String status,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$SaccoProfileModelImplCopyWithImpl<$Res>
    extends _$SaccoProfileModelCopyWithImpl<$Res, _$SaccoProfileModelImpl>
    implements _$$SaccoProfileModelImplCopyWith<$Res> {
  __$$SaccoProfileModelImplCopyWithImpl(
    _$SaccoProfileModelImpl _value,
    $Res Function(_$SaccoProfileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaccoProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? code = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? address = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$SaccoProfileModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SaccoProfileModelImpl implements _SaccoProfileModel {
  const _$SaccoProfileModelImpl({
    required this.id,
    required this.name,
    required this.code,
    this.email,
    this.phone,
    this.address,
    this.status = 'ACTIVE',
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$SaccoProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaccoProfileModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String code;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final String? address;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'SaccoProfileModel(id: $id, name: $name, code: $code, email: $email, phone: $phone, address: $address, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaccoProfileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    code,
    email,
    phone,
    address,
    status,
    createdAt,
  );

  /// Create a copy of SaccoProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaccoProfileModelImplCopyWith<_$SaccoProfileModelImpl> get copyWith =>
      __$$SaccoProfileModelImplCopyWithImpl<_$SaccoProfileModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SaccoProfileModelImplToJson(this);
  }
}

abstract class _SaccoProfileModel implements SaccoProfileModel {
  const factory _SaccoProfileModel({
    required final String id,
    required final String name,
    required final String code,
    final String? email,
    final String? phone,
    final String? address,
    final String status,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$SaccoProfileModelImpl;

  factory _SaccoProfileModel.fromJson(Map<String, dynamic> json) =
      _$SaccoProfileModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get code;
  @override
  String? get email;
  @override
  String? get phone;
  @override
  String? get address;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of SaccoProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaccoProfileModelImplCopyWith<_$SaccoProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SaccoSettingsModel _$SaccoSettingsModelFromJson(Map<String, dynamic> json) {
  return _SaccoSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$SaccoSettingsModel {
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'milk_unit')
  String get milkUnit => throw _privateConstructorUsedError;
  @JsonKey(name: 'morning_cutoff_time')
  String? get morningCutoffTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'evening_cutoff_time')
  String? get eveningCutoffTime => throw _privateConstructorUsedError;

  /// Serializes this SaccoSettingsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaccoSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaccoSettingsModelCopyWith<SaccoSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaccoSettingsModelCopyWith<$Res> {
  factory $SaccoSettingsModelCopyWith(
    SaccoSettingsModel value,
    $Res Function(SaccoSettingsModel) then,
  ) = _$SaccoSettingsModelCopyWithImpl<$Res, SaccoSettingsModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'sacco_id') String saccoId,
    String currency,
    @JsonKey(name: 'milk_unit') String milkUnit,
    @JsonKey(name: 'morning_cutoff_time') String? morningCutoffTime,
    @JsonKey(name: 'evening_cutoff_time') String? eveningCutoffTime,
  });
}

/// @nodoc
class _$SaccoSettingsModelCopyWithImpl<$Res, $Val extends SaccoSettingsModel>
    implements $SaccoSettingsModelCopyWith<$Res> {
  _$SaccoSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaccoSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saccoId = null,
    Object? currency = null,
    Object? milkUnit = null,
    Object? morningCutoffTime = freezed,
    Object? eveningCutoffTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            saccoId: null == saccoId
                ? _value.saccoId
                : saccoId // ignore: cast_nullable_to_non_nullable
                      as String,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            milkUnit: null == milkUnit
                ? _value.milkUnit
                : milkUnit // ignore: cast_nullable_to_non_nullable
                      as String,
            morningCutoffTime: freezed == morningCutoffTime
                ? _value.morningCutoffTime
                : morningCutoffTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            eveningCutoffTime: freezed == eveningCutoffTime
                ? _value.eveningCutoffTime
                : eveningCutoffTime // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SaccoSettingsModelImplCopyWith<$Res>
    implements $SaccoSettingsModelCopyWith<$Res> {
  factory _$$SaccoSettingsModelImplCopyWith(
    _$SaccoSettingsModelImpl value,
    $Res Function(_$SaccoSettingsModelImpl) then,
  ) = __$$SaccoSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'sacco_id') String saccoId,
    String currency,
    @JsonKey(name: 'milk_unit') String milkUnit,
    @JsonKey(name: 'morning_cutoff_time') String? morningCutoffTime,
    @JsonKey(name: 'evening_cutoff_time') String? eveningCutoffTime,
  });
}

/// @nodoc
class __$$SaccoSettingsModelImplCopyWithImpl<$Res>
    extends _$SaccoSettingsModelCopyWithImpl<$Res, _$SaccoSettingsModelImpl>
    implements _$$SaccoSettingsModelImplCopyWith<$Res> {
  __$$SaccoSettingsModelImplCopyWithImpl(
    _$SaccoSettingsModelImpl _value,
    $Res Function(_$SaccoSettingsModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaccoSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saccoId = null,
    Object? currency = null,
    Object? milkUnit = null,
    Object? morningCutoffTime = freezed,
    Object? eveningCutoffTime = freezed,
  }) {
    return _then(
      _$SaccoSettingsModelImpl(
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        milkUnit: null == milkUnit
            ? _value.milkUnit
            : milkUnit // ignore: cast_nullable_to_non_nullable
                  as String,
        morningCutoffTime: freezed == morningCutoffTime
            ? _value.morningCutoffTime
            : morningCutoffTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        eveningCutoffTime: freezed == eveningCutoffTime
            ? _value.eveningCutoffTime
            : eveningCutoffTime // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SaccoSettingsModelImpl implements _SaccoSettingsModel {
  const _$SaccoSettingsModelImpl({
    @JsonKey(name: 'sacco_id') required this.saccoId,
    this.currency = 'KES',
    @JsonKey(name: 'milk_unit') this.milkUnit = 'LITRES',
    @JsonKey(name: 'morning_cutoff_time') this.morningCutoffTime,
    @JsonKey(name: 'evening_cutoff_time') this.eveningCutoffTime,
  });

  factory _$SaccoSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaccoSettingsModelImplFromJson(json);

  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey(name: 'milk_unit')
  final String milkUnit;
  @override
  @JsonKey(name: 'morning_cutoff_time')
  final String? morningCutoffTime;
  @override
  @JsonKey(name: 'evening_cutoff_time')
  final String? eveningCutoffTime;

  @override
  String toString() {
    return 'SaccoSettingsModel(saccoId: $saccoId, currency: $currency, milkUnit: $milkUnit, morningCutoffTime: $morningCutoffTime, eveningCutoffTime: $eveningCutoffTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaccoSettingsModelImpl &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.milkUnit, milkUnit) ||
                other.milkUnit == milkUnit) &&
            (identical(other.morningCutoffTime, morningCutoffTime) ||
                other.morningCutoffTime == morningCutoffTime) &&
            (identical(other.eveningCutoffTime, eveningCutoffTime) ||
                other.eveningCutoffTime == eveningCutoffTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    saccoId,
    currency,
    milkUnit,
    morningCutoffTime,
    eveningCutoffTime,
  );

  /// Create a copy of SaccoSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaccoSettingsModelImplCopyWith<_$SaccoSettingsModelImpl> get copyWith =>
      __$$SaccoSettingsModelImplCopyWithImpl<_$SaccoSettingsModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SaccoSettingsModelImplToJson(this);
  }
}

abstract class _SaccoSettingsModel implements SaccoSettingsModel {
  const factory _SaccoSettingsModel({
    @JsonKey(name: 'sacco_id') required final String saccoId,
    final String currency,
    @JsonKey(name: 'milk_unit') final String milkUnit,
    @JsonKey(name: 'morning_cutoff_time') final String? morningCutoffTime,
    @JsonKey(name: 'evening_cutoff_time') final String? eveningCutoffTime,
  }) = _$SaccoSettingsModelImpl;

  factory _SaccoSettingsModel.fromJson(Map<String, dynamic> json) =
      _$SaccoSettingsModelImpl.fromJson;

  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  String get currency;
  @override
  @JsonKey(name: 'milk_unit')
  String get milkUnit;
  @override
  @JsonKey(name: 'morning_cutoff_time')
  String? get morningCutoffTime;
  @override
  @JsonKey(name: 'evening_cutoff_time')
  String? get eveningCutoffTime;

  /// Create a copy of SaccoSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaccoSettingsModelImplCopyWith<_$SaccoSettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SetPriceRequestModel _$SetPriceRequestModelFromJson(Map<String, dynamic> json) {
  return _SetPriceRequestModel.fromJson(json);
}

/// @nodoc
mixin _$SetPriceRequestModel {
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre => throw _privateConstructorUsedError;
  @JsonKey(name: 'effective_date')
  String? get effectiveDate => throw _privateConstructorUsedError;

  /// Serializes this SetPriceRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SetPriceRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SetPriceRequestModelCopyWith<SetPriceRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetPriceRequestModelCopyWith<$Res> {
  factory $SetPriceRequestModelCopyWith(
    SetPriceRequestModel value,
    $Res Function(SetPriceRequestModel) then,
  ) = _$SetPriceRequestModelCopyWithImpl<$Res, SetPriceRequestModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
  });
}

/// @nodoc
class _$SetPriceRequestModelCopyWithImpl<
  $Res,
  $Val extends SetPriceRequestModel
>
    implements $SetPriceRequestModelCopyWith<$Res> {
  _$SetPriceRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SetPriceRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pricePerLitre = null, Object? effectiveDate = freezed}) {
    return _then(
      _value.copyWith(
            pricePerLitre: null == pricePerLitre
                ? _value.pricePerLitre
                : pricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double,
            effectiveDate: freezed == effectiveDate
                ? _value.effectiveDate
                : effectiveDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SetPriceRequestModelImplCopyWith<$Res>
    implements $SetPriceRequestModelCopyWith<$Res> {
  factory _$$SetPriceRequestModelImplCopyWith(
    _$SetPriceRequestModelImpl value,
    $Res Function(_$SetPriceRequestModelImpl) then,
  ) = __$$SetPriceRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'price_per_litre') double pricePerLitre,
    @JsonKey(name: 'effective_date') String? effectiveDate,
  });
}

/// @nodoc
class __$$SetPriceRequestModelImplCopyWithImpl<$Res>
    extends _$SetPriceRequestModelCopyWithImpl<$Res, _$SetPriceRequestModelImpl>
    implements _$$SetPriceRequestModelImplCopyWith<$Res> {
  __$$SetPriceRequestModelImplCopyWithImpl(
    _$SetPriceRequestModelImpl _value,
    $Res Function(_$SetPriceRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SetPriceRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pricePerLitre = null, Object? effectiveDate = freezed}) {
    return _then(
      _$SetPriceRequestModelImpl(
        pricePerLitre: null == pricePerLitre
            ? _value.pricePerLitre
            : pricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double,
        effectiveDate: freezed == effectiveDate
            ? _value.effectiveDate
            : effectiveDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SetPriceRequestModelImpl implements _SetPriceRequestModel {
  const _$SetPriceRequestModelImpl({
    @JsonKey(name: 'price_per_litre') required this.pricePerLitre,
    @JsonKey(name: 'effective_date') this.effectiveDate,
  });

  factory _$SetPriceRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetPriceRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;
  @override
  @JsonKey(name: 'effective_date')
  final String? effectiveDate;

  @override
  String toString() {
    return 'SetPriceRequestModel(pricePerLitre: $pricePerLitre, effectiveDate: $effectiveDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetPriceRequestModelImpl &&
            (identical(other.pricePerLitre, pricePerLitre) ||
                other.pricePerLitre == pricePerLitre) &&
            (identical(other.effectiveDate, effectiveDate) ||
                other.effectiveDate == effectiveDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pricePerLitre, effectiveDate);

  /// Create a copy of SetPriceRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetPriceRequestModelImplCopyWith<_$SetPriceRequestModelImpl>
  get copyWith =>
      __$$SetPriceRequestModelImplCopyWithImpl<_$SetPriceRequestModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SetPriceRequestModelImplToJson(this);
  }
}

abstract class _SetPriceRequestModel implements SetPriceRequestModel {
  const factory _SetPriceRequestModel({
    @JsonKey(name: 'price_per_litre') required final double pricePerLitre,
    @JsonKey(name: 'effective_date') final String? effectiveDate,
  }) = _$SetPriceRequestModelImpl;

  factory _SetPriceRequestModel.fromJson(Map<String, dynamic> json) =
      _$SetPriceRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'price_per_litre')
  double get pricePerLitre;
  @override
  @JsonKey(name: 'effective_date')
  String? get effectiveDate;

  /// Create a copy of SetPriceRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetPriceRequestModelImplCopyWith<_$SetPriceRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
