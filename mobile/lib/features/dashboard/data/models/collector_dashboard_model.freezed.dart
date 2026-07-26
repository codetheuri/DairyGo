// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collector_dashboard_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CollectorDashboardModel _$CollectorDashboardModelFromJson(
  Map<String, dynamic> json,
) {
  return _CollectorDashboardModel.fromJson(json);
}

/// @nodoc
mixin _$CollectorDashboardModel {
  @JsonKey(name: 'collector_id')
  int get collectorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'collector_name')
  String get collectorName => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_collected_litres')
  double get todayCollectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_purchases_amount')
  double get todayPurchasesAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_farmers_serviced')
  int get todayFarmersServiced => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_sold_litres')
  double get todaySoldLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_sales_revenue')
  double get todaySalesRevenue => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_spoiled_litres')
  double get todaySpoiledLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_net_station_delivery_litres')
  double get todayNetStationDeliveryLitres =>
      throw _privateConstructorUsedError;

  /// Serializes this CollectorDashboardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollectorDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollectorDashboardModelCopyWith<CollectorDashboardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollectorDashboardModelCopyWith<$Res> {
  factory $CollectorDashboardModelCopyWith(
    CollectorDashboardModel value,
    $Res Function(CollectorDashboardModel) then,
  ) = _$CollectorDashboardModelCopyWithImpl<$Res, CollectorDashboardModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    String date,
    @JsonKey(name: 'today_collected_litres') double todayCollectedLitres,
    @JsonKey(name: 'today_purchases_amount') double todayPurchasesAmount,
    @JsonKey(name: 'today_farmers_serviced') int todayFarmersServiced,
    @JsonKey(name: 'today_sold_litres') double todaySoldLitres,
    @JsonKey(name: 'today_sales_revenue') double todaySalesRevenue,
    @JsonKey(name: 'today_spoiled_litres') double todaySpoiledLitres,
    @JsonKey(name: 'today_net_station_delivery_litres')
    double todayNetStationDeliveryLitres,
  });
}

/// @nodoc
class _$CollectorDashboardModelCopyWithImpl<
  $Res,
  $Val extends CollectorDashboardModel
>
    implements $CollectorDashboardModelCopyWith<$Res> {
  _$CollectorDashboardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollectorDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? date = null,
    Object? todayCollectedLitres = null,
    Object? todayPurchasesAmount = null,
    Object? todayFarmersServiced = null,
    Object? todaySoldLitres = null,
    Object? todaySalesRevenue = null,
    Object? todaySpoiledLitres = null,
    Object? todayNetStationDeliveryLitres = null,
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
            todayCollectedLitres: null == todayCollectedLitres
                ? _value.todayCollectedLitres
                : todayCollectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todayPurchasesAmount: null == todayPurchasesAmount
                ? _value.todayPurchasesAmount
                : todayPurchasesAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            todayFarmersServiced: null == todayFarmersServiced
                ? _value.todayFarmersServiced
                : todayFarmersServiced // ignore: cast_nullable_to_non_nullable
                      as int,
            todaySoldLitres: null == todaySoldLitres
                ? _value.todaySoldLitres
                : todaySoldLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todaySalesRevenue: null == todaySalesRevenue
                ? _value.todaySalesRevenue
                : todaySalesRevenue // ignore: cast_nullable_to_non_nullable
                      as double,
            todaySpoiledLitres: null == todaySpoiledLitres
                ? _value.todaySpoiledLitres
                : todaySpoiledLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todayNetStationDeliveryLitres: null == todayNetStationDeliveryLitres
                ? _value.todayNetStationDeliveryLitres
                : todayNetStationDeliveryLitres // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollectorDashboardModelImplCopyWith<$Res>
    implements $CollectorDashboardModelCopyWith<$Res> {
  factory _$$CollectorDashboardModelImplCopyWith(
    _$CollectorDashboardModelImpl value,
    $Res Function(_$CollectorDashboardModelImpl) then,
  ) = __$$CollectorDashboardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'collector_id') int collectorId,
    @JsonKey(name: 'collector_name') String collectorName,
    String date,
    @JsonKey(name: 'today_collected_litres') double todayCollectedLitres,
    @JsonKey(name: 'today_purchases_amount') double todayPurchasesAmount,
    @JsonKey(name: 'today_farmers_serviced') int todayFarmersServiced,
    @JsonKey(name: 'today_sold_litres') double todaySoldLitres,
    @JsonKey(name: 'today_sales_revenue') double todaySalesRevenue,
    @JsonKey(name: 'today_spoiled_litres') double todaySpoiledLitres,
    @JsonKey(name: 'today_net_station_delivery_litres')
    double todayNetStationDeliveryLitres,
  });
}

