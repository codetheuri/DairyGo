// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomerModel _$CustomerModelFromJson(Map<String, dynamic> json) {
  return _CustomerModel.fromJson(json);
}

/// @nodoc
mixin _$CustomerModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_type')
  String get customerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_price_per_litre')
  double? get defaultPricePerLitre => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  double? get balance => throw _privateConstructorUsedError;

  /// Serializes this CustomerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerModelCopyWith<CustomerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerModelCopyWith<$Res> {
  factory $CustomerModelCopyWith(
    CustomerModel value,
    $Res Function(CustomerModel) then,
  ) = _$CustomerModelCopyWithImpl<$Res, CustomerModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    String status,
    String? notes,
    double? balance,
  });
}

/// @nodoc
class _$CustomerModelCopyWithImpl<$Res, $Val extends CustomerModel>
    implements $CustomerModelCopyWith<$Res> {
  _$CustomerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? defaultPricePerLitre = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? balance = freezed,
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
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerType: null == customerType
                ? _value.customerType
                : customerType // ignore: cast_nullable_to_non_nullable
                      as String,
            defaultPricePerLitre: freezed == defaultPricePerLitre
                ? _value.defaultPricePerLitre
                : defaultPricePerLitre // ignore: cast_nullable_to_non_nullable
                      as double?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            balance: freezed == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerModelImplCopyWith<$Res>
    implements $CustomerModelCopyWith<$Res> {
  factory _$$CustomerModelImplCopyWith(
    _$CustomerModelImpl value,
    $Res Function(_$CustomerModelImpl) then,
  ) = __$$CustomerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    String status,
    String? notes,
    double? balance,
  });
}

/// @nodoc
class __$$CustomerModelImplCopyWithImpl<$Res>
    extends _$CustomerModelCopyWithImpl<$Res, _$CustomerModelImpl>
    implements _$$CustomerModelImplCopyWith<$Res> {
  __$$CustomerModelImplCopyWithImpl(
    _$CustomerModelImpl _value,
    $Res Function(_$CustomerModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? defaultPricePerLitre = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? balance = freezed,
  }) {
    return _then(
      _$CustomerModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerType: null == customerType
            ? _value.customerType
            : customerType // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultPricePerLitre: freezed == defaultPricePerLitre
            ? _value.defaultPricePerLitre
            : defaultPricePerLitre // ignore: cast_nullable_to_non_nullable
                  as double?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        balance: freezed == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerModelImpl extends _CustomerModel {
  const _$CustomerModelImpl({
    required this.id,
    required this.name,
    this.phone,
    @JsonKey(name: 'customer_type') this.customerType = 'OTHER',
    @JsonKey(name: 'default_price_per_litre') this.defaultPricePerLitre,
    this.status = 'ACTIVE',
    this.notes,
    this.balance,
  }) : super._();

  factory _$CustomerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'customer_type')
  final String customerType;
  @override
  @JsonKey(name: 'default_price_per_litre')
  final double? defaultPricePerLitre;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  @override
  final double? balance;

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, phone: $phone, customerType: $customerType, defaultPricePerLitre: $defaultPricePerLitre, status: $status, notes: $notes, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.customerType, customerType) ||
                other.customerType == customerType) &&
            (identical(other.defaultPricePerLitre, defaultPricePerLitre) ||
                other.defaultPricePerLitre == defaultPricePerLitre) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.balance, balance) || other.balance == balance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    phone,
    customerType,
    defaultPricePerLitre,
    status,
    notes,
    balance,
  );

  /// Create a copy of CustomerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerModelImplCopyWith<_$CustomerModelImpl> get copyWith =>
      __$$CustomerModelImplCopyWithImpl<_$CustomerModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerModelImplToJson(this);
  }
}

abstract class _CustomerModel extends CustomerModel {
  const factory _CustomerModel({
    required final String id,
    required final String name,
    final String? phone,
    @JsonKey(name: 'customer_type') final String customerType,
    @JsonKey(name: 'default_price_per_litre')
    final double? defaultPricePerLitre,
    final String status,
    final String? notes,
    final double? balance,
  }) = _$CustomerModelImpl;
  const _CustomerModel._() : super._();

  factory _CustomerModel.fromJson(Map<String, dynamic> json) =
      _$CustomerModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'customer_type')
  String get customerType;
  @override
  @JsonKey(name: 'default_price_per_litre')
  double? get defaultPricePerLitre;
  @override
  String get status;
  @override
  String? get notes;
  @override
  double? get balance;

  /// Create a copy of CustomerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerModelImplCopyWith<_$CustomerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateCustomerRequestModel _$CreateCustomerRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _CreateCustomerRequestModel.fromJson(json);
}

