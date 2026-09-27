// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_type_total_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomerTypeTotalModel _$CustomerTypeTotalModelFromJson(
  Map<String, dynamic> json,
) {
  return _CustomerTypeTotalModel.fromJson(json);
}

/// @nodoc
mixin _$CustomerTypeTotalModel {
  @JsonKey(name: 'customer_type')
  String get customerType => throw _privateConstructorUsedError;
  double get litres => throw _privateConstructorUsedError;
  double get revenue => throw _privateConstructorUsedError;

  /// Serializes this CustomerTypeTotalModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerTypeTotalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerTypeTotalModelCopyWith<CustomerTypeTotalModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerTypeTotalModelCopyWith<$Res> {
  factory $CustomerTypeTotalModelCopyWith(
    CustomerTypeTotalModel value,
    $Res Function(CustomerTypeTotalModel) then,
  ) = _$CustomerTypeTotalModelCopyWithImpl<$Res, CustomerTypeTotalModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'customer_type') String customerType,
    double litres,
    double revenue,
  });
}

/// @nodoc
class _$CustomerTypeTotalModelCopyWithImpl<
  $Res,
  $Val extends CustomerTypeTotalModel
>
    implements $CustomerTypeTotalModelCopyWith<$Res> {
  _$CustomerTypeTotalModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerTypeTotalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerType = null,
    Object? litres = null,
    Object? revenue = null,
  }) {
    return _then(
      _value.copyWith(
            customerType: null == customerType
                ? _value.customerType
                : customerType // ignore: cast_nullable_to_non_nullable
                      as String,
            litres: null == litres
                ? _value.litres
                : litres // ignore: cast_nullable_to_non_nullable
                      as double,
            revenue: null == revenue
                ? _value.revenue
                : revenue // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerTypeTotalModelImplCopyWith<$Res>
    implements $CustomerTypeTotalModelCopyWith<$Res> {
  factory _$$CustomerTypeTotalModelImplCopyWith(
    _$CustomerTypeTotalModelImpl value,
    $Res Function(_$CustomerTypeTotalModelImpl) then,
  ) = __$$CustomerTypeTotalModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'customer_type') String customerType,
    double litres,
    double revenue,
  });
}

/// @nodoc
class __$$CustomerTypeTotalModelImplCopyWithImpl<$Res>
    extends
        _$CustomerTypeTotalModelCopyWithImpl<$Res, _$CustomerTypeTotalModelImpl>
    implements _$$CustomerTypeTotalModelImplCopyWith<$Res> {
  __$$CustomerTypeTotalModelImplCopyWithImpl(
    _$CustomerTypeTotalModelImpl _value,
    $Res Function(_$CustomerTypeTotalModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerTypeTotalModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerType = null,
    Object? litres = null,
    Object? revenue = null,
  }) {
    return _then(
      _$CustomerTypeTotalModelImpl(
        customerType: null == customerType
            ? _value.customerType
            : customerType // ignore: cast_nullable_to_non_nullable
                  as String,
        litres: null == litres
            ? _value.litres
            : litres // ignore: cast_nullable_to_non_nullable
                  as double,
        revenue: null == revenue
            ? _value.revenue
            : revenue // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerTypeTotalModelImpl implements _CustomerTypeTotalModel {
  const _$CustomerTypeTotalModelImpl({
    @JsonKey(name: 'customer_type') this.customerType = 'OTHER',
    this.litres = 0.0,
    this.revenue = 0.0,
  });

  factory _$CustomerTypeTotalModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerTypeTotalModelImplFromJson(json);

  @override
  @JsonKey(name: 'customer_type')
  final String customerType;
  @override
  @JsonKey()
  final double litres;
  @override
  @JsonKey()
  final double revenue;

  @override
  String toString() {
    return 'CustomerTypeTotalModel(customerType: $customerType, litres: $litres, revenue: $revenue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerTypeTotalModelImpl &&
            (identical(other.customerType, customerType) ||
                other.customerType == customerType) &&
            (identical(other.litres, litres) || other.litres == litres) &&
            (identical(other.revenue, revenue) || other.revenue == revenue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, customerType, litres, revenue);

  /// Create a copy of CustomerTypeTotalModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerTypeTotalModelImplCopyWith<_$CustomerTypeTotalModelImpl>
  get copyWith =>
      __$$CustomerTypeTotalModelImplCopyWithImpl<_$CustomerTypeTotalModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerTypeTotalModelImplToJson(this);
  }
}

abstract class _CustomerTypeTotalModel implements CustomerTypeTotalModel {
  const factory _CustomerTypeTotalModel({
    @JsonKey(name: 'customer_type') final String customerType,
    final double litres,
    final double revenue,
  }) = _$CustomerTypeTotalModelImpl;

  factory _CustomerTypeTotalModel.fromJson(Map<String, dynamic> json) =
      _$CustomerTypeTotalModelImpl.fromJson;

  @override
  @JsonKey(name: 'customer_type')
  String get customerType;
  @override
  double get litres;
  @override
  double get revenue;

  /// Create a copy of CustomerTypeTotalModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerTypeTotalModelImplCopyWith<_$CustomerTypeTotalModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