/// @nodoc
class __$$CollectorDashboardModelImplCopyWithImpl<$Res>
    extends
        _$CollectorDashboardModelCopyWithImpl<
          $Res,
          _$CollectorDashboardModelImpl
        >
    implements _$$CollectorDashboardModelImplCopyWith<$Res> {
  __$$CollectorDashboardModelImplCopyWithImpl(
    _$CollectorDashboardModelImpl _value,
    $Res Function(_$CollectorDashboardModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollectorDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? collectorId = null,
    Object? collectorName = null,
    Object? date = null,
    Object? todayCollectedLitres = null,
    Object? todayPurchasesAmount = null,
    Object? todayFarmersServiced = null,
    Object? todaySoldLitres = null,
    Object? todaySalesRevenue = null,
    Object? todaySpoiledLitres = null,
    Object? todayNetStationDeliveryLitres = null,
  }) {
    return _then(
      _$CollectorDashboardModelImpl(
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
        todayCollectedLitres: null == todayCollectedLitres
            ? _value.todayCollectedLitres
            : todayCollectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todayPurchasesAmount: null == todayPurchasesAmount
            ? _value.todayPurchasesAmount
            : todayPurchasesAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        todayFarmersServiced: null == todayFarmersServiced
            ? _value.todayFarmersServiced
            : todayFarmersServiced // ignore: cast_nullable_to_non_nullable
                  as int,
        todaySoldLitres: null == todaySoldLitres
            ? _value.todaySoldLitres
            : todaySoldLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todaySalesRevenue: null == todaySalesRevenue
            ? _value.todaySalesRevenue
            : todaySalesRevenue // ignore: cast_nullable_to_non_nullable
                  as double,
        todaySpoiledLitres: null == todaySpoiledLitres
            ? _value.todaySpoiledLitres
            : todaySpoiledLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todayNetStationDeliveryLitres: null == todayNetStationDeliveryLitres
            ? _value.todayNetStationDeliveryLitres
            : todayNetStationDeliveryLitres // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollectorDashboardModelImpl implements _CollectorDashboardModel {
  const _$CollectorDashboardModelImpl({
    @JsonKey(name: 'collector_id') this.collectorId = 0,
    @JsonKey(name: 'collector_name') this.collectorName = '',
    this.date = '',
    @JsonKey(name: 'today_collected_litres') this.todayCollectedLitres = 0.0,
    @JsonKey(name: 'today_purchases_amount') this.todayPurchasesAmount = 0.0,
    @JsonKey(name: 'today_farmers_serviced') this.todayFarmersServiced = 0,
    @JsonKey(name: 'today_sold_litres') this.todaySoldLitres = 0.0,
    @JsonKey(name: 'today_sales_revenue') this.todaySalesRevenue = 0.0,
    @JsonKey(name: 'today_spoiled_litres') this.todaySpoiledLitres = 0.0,
    @JsonKey(name: 'today_net_station_delivery_litres')
    this.todayNetStationDeliveryLitres = 0.0,
  });

  factory _$CollectorDashboardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollectorDashboardModelImplFromJson(json);

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
  @JsonKey(name: 'today_collected_litres')
  final double todayCollectedLitres;
  @override
  @JsonKey(name: 'today_purchases_amount')
  final double todayPurchasesAmount;
  @override
  @JsonKey(name: 'today_farmers_serviced')
  final int todayFarmersServiced;
  @override
  @JsonKey(name: 'today_sold_litres')
  final double todaySoldLitres;
  @override
  @JsonKey(name: 'today_sales_revenue')
  final double todaySalesRevenue;
  @override
  @JsonKey(name: 'today_spoiled_litres')
  final double todaySpoiledLitres;
  @override
  @JsonKey(name: 'today_net_station_delivery_litres')
  final double todayNetStationDeliveryLitres;

  @override
  String toString() {
    return 'CollectorDashboardModel(collectorId: $collectorId, collectorName: $collectorName, date: $date, todayCollectedLitres: $todayCollectedLitres, todayPurchasesAmount: $todayPurchasesAmount, todayFarmersServiced: $todayFarmersServiced, todaySoldLitres: $todaySoldLitres, todaySalesRevenue: $todaySalesRevenue, todaySpoiledLitres: $todaySpoiledLitres, todayNetStationDeliveryLitres: $todayNetStationDeliveryLitres)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollectorDashboardModelImpl &&
            (identical(other.collectorId, collectorId) ||
                other.collectorId == collectorId) &&
            (identical(other.collectorName, collectorName) ||
                other.collectorName == collectorName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.todayCollectedLitres, todayCollectedLitres) ||
                other.todayCollectedLitres == todayCollectedLitres) &&
            (identical(other.todayPurchasesAmount, todayPurchasesAmount) ||
                other.todayPurchasesAmount == todayPurchasesAmount) &&
            (identical(other.todayFarmersServiced, todayFarmersServiced) ||
                other.todayFarmersServiced == todayFarmersServiced) &&
            (identical(other.todaySoldLitres, todaySoldLitres) ||
                other.todaySoldLitres == todaySoldLitres) &&
            (identical(other.todaySalesRevenue, todaySalesRevenue) ||
                other.todaySalesRevenue == todaySalesRevenue) &&
            (identical(other.todaySpoiledLitres, todaySpoiledLitres) ||
                other.todaySpoiledLitres == todaySpoiledLitres) &&
            (identical(
                  other.todayNetStationDeliveryLitres,
                  todayNetStationDeliveryLitres,
                ) ||
                other.todayNetStationDeliveryLitres ==
                    todayNetStationDeliveryLitres));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    collectorId,
    collectorName,
    date,
    todayCollectedLitres,
    todayPurchasesAmount,
    todayFarmersServiced,
    todaySoldLitres,
    todaySalesRevenue,
    todaySpoiledLitres,
    todayNetStationDeliveryLitres,
  );

  /// Create a copy of CollectorDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollectorDashboardModelImplCopyWith<_$CollectorDashboardModelImpl>
  get copyWith =>
      __$$CollectorDashboardModelImplCopyWithImpl<
        _$CollectorDashboardModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollectorDashboardModelImplToJson(this);
  }
}