/// @nodoc
mixin _$CreateCustomerRequestModel {
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_type')
  String get customerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_price_per_litre')
  double? get defaultPricePerLitre => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this CreateCustomerRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateCustomerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateCustomerRequestModelCopyWith<CreateCustomerRequestModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateCustomerRequestModelCopyWith<$Res> {
  factory $CreateCustomerRequestModelCopyWith(
    CreateCustomerRequestModel value,
    $Res Function(CreateCustomerRequestModel) then,
  ) =
      _$CreateCustomerRequestModelCopyWithImpl<
        $Res,
        CreateCustomerRequestModel
      >;
  @useResult
  $Res call({
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    String? notes,
  });
}

/// @nodoc
class _$CreateCustomerRequestModelCopyWithImpl<
  $Res,
  $Val extends CreateCustomerRequestModel
>
    implements $CreateCustomerRequestModelCopyWith<$Res> {
  _$CreateCustomerRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateCustomerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? defaultPricePerLitre = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerType: null == customerType
                ? _value.customerType
                : customerType // ignore: cast_nullable_to_non_nullable
                      as String,
            defaultPricePerLitre: freezed == defaultPricePerLitre
                ? _value.defaultPricePerLitre
                : defaultPricePerLitre // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CreateCustomerRequestModelImplCopyWith<$Res>
    implements $CreateCustomerRequestModelCopyWith<$Res> {
  factory _$$CreateCustomerRequestModelImplCopyWith(
    _$CreateCustomerRequestModelImpl value,
    $Res Function(_$CreateCustomerRequestModelImpl) then,
  ) = __$$CreateCustomerRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'default_price_per_litre') double? defaultPricePerLitre,
    String? notes,
  });
}

/// @nodoc
class __$$CreateCustomerRequestModelImplCopyWithImpl<$Res>
    extends
        _$CreateCustomerRequestModelCopyWithImpl<
          $Res,
          _$CreateCustomerRequestModelImpl
        >
    implements _$$CreateCustomerRequestModelImplCopyWith<$Res> {
  __$$CreateCustomerRequestModelImplCopyWithImpl(
    _$CreateCustomerRequestModelImpl _value,
    $Res Function(_$CreateCustomerRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateCustomerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? defaultPricePerLitre = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$CreateCustomerRequestModelImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerType: null == customerType
            ? _value.customerType
            : customerType // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultPricePerLitre: freezed == defaultPricePerLitre
            ? _value.defaultPricePerLitre
            : defaultPricePerLitre // ignore: cast_nullable_to_non_nullable
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
class _$CreateCustomerRequestModelImpl implements _CreateCustomerRequestModel {
  const _$CreateCustomerRequestModelImpl({
    required this.name,
    this.phone,
    @JsonKey(name: 'customer_type') this.customerType = 'OTHER',
    @JsonKey(name: 'default_price_per_litre') this.defaultPricePerLitre,
    this.notes,
  });

  factory _$CreateCustomerRequestModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$CreateCustomerRequestModelImplFromJson(json);

  @override
  final String name;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'customer_type')
  final String customerType;
  @override
  @JsonKey(name: 'default_price_per_litre')
  final double? defaultPricePerLitre;
  @override
  final String? notes;

  @override
  String toString() {
    return 'CreateCustomerRequestModel(name: $name, phone: $phone, customerType: $customerType, defaultPricePerLitre: $defaultPricePerLitre, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateCustomerRequestModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.customerType, customerType) ||
                other.customerType == customerType) &&
            (identical(other.defaultPricePerLitre, defaultPricePerLitre) ||
                other.defaultPricePerLitre == defaultPricePerLitre) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    phone,
    customerType,
    defaultPricePerLitre,
    notes,
  );

  /// Create a copy of CreateCustomerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateCustomerRequestModelImplCopyWith<_$CreateCustomerRequestModelImpl>
  get copyWith =>
      __$$CreateCustomerRequestModelImplCopyWithImpl<
        _$CreateCustomerRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateCustomerRequestModelImplToJson(this);
  }
}

abstract class _CreateCustomerRequestModel
    implements CreateCustomerRequestModel {
  const factory _CreateCustomerRequestModel({
    required final String name,
    final String? phone,
    @JsonKey(name: 'customer_type') final String customerType,
    @JsonKey(name: 'default_price_per_litre')
    final double? defaultPricePerLitre,
    final String? notes,
  }) = _$CreateCustomerRequestModelImpl;

  factory _CreateCustomerRequestModel.fromJson(Map<String, dynamic> json) =
      _$CreateCustomerRequestModelImpl.fromJson;

  @override
  String get name;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'customer_type')
  String get customerType;
  @override
  @JsonKey(name: 'default_price_per_litre')
  double? get defaultPricePerLitre;
  @override
  String? get notes;

  /// Create a copy of CreateCustomerRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateCustomerRequestModelImplCopyWith<_$CreateCustomerRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

StatementLineModel _$StatementLineModelFromJson(Map<String, dynamic> json) {
  return _StatementLineModel.fromJson(json);
}

/// @nodoc
mixin _$StatementLineModel {
  String get kind => throw _privateConstructorUsedError;
  @JsonKey(name: 'reference_id')
  String get referenceId => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get litres => throw _privateConstructorUsedError;
  double get debit => throw _privateConstructorUsedError;
  double get credit => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;

  /// Serializes this StatementLineModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StatementLineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatementLineModelCopyWith<StatementLineModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatementLineModelCopyWith<$Res> {
  factory $StatementLineModelCopyWith(
    StatementLineModel value,
    $Res Function(StatementLineModel) then,
  ) = _$StatementLineModelCopyWithImpl<$Res, StatementLineModel>;
  @useResult
  $Res call({
    String kind,
    @JsonKey(name: 'reference_id') String referenceId,
    String date,
    String description,
    double litres,
    double debit,
    double credit,
    double balance,
  });
}

/// @nodoc
class _$StatementLineModelCopyWithImpl<$Res, $Val extends StatementLineModel>
    implements $StatementLineModelCopyWith<$Res> {
  _$StatementLineModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StatementLineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? referenceId = null,
    Object? date = null,
    Object? description = null,
    Object? litres = null,
    Object? debit = null,
    Object? credit = null,
    Object? balance = null,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            referenceId: null == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            litres: null == litres
                ? _value.litres
                : litres // ignore: cast_nullable_to_non_nullable
                      as double,
            debit: null == debit
                ? _value.debit
                : debit // ignore: cast_nullable_to_non_nullable
                      as double,
            credit: null == credit
                ? _value.credit
                : credit // ignore: cast_nullable_to_non_nullable
                      as double,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StatementLineModelImplCopyWith<$Res>
    implements $StatementLineModelCopyWith<$Res> {
  factory _$$StatementLineModelImplCopyWith(
    _$StatementLineModelImpl value,
    $Res Function(_$StatementLineModelImpl) then,
  ) = __$$StatementLineModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String kind,
    @JsonKey(name: 'reference_id') String referenceId,
    String date,
    String description,
    double litres,
    double debit,
    double credit,
    double balance,
  });
}