abstract class _CollectorDashboardModel implements CollectorDashboardModel {
  const factory _CollectorDashboardModel({
    @JsonKey(name: 'collector_id') final int collectorId,
    @JsonKey(name: 'collector_name') final String collectorName,
    final String date,
    @JsonKey(name: 'today_collected_litres') final double todayCollectedLitres,
    @JsonKey(name: 'today_purchases_amount') final double todayPurchasesAmount,
    @JsonKey(name: 'today_farmers_serviced') final int todayFarmersServiced,
    @JsonKey(name: 'today_sold_litres') final double todaySoldLitres,
    @JsonKey(name: 'today_sales_revenue') final double todaySalesRevenue,
    @JsonKey(name: 'today_spoiled_litres') final double todaySpoiledLitres,
    @JsonKey(name: 'today_net_station_delivery_litres')
    final double todayNetStationDeliveryLitres,
  }) = _$CollectorDashboardModelImpl;

  factory _CollectorDashboardModel.fromJson(Map<String, dynamic> json) =
      _$CollectorDashboardModelImpl.fromJson;

  @override
  @JsonKey(name: 'collector_id')
  int get collectorId;
  @override
  @JsonKey(name: 'collector_name')
  String get collectorName;
  @override
  String get date;
  @override
  @JsonKey(name: 'today_collected_litres')
  double get todayCollectedLitres;
  @override
  @JsonKey(name: 'today_purchases_amount')
  double get todayPurchasesAmount;
  @override
  @JsonKey(name: 'today_farmers_serviced')
  int get todayFarmersServiced;
  @override
  @JsonKey(name: 'today_sold_litres')
  double get todaySoldLitres;
  @override
  @JsonKey(name: 'today_sales_revenue')
  double get todaySalesRevenue;
  @override
  @JsonKey(name: 'today_spoiled_litres')
  double get todaySpoiledLitres;
  @override
  @JsonKey(name: 'today_net_station_delivery_litres')
  double get todayNetStationDeliveryLitres;

  /// Create a copy of CollectorDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollectorDashboardModelImplCopyWith<_$CollectorDashboardModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