/// @nodoc
class __$$StatementLineModelImplCopyWithImpl<$Res>
    extends _$StatementLineModelCopyWithImpl<$Res, _$StatementLineModelImpl>
    implements _$$StatementLineModelImplCopyWith<$Res> {
  __$$StatementLineModelImplCopyWithImpl(
    _$StatementLineModelImpl _value,
    $Res Function(_$StatementLineModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StatementLineModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? referenceId = null,
    Object? date = null,
    Object? description = null,
    Object? litres = null,
    Object? debit = null,
    Object? credit = null,
    Object? balance = null,
  }) {
    return _then(
      _$StatementLineModelImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        referenceId: null == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        litres: null == litres
            ? _value.litres
            : litres // ignore: cast_nullable_to_non_nullable
                  as double,
        debit: null == debit
            ? _value.debit
            : debit // ignore: cast_nullable_to_non_nullable
                  as double,
        credit: null == credit
            ? _value.credit
            : credit // ignore: cast_nullable_to_non_nullable
                  as double,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StatementLineModelImpl implements _StatementLineModel {
  const _$StatementLineModelImpl({
    this.kind = 'SALE',
    @JsonKey(name: 'reference_id') this.referenceId = '',
    this.date = '',
    this.description = '',
    this.litres = 0.0,
    this.debit = 0.0,
    this.credit = 0.0,
    this.balance = 0.0,
  });

  factory _$StatementLineModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatementLineModelImplFromJson(json);

  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey(name: 'reference_id')
  final String referenceId;
  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final double litres;
  @override
  @JsonKey()
  final double debit;
  @override
  @JsonKey()
  final double credit;
  @override
  @JsonKey()
  final double balance;

  @override
  String toString() {
    return 'StatementLineModel(kind: $kind, referenceId: $referenceId, date: $date, description: $description, litres: $litres, debit: $debit, credit: $credit, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatementLineModelImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.litres, litres) || other.litres == litres) &&
            (identical(other.debit, debit) || other.debit == debit) &&
            (identical(other.credit, credit) || other.credit == credit) &&
            (identical(other.balance, balance) || other.balance == balance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    kind,
    referenceId,
    date,
    description,
    litres,
    debit,
    credit,
    balance,
  );

  /// Create a copy of StatementLineModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatementLineModelImplCopyWith<_$StatementLineModelImpl> get copyWith =>
      __$$StatementLineModelImplCopyWithImpl<_$StatementLineModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StatementLineModelImplToJson(this);
  }
}

abstract class _StatementLineModel implements StatementLineModel {
  const factory _StatementLineModel({
    final String kind,
    @JsonKey(name: 'reference_id') final String referenceId,
    final String date,
    final String description,
    final double litres,
    final double debit,
    final double credit,
    final double balance,
  }) = _$StatementLineModelImpl;

  factory _StatementLineModel.fromJson(Map<String, dynamic> json) =
      _$StatementLineModelImpl.fromJson;

  @override
  String get kind;
  @override
  @JsonKey(name: 'reference_id')
  String get referenceId;
  @override
  String get date;
  @override
  String get description;
  @override
  double get litres;
  @override
  double get debit;
  @override
  double get credit;
  @override
  double get balance;

  /// Create a copy of StatementLineModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatementLineModelImplCopyWith<_$StatementLineModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerStatementModel _$CustomerStatementModelFromJson(
  Map<String, dynamic> json,
) {
  return _CustomerStatementModel.fromJson(json);
}

/// @nodoc
mixin _$CustomerStatementModel {
  CustomerModel get customer => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_date')
  String get fromDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_date')
  String get toDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'opening_balance')
  double get openingBalance => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_debit')
  double get totalDebit => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_credit')
  double get totalCredit => throw _privateConstructorUsedError;
  @JsonKey(name: 'closing_balance')
  double get closingBalance => throw _privateConstructorUsedError;
  List<StatementLineModel> get lines => throw _privateConstructorUsedError;

  /// Serializes this CustomerStatementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerStatementModelCopyWith<CustomerStatementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerStatementModelCopyWith<$Res> {
  factory $CustomerStatementModelCopyWith(
    CustomerStatementModel value,
    $Res Function(CustomerStatementModel) then,
  ) = _$CustomerStatementModelCopyWithImpl<$Res, CustomerStatementModel>;
  @useResult
  $Res call({
    CustomerModel customer,
    @JsonKey(name: 'from_date') String fromDate,
    @JsonKey(name: 'to_date') String toDate,
    @JsonKey(name: 'opening_balance') double openingBalance,
    @JsonKey(name: 'total_debit') double totalDebit,
    @JsonKey(name: 'total_credit') double totalCredit,
    @JsonKey(name: 'closing_balance') double closingBalance,
    List<StatementLineModel> lines,
  });

  $CustomerModelCopyWith<$Res> get customer;
}

/// @nodoc
class _$CustomerStatementModelCopyWithImpl<
  $Res,
  $Val extends CustomerStatementModel
>
    implements $CustomerStatementModelCopyWith<$Res> {
  _$CustomerStatementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customer = null,
    Object? fromDate = null,
    Object? toDate = null,
    Object? openingBalance = null,
    Object? totalDebit = null,
    Object? totalCredit = null,
    Object? closingBalance = null,
    Object? lines = null,
  }) {
    return _then(
      _value.copyWith(
            customer: null == customer
                ? _value.customer
                : customer // ignore: cast_nullable_to_non_nullable
                      as CustomerModel,
            fromDate: null == fromDate
                ? _value.fromDate
                : fromDate // ignore: cast_nullable_to_non_nullable
                      as String,
            toDate: null == toDate
                ? _value.toDate
                : toDate // ignore: cast_nullable_to_non_nullable
                      as String,
            openingBalance: null == openingBalance
                ? _value.openingBalance
                : openingBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            totalDebit: null == totalDebit
                ? _value.totalDebit
                : totalDebit // ignore: cast_nullable_to_non_nullable
                      as double,
            totalCredit: null == totalCredit
                ? _value.totalCredit
                : totalCredit // ignore: cast_nullable_to_non_nullable
                      as double,
            closingBalance: null == closingBalance
                ? _value.closingBalance
                : closingBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            lines: null == lines
                ? _value.lines
                : lines // ignore: cast_nullable_to_non_nullable
                      as List<StatementLineModel>,
          )
          as $Val,
    );
  }

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomerModelCopyWith<$Res> get customer {
    return $CustomerModelCopyWith<$Res>(_value.customer, (value) {
      return _then(_value.copyWith(customer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CustomerStatementModelImplCopyWith<$Res>
    implements $CustomerStatementModelCopyWith<$Res> {
  factory _$$CustomerStatementModelImplCopyWith(
    _$CustomerStatementModelImpl value,
    $Res Function(_$CustomerStatementModelImpl) then,
  ) = __$$CustomerStatementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CustomerModel customer,
    @JsonKey(name: 'from_date') String fromDate,
    @JsonKey(name: 'to_date') String toDate,
    @JsonKey(name: 'opening_balance') double openingBalance,
    @JsonKey(name: 'total_debit') double totalDebit,
    @JsonKey(name: 'total_credit') double totalCredit,
    @JsonKey(name: 'closing_balance') double closingBalance,
    List<StatementLineModel> lines,
  });

  @override
  $CustomerModelCopyWith<$Res> get customer;
}

/// @nodoc
class __$$CustomerStatementModelImplCopyWithImpl<$Res>
    extends
        _$CustomerStatementModelCopyWithImpl<$Res, _$CustomerStatementModelImpl>
    implements _$$CustomerStatementModelImplCopyWith<$Res> {
  __$$CustomerStatementModelImplCopyWithImpl(
    _$CustomerStatementModelImpl _value,
    $Res Function(_$CustomerStatementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customer = null,
    Object? fromDate = null,
    Object? toDate = null,
    Object? openingBalance = null,
    Object? totalDebit = null,
    Object? totalCredit = null,
    Object? closingBalance = null,
    Object? lines = null,
  }) {
    return _then(
      _$CustomerStatementModelImpl(
        customer: null == customer
            ? _value.customer
            : customer // ignore: cast_nullable_to_non_nullable
                  as CustomerModel,
        fromDate: null == fromDate
            ? _value.fromDate
            : fromDate // ignore: cast_nullable_to_non_nullable
                  as String,
        toDate: null == toDate
            ? _value.toDate
            : toDate // ignore: cast_nullable_to_non_nullable
                  as String,
        openingBalance: null == openingBalance
            ? _value.openingBalance
            : openingBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        totalDebit: null == totalDebit
            ? _value.totalDebit
            : totalDebit // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCredit: null == totalCredit
            ? _value.totalCredit
            : totalCredit // ignore: cast_nullable_to_non_nullable
                  as double,
        closingBalance: null == closingBalance
            ? _value.closingBalance
            : closingBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        lines: null == lines
            ? _value._lines
            : lines // ignore: cast_nullable_to_non_nullable
                  as List<StatementLineModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerStatementModelImpl implements _CustomerStatementModel {
  const _$CustomerStatementModelImpl({
    required this.customer,
    @JsonKey(name: 'from_date') this.fromDate = '',
    @JsonKey(name: 'to_date') this.toDate = '',
    @JsonKey(name: 'opening_balance') this.openingBalance = 0.0,
    @JsonKey(name: 'total_debit') this.totalDebit = 0.0,
    @JsonKey(name: 'total_credit') this.totalCredit = 0.0,
    @JsonKey(name: 'closing_balance') this.closingBalance = 0.0,
    final List<StatementLineModel> lines = const [],
  }) : _lines = lines;

  factory _$CustomerStatementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerStatementModelImplFromJson(json);

  @override
  final CustomerModel customer;
  @override
  @JsonKey(name: 'from_date')
  final String fromDate;
  @override
  @JsonKey(name: 'to_date')
  final String toDate;
  @override
  @JsonKey(name: 'opening_balance')
  final double openingBalance;
  @override
  @JsonKey(name: 'total_debit')
  final double totalDebit;
  @override
  @JsonKey(name: 'total_credit')
  final double totalCredit;
  @override
  @JsonKey(name: 'closing_balance')
  final double closingBalance;
  final List<StatementLineModel> _lines;
  @override
  @JsonKey()
  List<StatementLineModel> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'CustomerStatementModel(customer: $customer, fromDate: $fromDate, toDate: $toDate, openingBalance: $openingBalance, totalDebit: $totalDebit, totalCredit: $totalCredit, closingBalance: $closingBalance, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerStatementModelImpl &&
            (identical(other.customer, customer) ||
                other.customer == customer) &&
            (identical(other.fromDate, fromDate) ||
                other.fromDate == fromDate) &&
            (identical(other.toDate, toDate) || other.toDate == toDate) &&
            (identical(other.openingBalance, openingBalance) ||
                other.openingBalance == openingBalance) &&
            (identical(other.totalDebit, totalDebit) ||
                other.totalDebit == totalDebit) &&
            (identical(other.totalCredit, totalCredit) ||
                other.totalCredit == totalCredit) &&
            (identical(other.closingBalance, closingBalance) ||
                other.closingBalance == closingBalance) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    customer,
    fromDate,
    toDate,
    openingBalance,
    totalDebit,
    totalCredit,
    closingBalance,
    const DeepCollectionEquality().hash(_lines),
  );

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerStatementModelImplCopyWith<_$CustomerStatementModelImpl>
  get copyWith =>
      __$$CustomerStatementModelImplCopyWithImpl<_$CustomerStatementModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerStatementModelImplToJson(this);
  }
}

abstract class _CustomerStatementModel implements CustomerStatementModel {
  const factory _CustomerStatementModel({
    required final CustomerModel customer,
    @JsonKey(name: 'from_date') final String fromDate,
    @JsonKey(name: 'to_date') final String toDate,
    @JsonKey(name: 'opening_balance') final double openingBalance,
    @JsonKey(name: 'total_debit') final double totalDebit,
    @JsonKey(name: 'total_credit') final double totalCredit,
    @JsonKey(name: 'closing_balance') final double closingBalance,
    final List<StatementLineModel> lines,
  }) = _$CustomerStatementModelImpl;

  factory _CustomerStatementModel.fromJson(Map<String, dynamic> json) =
      _$CustomerStatementModelImpl.fromJson;

  @override
  CustomerModel get customer;
  @override
  @JsonKey(name: 'from_date')
  String get fromDate;
  @override
  @JsonKey(name: 'to_date')
  String get toDate;
  @override
  @JsonKey(name: 'opening_balance')
  double get openingBalance;
  @override
  @JsonKey(name: 'total_debit')
  double get totalDebit;
  @override
  @JsonKey(name: 'total_credit')
  double get totalCredit;
  @override
  @JsonKey(name: 'closing_balance')
  double get closingBalance;
  @override
  List<StatementLineModel> get lines;

  /// Create a copy of CustomerStatementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerStatementModelImplCopyWith<_$CustomerStatementModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CustomerBalanceModel _$CustomerBalanceModelFromJson(Map<String, dynamic> json) {
  return _CustomerBalanceModel.fromJson(json);
}

/// @nodoc
mixin _$CustomerBalanceModel {
  @JsonKey(name: 'customer_id')
  String get customerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_type')
  String get customerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sales')
  double get totalSales => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_paid')
  double get totalPaid => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;

  /// Serializes this CustomerBalanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerBalanceModelCopyWith<CustomerBalanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerBalanceModelCopyWith<$Res> {
  factory $CustomerBalanceModelCopyWith(
    CustomerBalanceModel value,
    $Res Function(CustomerBalanceModel) then,
  ) = _$CustomerBalanceModelCopyWithImpl<$Res, CustomerBalanceModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'customer_id') String customerId,
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'total_sales') double totalSales,
    @JsonKey(name: 'total_paid') double totalPaid,
    double balance,
  });
}

/// @nodoc
class _$CustomerBalanceModelCopyWithImpl<
  $Res,
  $Val extends CustomerBalanceModel
>
    implements $CustomerBalanceModelCopyWith<$Res> {
  _$CustomerBalanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? totalSales = null,
    Object? totalPaid = null,
    Object? balance = null,
  }) {
    return _then(
      _value.copyWith(
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerType: null == customerType
                ? _value.customerType
                : customerType // ignore: cast_nullable_to_non_nullable
                      as String,
            totalSales: null == totalSales
                ? _value.totalSales
                : totalSales // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPaid: null == totalPaid
                ? _value.totalPaid
                : totalPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerBalanceModelImplCopyWith<$Res>
    implements $CustomerBalanceModelCopyWith<$Res> {
  factory _$$CustomerBalanceModelImplCopyWith(
    _$CustomerBalanceModelImpl value,
    $Res Function(_$CustomerBalanceModelImpl) then,
  ) = __$$CustomerBalanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'customer_id') String customerId,
    String name,
    String? phone,
    @JsonKey(name: 'customer_type') String customerType,
    @JsonKey(name: 'total_sales') double totalSales,
    @JsonKey(name: 'total_paid') double totalPaid,
    double balance,
  });
}

/// @nodoc
class __$$CustomerBalanceModelImplCopyWithImpl<$Res>
    extends _$CustomerBalanceModelCopyWithImpl<$Res, _$CustomerBalanceModelImpl>
    implements _$$CustomerBalanceModelImplCopyWith<$Res> {
  __$$CustomerBalanceModelImplCopyWithImpl(
    _$CustomerBalanceModelImpl _value,
    $Res Function(_$CustomerBalanceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? name = null,
    Object? phone = freezed,
    Object? customerType = null,
    Object? totalSales = null,
    Object? totalPaid = null,
    Object? balance = null,
  }) {
    return _then(
      _$CustomerBalanceModelImpl(
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerType: null == customerType
            ? _value.customerType
            : customerType // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSales: null == totalSales
            ? _value.totalSales
            : totalSales // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPaid: null == totalPaid
            ? _value.totalPaid
            : totalPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerBalanceModelImpl implements _CustomerBalanceModel {
  const _$CustomerBalanceModelImpl({
    @JsonKey(name: 'customer_id') required this.customerId,
    required this.name,
    this.phone,
    @JsonKey(name: 'customer_type') this.customerType = 'OTHER',
    @JsonKey(name: 'total_sales') this.totalSales = 0.0,
    @JsonKey(name: 'total_paid') this.totalPaid = 0.0,
    this.balance = 0.0,
  });

  factory _$CustomerBalanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerBalanceModelImplFromJson(json);

  @override
  @JsonKey(name: 'customer_id')
  final String customerId;
  @override
  final String name;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'customer_type')
  final String customerType;
  @override
  @JsonKey(name: 'total_sales')
  final double totalSales;
  @override
  @JsonKey(name: 'total_paid')
  final double totalPaid;
  @override
  @JsonKey()
  final double balance;

  @override
  String toString() {
    return 'CustomerBalanceModel(customerId: $customerId, name: $name, phone: $phone, customerType: $customerType, totalSales: $totalSales, totalPaid: $totalPaid, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerBalanceModelImpl &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.customerType, customerType) ||
                other.customerType == customerType) &&
            (identical(other.totalSales, totalSales) ||
                other.totalSales == totalSales) &&
            (identical(other.totalPaid, totalPaid) ||
                other.totalPaid == totalPaid) &&
            (identical(other.balance, balance) || other.balance == balance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    customerId,
    name,
    phone,
    customerType,
    totalSales,
    totalPaid,
    balance,
  );

  /// Create a copy of CustomerBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerBalanceModelImplCopyWith<_$CustomerBalanceModelImpl>
  get copyWith =>
      __$$CustomerBalanceModelImplCopyWithImpl<_$CustomerBalanceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerBalanceModelImplToJson(this);
  }
}

abstract class _CustomerBalanceModel implements CustomerBalanceModel {
  const factory _CustomerBalanceModel({
    @JsonKey(name: 'customer_id') required final String customerId,
    required final String name,
    final String? phone,
    @JsonKey(name: 'customer_type') final String customerType,
    @JsonKey(name: 'total_sales') final double totalSales,
    @JsonKey(name: 'total_paid') final double totalPaid,
    final double balance,
  }) = _$CustomerBalanceModelImpl;

  factory _CustomerBalanceModel.fromJson(Map<String, dynamic> json) =
      _$CustomerBalanceModelImpl.fromJson;

  @override
  @JsonKey(name: 'customer_id')
  String get customerId;
  @override
  String get name;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'customer_type')
  String get customerType;
  @override
  @JsonKey(name: 'total_sales')
  double get totalSales;
  @override
  @JsonKey(name: 'total_paid')
  double get totalPaid;
  @override
  double get balance;

  /// Create a copy of CustomerBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerBalanceModelImplCopyWith<_$CustomerBalanceModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RecordPaymentRequestModel _$RecordPaymentRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _RecordPaymentRequestModel.fromJson(json);
}

/// @nodoc
mixin _$RecordPaymentRequestModel {
  double get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_date')
  String? get paymentDate => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String? get reference => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this RecordPaymentRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordPaymentRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordPaymentRequestModelCopyWith<RecordPaymentRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordPaymentRequestModelCopyWith<$Res> {
  factory $RecordPaymentRequestModelCopyWith(
    RecordPaymentRequestModel value,
    $Res Function(RecordPaymentRequestModel) then,
  ) = _$RecordPaymentRequestModelCopyWithImpl<$Res, RecordPaymentRequestModel>;
  @useResult
  $Res call({
    double amount,
    @JsonKey(name: 'payment_date') String? paymentDate,
    String method,
    String? reference,
    String? notes,
  });
}

/// @nodoc
class _$RecordPaymentRequestModelCopyWithImpl<
  $Res,
  $Val extends RecordPaymentRequestModel
>
    implements $RecordPaymentRequestModelCopyWith<$Res> {
  _$RecordPaymentRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordPaymentRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? method = null,
    Object? reference = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentDate: freezed == paymentDate
                ? _value.paymentDate
                : paymentDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            reference: freezed == reference
                ? _value.reference
                : reference // ignore: cast_nullable_to_non_nullable
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
abstract class _$$RecordPaymentRequestModelImplCopyWith<$Res>
    implements $RecordPaymentRequestModelCopyWith<$Res> {
  factory _$$RecordPaymentRequestModelImplCopyWith(
    _$RecordPaymentRequestModelImpl value,
    $Res Function(_$RecordPaymentRequestModelImpl) then,
  ) = __$$RecordPaymentRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double amount,
    @JsonKey(name: 'payment_date') String? paymentDate,
    String method,
    String? reference,
    String? notes,
  });
}

/// @nodoc
class __$$RecordPaymentRequestModelImplCopyWithImpl<$Res>
    extends
        _$RecordPaymentRequestModelCopyWithImpl<
          $Res,
          _$RecordPaymentRequestModelImpl
        >
    implements _$$RecordPaymentRequestModelImplCopyWith<$Res> {
  __$$RecordPaymentRequestModelImplCopyWithImpl(
    _$RecordPaymentRequestModelImpl _value,
    $Res Function(_$RecordPaymentRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordPaymentRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? paymentDate = freezed,
    Object? method = null,
    Object? reference = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$RecordPaymentRequestModelImpl(
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentDate: freezed == paymentDate
            ? _value.paymentDate
            : paymentDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        reference: freezed == reference
            ? _value.reference
            : reference // ignore: cast_nullable_to_non_nullable
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
class _$RecordPaymentRequestModelImpl implements _RecordPaymentRequestModel {
  const _$RecordPaymentRequestModelImpl({
    required this.amount,
    @JsonKey(name: 'payment_date') this.paymentDate,
    this.method = 'CASH',
    this.reference,
    this.notes,
  });

  factory _$RecordPaymentRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordPaymentRequestModelImplFromJson(json);

  @override
  final double amount;
  @override
  @JsonKey(name: 'payment_date')
  final String? paymentDate;
  @override
  @JsonKey()
  final String method;
  @override
  final String? reference;
  @override
  final String? notes;

  @override
  String toString() {
    return 'RecordPaymentRequestModel(amount: $amount, paymentDate: $paymentDate, method: $method, reference: $reference, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordPaymentRequestModelImpl &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, amount, paymentDate, method, reference, notes);

  /// Create a copy of RecordPaymentRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordPaymentRequestModelImplCopyWith<_$RecordPaymentRequestModelImpl>
  get copyWith =>
      __$$RecordPaymentRequestModelImplCopyWithImpl<
        _$RecordPaymentRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordPaymentRequestModelImplToJson(this);
  }
}

abstract class _RecordPaymentRequestModel implements RecordPaymentRequestModel {
  const factory _RecordPaymentRequestModel({
    required final double amount,
    @JsonKey(name: 'payment_date') final String? paymentDate,
    final String method,
    final String? reference,
    final String? notes,
  }) = _$RecordPaymentRequestModelImpl;

  factory _RecordPaymentRequestModel.fromJson(Map<String, dynamic> json) =
      _$RecordPaymentRequestModelImpl.fromJson;

  @override
  double get amount;
  @override
  @JsonKey(name: 'payment_date')
  String? get paymentDate;
  @override
  String get method;
  @override
  String? get reference;
  @override
  String? get notes;

  /// Create a copy of RecordPaymentRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordPaymentRequestModelImplCopyWith<_$RecordPaymentRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
