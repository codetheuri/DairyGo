// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'executive_dashboard_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ExecutiveSummaryCards _$ExecutiveSummaryCardsFromJson(
  Map<String, dynamic> json,
) {
  return _ExecutiveSummaryCards.fromJson(json);
}

/// @nodoc
mixin _$ExecutiveSummaryCards {
  @JsonKey(name: 'today_collected_litres')
  double get todayCollectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_sales_litres')
  double get todaySalesLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_spoilage_litres')
  double get todaySpoilageLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_net_coolant_station_litres')
  double get todayNetCoolantStationLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'month_collected_litres')
  double get monthCollectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'month_payout_liability_kes')
  double get monthPayoutLiabilityKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'month_sales_revenue_kes')
  double get monthSalesRevenueKes => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_members_count')
  int get activeMembersCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_collectors_count')
  int get activeCollectorsCount => throw _privateConstructorUsedError;

  /// Serializes this ExecutiveSummaryCards to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExecutiveSummaryCards
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExecutiveSummaryCardsCopyWith<ExecutiveSummaryCards> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExecutiveSummaryCardsCopyWith<$Res> {
  factory $ExecutiveSummaryCardsCopyWith(
    ExecutiveSummaryCards value,
    $Res Function(ExecutiveSummaryCards) then,
  ) = _$ExecutiveSummaryCardsCopyWithImpl<$Res, ExecutiveSummaryCards>;
  @useResult
  $Res call({
    @JsonKey(name: 'today_collected_litres') double todayCollectedLitres,
    @JsonKey(name: 'today_sales_litres') double todaySalesLitres,
    @JsonKey(name: 'today_spoilage_litres') double todaySpoilageLitres,
    @JsonKey(name: 'today_net_coolant_station_litres')
    double todayNetCoolantStationLitres,
    @JsonKey(name: 'month_collected_litres') double monthCollectedLitres,
    @JsonKey(name: 'month_payout_liability_kes') double monthPayoutLiabilityKes,
    @JsonKey(name: 'month_sales_revenue_kes') double monthSalesRevenueKes,
    @JsonKey(name: 'active_members_count') int activeMembersCount,
    @JsonKey(name: 'active_collectors_count') int activeCollectorsCount,
  });
}

/// @nodoc
class _$ExecutiveSummaryCardsCopyWithImpl<
  $Res,
  $Val extends ExecutiveSummaryCards
>
    implements $ExecutiveSummaryCardsCopyWith<$Res> {
  _$ExecutiveSummaryCardsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExecutiveSummaryCards
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayCollectedLitres = null,
    Object? todaySalesLitres = null,
    Object? todaySpoilageLitres = null,
    Object? todayNetCoolantStationLitres = null,
    Object? monthCollectedLitres = null,
    Object? monthPayoutLiabilityKes = null,
    Object? monthSalesRevenueKes = null,
    Object? activeMembersCount = null,
    Object? activeCollectorsCount = null,
  }) {
    return _then(
      _value.copyWith(
            todayCollectedLitres: null == todayCollectedLitres
                ? _value.todayCollectedLitres
                : todayCollectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todaySalesLitres: null == todaySalesLitres
                ? _value.todaySalesLitres
                : todaySalesLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todaySpoilageLitres: null == todaySpoilageLitres
                ? _value.todaySpoilageLitres
                : todaySpoilageLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            todayNetCoolantStationLitres: null == todayNetCoolantStationLitres
                ? _value.todayNetCoolantStationLitres
                : todayNetCoolantStationLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            monthCollectedLitres: null == monthCollectedLitres
                ? _value.monthCollectedLitres
                : monthCollectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            monthPayoutLiabilityKes: null == monthPayoutLiabilityKes
                ? _value.monthPayoutLiabilityKes
                : monthPayoutLiabilityKes // ignore: cast_nullable_to_non_nullable
                      as double,
            monthSalesRevenueKes: null == monthSalesRevenueKes
                ? _value.monthSalesRevenueKes
                : monthSalesRevenueKes // ignore: cast_nullable_to_non_nullable
                      as double,
            activeMembersCount: null == activeMembersCount
                ? _value.activeMembersCount
                : activeMembersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            activeCollectorsCount: null == activeCollectorsCount
                ? _value.activeCollectorsCount
                : activeCollectorsCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExecutiveSummaryCardsImplCopyWith<$Res>
    implements $ExecutiveSummaryCardsCopyWith<$Res> {
  factory _$$ExecutiveSummaryCardsImplCopyWith(
    _$ExecutiveSummaryCardsImpl value,
    $Res Function(_$ExecutiveSummaryCardsImpl) then,
  ) = __$$ExecutiveSummaryCardsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'today_collected_litres') double todayCollectedLitres,
    @JsonKey(name: 'today_sales_litres') double todaySalesLitres,
    @JsonKey(name: 'today_spoilage_litres') double todaySpoilageLitres,
    @JsonKey(name: 'today_net_coolant_station_litres')
    double todayNetCoolantStationLitres,
    @JsonKey(name: 'month_collected_litres') double monthCollectedLitres,
    @JsonKey(name: 'month_payout_liability_kes') double monthPayoutLiabilityKes,
    @JsonKey(name: 'month_sales_revenue_kes') double monthSalesRevenueKes,
    @JsonKey(name: 'active_members_count') int activeMembersCount,
    @JsonKey(name: 'active_collectors_count') int activeCollectorsCount,
  });
}

/// @nodoc
class __$$ExecutiveSummaryCardsImplCopyWithImpl<$Res>
    extends
        _$ExecutiveSummaryCardsCopyWithImpl<$Res, _$ExecutiveSummaryCardsImpl>
    implements _$$ExecutiveSummaryCardsImplCopyWith<$Res> {
  __$$ExecutiveSummaryCardsImplCopyWithImpl(
    _$ExecutiveSummaryCardsImpl _value,
    $Res Function(_$ExecutiveSummaryCardsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExecutiveSummaryCards
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayCollectedLitres = null,
    Object? todaySalesLitres = null,
    Object? todaySpoilageLitres = null,
    Object? todayNetCoolantStationLitres = null,
    Object? monthCollectedLitres = null,
    Object? monthPayoutLiabilityKes = null,
    Object? monthSalesRevenueKes = null,
    Object? activeMembersCount = null,
    Object? activeCollectorsCount = null,
  }) {
    return _then(
      _$ExecutiveSummaryCardsImpl(
        todayCollectedLitres: null == todayCollectedLitres
            ? _value.todayCollectedLitres
            : todayCollectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todaySalesLitres: null == todaySalesLitres
            ? _value.todaySalesLitres
            : todaySalesLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todaySpoilageLitres: null == todaySpoilageLitres
            ? _value.todaySpoilageLitres
            : todaySpoilageLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        todayNetCoolantStationLitres: null == todayNetCoolantStationLitres
            ? _value.todayNetCoolantStationLitres
            : todayNetCoolantStationLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        monthCollectedLitres: null == monthCollectedLitres
            ? _value.monthCollectedLitres
            : monthCollectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        monthPayoutLiabilityKes: null == monthPayoutLiabilityKes
            ? _value.monthPayoutLiabilityKes
            : monthPayoutLiabilityKes // ignore: cast_nullable_to_non_nullable
                  as double,
        monthSalesRevenueKes: null == monthSalesRevenueKes
            ? _value.monthSalesRevenueKes
            : monthSalesRevenueKes // ignore: cast_nullable_to_non_nullable
                  as double,
        activeMembersCount: null == activeMembersCount
            ? _value.activeMembersCount
            : activeMembersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        activeCollectorsCount: null == activeCollectorsCount
            ? _value.activeCollectorsCount
            : activeCollectorsCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExecutiveSummaryCardsImpl implements _ExecutiveSummaryCards {
  const _$ExecutiveSummaryCardsImpl({
    @JsonKey(name: 'today_collected_litres') this.todayCollectedLitres = 0.0,
    @JsonKey(name: 'today_sales_litres') this.todaySalesLitres = 0.0,
    @JsonKey(name: 'today_spoilage_litres') this.todaySpoilageLitres = 0.0,
    @JsonKey(name: 'today_net_coolant_station_litres')
    this.todayNetCoolantStationLitres = 0.0,
    @JsonKey(name: 'month_collected_litres') this.monthCollectedLitres = 0.0,
    @JsonKey(name: 'month_payout_liability_kes')
    this.monthPayoutLiabilityKes = 0.0,
    @JsonKey(name: 'month_sales_revenue_kes') this.monthSalesRevenueKes = 0.0,
    @JsonKey(name: 'active_members_count') this.activeMembersCount = 0,
    @JsonKey(name: 'active_collectors_count') this.activeCollectorsCount = 0,
  });

  factory _$ExecutiveSummaryCardsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExecutiveSummaryCardsImplFromJson(json);

  @override
  @JsonKey(name: 'today_collected_litres')
  final double todayCollectedLitres;
  @override
  @JsonKey(name: 'today_sales_litres')
  final double todaySalesLitres;
  @override
  @JsonKey(name: 'today_spoilage_litres')
  final double todaySpoilageLitres;
  @override
  @JsonKey(name: 'today_net_coolant_station_litres')
  final double todayNetCoolantStationLitres;
  @override
  @JsonKey(name: 'month_collected_litres')
  final double monthCollectedLitres;
  @override
  @JsonKey(name: 'month_payout_liability_kes')
  final double monthPayoutLiabilityKes;
  @override
  @JsonKey(name: 'month_sales_revenue_kes')
  final double monthSalesRevenueKes;
  @override
  @JsonKey(name: 'active_members_count')
  final int activeMembersCount;
  @override
  @JsonKey(name: 'active_collectors_count')
  final int activeCollectorsCount;

  @override
  String toString() {
    return 'ExecutiveSummaryCards(todayCollectedLitres: $todayCollectedLitres, todaySalesLitres: $todaySalesLitres, todaySpoilageLitres: $todaySpoilageLitres, todayNetCoolantStationLitres: $todayNetCoolantStationLitres, monthCollectedLitres: $monthCollectedLitres, monthPayoutLiabilityKes: $monthPayoutLiabilityKes, monthSalesRevenueKes: $monthSalesRevenueKes, activeMembersCount: $activeMembersCount, activeCollectorsCount: $activeCollectorsCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExecutiveSummaryCardsImpl &&
            (identical(other.todayCollectedLitres, todayCollectedLitres) ||
                other.todayCollectedLitres == todayCollectedLitres) &&
            (identical(other.todaySalesLitres, todaySalesLitres) ||
                other.todaySalesLitres == todaySalesLitres) &&
            (identical(other.todaySpoilageLitres, todaySpoilageLitres) ||
                other.todaySpoilageLitres == todaySpoilageLitres) &&
            (identical(
                  other.todayNetCoolantStationLitres,
                  todayNetCoolantStationLitres,
                ) ||
                other.todayNetCoolantStationLitres ==
                    todayNetCoolantStationLitres) &&
            (identical(other.monthCollectedLitres, monthCollectedLitres) ||
                other.monthCollectedLitres == monthCollectedLitres) &&
            (identical(
                  other.monthPayoutLiabilityKes,
                  monthPayoutLiabilityKes,
                ) ||
                other.monthPayoutLiabilityKes == monthPayoutLiabilityKes) &&
            (identical(other.monthSalesRevenueKes, monthSalesRevenueKes) ||
                other.monthSalesRevenueKes == monthSalesRevenueKes) &&
            (identical(other.activeMembersCount, activeMembersCount) ||
                other.activeMembersCount == activeMembersCount) &&
            (identical(other.activeCollectorsCount, activeCollectorsCount) ||
                other.activeCollectorsCount == activeCollectorsCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    todayCollectedLitres,
    todaySalesLitres,
    todaySpoilageLitres,
    todayNetCoolantStationLitres,
    monthCollectedLitres,
    monthPayoutLiabilityKes,
    monthSalesRevenueKes,
    activeMembersCount,
    activeCollectorsCount,
  );

  /// Create a copy of ExecutiveSummaryCards
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExecutiveSummaryCardsImplCopyWith<_$ExecutiveSummaryCardsImpl>
  get copyWith =>
      __$$ExecutiveSummaryCardsImplCopyWithImpl<_$ExecutiveSummaryCardsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ExecutiveSummaryCardsImplToJson(this);
  }
}

abstract class _ExecutiveSummaryCards implements ExecutiveSummaryCards {
  const factory _ExecutiveSummaryCards({
    @JsonKey(name: 'today_collected_litres') final double todayCollectedLitres,
    @JsonKey(name: 'today_sales_litres') final double todaySalesLitres,
    @JsonKey(name: 'today_spoilage_litres') final double todaySpoilageLitres,
    @JsonKey(name: 'today_net_coolant_station_litres')
    final double todayNetCoolantStationLitres,
    @JsonKey(name: 'month_collected_litres') final double monthCollectedLitres,
    @JsonKey(name: 'month_payout_liability_kes')
    final double monthPayoutLiabilityKes,
    @JsonKey(name: 'month_sales_revenue_kes') final double monthSalesRevenueKes,
    @JsonKey(name: 'active_members_count') final int activeMembersCount,
    @JsonKey(name: 'active_collectors_count') final int activeCollectorsCount,
  }) = _$ExecutiveSummaryCardsImpl;

  factory _ExecutiveSummaryCards.fromJson(Map<String, dynamic> json) =
      _$ExecutiveSummaryCardsImpl.fromJson;

  @override
  @JsonKey(name: 'today_collected_litres')
  double get todayCollectedLitres;
  @override
  @JsonKey(name: 'today_sales_litres')
  double get todaySalesLitres;
  @override
  @JsonKey(name: 'today_spoilage_litres')
  double get todaySpoilageLitres;
  @override
  @JsonKey(name: 'today_net_coolant_station_litres')
  double get todayNetCoolantStationLitres;
  @override
  @JsonKey(name: 'month_collected_litres')
  double get monthCollectedLitres;
  @override
  @JsonKey(name: 'month_payout_liability_kes')
  double get monthPayoutLiabilityKes;
  @override
  @JsonKey(name: 'month_sales_revenue_kes')
  double get monthSalesRevenueKes;
  @override
  @JsonKey(name: 'active_members_count')
  int get activeMembersCount;
  @override
  @JsonKey(name: 'active_collectors_count')
  int get activeCollectorsCount;

  /// Create a copy of ExecutiveSummaryCards
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExecutiveSummaryCardsImplCopyWith<_$ExecutiveSummaryCardsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

DailyTrendPoint _$DailyTrendPointFromJson(Map<String, dynamic> json) {
  return _DailyTrendPoint.fromJson(json);
}

/// @nodoc
mixin _$DailyTrendPoint {
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'collected_litres')
  double get collectedLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'sales_litres')
  double get salesLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'spoilage_litres')
  double get spoilageLitres => throw _privateConstructorUsedError;
  @JsonKey(name: 'net_coolant_litres')
  double get netCoolantLitres => throw _privateConstructorUsedError;

  /// Serializes this DailyTrendPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyTrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyTrendPointCopyWith<DailyTrendPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyTrendPointCopyWith<$Res> {
  factory $DailyTrendPointCopyWith(
    DailyTrendPoint value,
    $Res Function(DailyTrendPoint) then,
  ) = _$DailyTrendPointCopyWithImpl<$Res, DailyTrendPoint>;
  @useResult
  $Res call({
    String date,
    @JsonKey(name: 'collected_litres') double collectedLitres,
    @JsonKey(name: 'sales_litres') double salesLitres,
    @JsonKey(name: 'spoilage_litres') double spoilageLitres,
    @JsonKey(name: 'net_coolant_litres') double netCoolantLitres,
  });
}

/// @nodoc
class _$DailyTrendPointCopyWithImpl<$Res, $Val extends DailyTrendPoint>
    implements $DailyTrendPointCopyWith<$Res> {
  _$DailyTrendPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyTrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? collectedLitres = null,
    Object? salesLitres = null,
    Object? spoilageLitres = null,
    Object? netCoolantLitres = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            collectedLitres: null == collectedLitres
                ? _value.collectedLitres
                : collectedLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            salesLitres: null == salesLitres
                ? _value.salesLitres
                : salesLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            spoilageLitres: null == spoilageLitres
                ? _value.spoilageLitres
                : spoilageLitres // ignore: cast_nullable_to_non_nullable
                      as double,
            netCoolantLitres: null == netCoolantLitres
                ? _value.netCoolantLitres
                : netCoolantLitres // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyTrendPointImplCopyWith<$Res>
    implements $DailyTrendPointCopyWith<$Res> {
  factory _$$DailyTrendPointImplCopyWith(
    _$DailyTrendPointImpl value,
    $Res Function(_$DailyTrendPointImpl) then,
  ) = __$$DailyTrendPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String date,
    @JsonKey(name: 'collected_litres') double collectedLitres,
    @JsonKey(name: 'sales_litres') double salesLitres,
    @JsonKey(name: 'spoilage_litres') double spoilageLitres,
    @JsonKey(name: 'net_coolant_litres') double netCoolantLitres,
  });
}

/// @nodoc
class __$$DailyTrendPointImplCopyWithImpl<$Res>
    extends _$DailyTrendPointCopyWithImpl<$Res, _$DailyTrendPointImpl>
    implements _$$DailyTrendPointImplCopyWith<$Res> {
  __$$DailyTrendPointImplCopyWithImpl(
    _$DailyTrendPointImpl _value,
    $Res Function(_$DailyTrendPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyTrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? collectedLitres = null,
    Object? salesLitres = null,
    Object? spoilageLitres = null,
    Object? netCoolantLitres = null,
  }) {
    return _then(
      _$DailyTrendPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        collectedLitres: null == collectedLitres
            ? _value.collectedLitres
            : collectedLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        salesLitres: null == salesLitres
            ? _value.salesLitres
            : salesLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        spoilageLitres: null == spoilageLitres
            ? _value.spoilageLitres
            : spoilageLitres // ignore: cast_nullable_to_non_nullable
                  as double,
        netCoolantLitres: null == netCoolantLitres
            ? _value.netCoolantLitres
            : netCoolantLitres // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyTrendPointImpl implements _DailyTrendPoint {
  const _$DailyTrendPointImpl({
    this.date = '',
    @JsonKey(name: 'collected_litres') this.collectedLitres = 0.0,
    @JsonKey(name: 'sales_litres') this.salesLitres = 0.0,
    @JsonKey(name: 'spoilage_litres') this.spoilageLitres = 0.0,
    @JsonKey(name: 'net_coolant_litres') this.netCoolantLitres = 0.0,
  });

  factory _$DailyTrendPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyTrendPointImplFromJson(json);

  @override
  @JsonKey()
  final String date;
  @override
  @JsonKey(name: 'collected_litres')
  final double collectedLitres;
  @override
  @JsonKey(name: 'sales_litres')
  final double salesLitres;
  @override
  @JsonKey(name: 'spoilage_litres')
  final double spoilageLitres;
  @override
  @JsonKey(name: 'net_coolant_litres')
  final double netCoolantLitres;

  @override
  String toString() {
    return 'DailyTrendPoint(date: $date, collectedLitres: $collectedLitres, salesLitres: $salesLitres, spoilageLitres: $spoilageLitres, netCoolantLitres: $netCoolantLitres)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyTrendPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.collectedLitres, collectedLitres) ||
                other.collectedLitres == collectedLitres) &&
            (identical(other.salesLitres, salesLitres) ||
                other.salesLitres == salesLitres) &&
            (identical(other.spoilageLitres, spoilageLitres) ||
                other.spoilageLitres == spoilageLitres) &&
            (identical(other.netCoolantLitres, netCoolantLitres) ||
                other.netCoolantLitres == netCoolantLitres));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    collectedLitres,
    salesLitres,
    spoilageLitres,
    netCoolantLitres,
  );

  /// Create a copy of DailyTrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyTrendPointImplCopyWith<_$DailyTrendPointImpl> get copyWith =>
      __$$DailyTrendPointImplCopyWithImpl<_$DailyTrendPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyTrendPointImplToJson(this);
  }
}

abstract class _DailyTrendPoint implements DailyTrendPoint {
  const factory _DailyTrendPoint({
    final String date,
    @JsonKey(name: 'collected_litres') final double collectedLitres,
    @JsonKey(name: 'sales_litres') final double salesLitres,
    @JsonKey(name: 'spoilage_litres') final double spoilageLitres,
    @JsonKey(name: 'net_coolant_litres') final double netCoolantLitres,
  }) = _$DailyTrendPointImpl;

  factory _DailyTrendPoint.fromJson(Map<String, dynamic> json) =
      _$DailyTrendPointImpl.fromJson;

  @override
  String get date;
  @override
  @JsonKey(name: 'collected_litres')
  double get collectedLitres;
  @override
  @JsonKey(name: 'sales_litres')
  double get salesLitres;
  @override
  @JsonKey(name: 'spoilage_litres')
  double get spoilageLitres;
  @override
  @JsonKey(name: 'net_coolant_litres')
  double get netCoolantLitres;

  /// Create a copy of DailyTrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyTrendPointImplCopyWith<_$DailyTrendPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExecutiveDashboardModel _$ExecutiveDashboardModelFromJson(
  Map<String, dynamic> json,
) {
  return _ExecutiveDashboardModel.fromJson(json);
}

/// @nodoc
mixin _$ExecutiveDashboardModel {
  @JsonKey(name: 'summary_cards')
  ExecutiveSummaryCards get summaryCards => throw _privateConstructorUsedError;
  @JsonKey(name: 'intake_trend')
  List<DailyTrendPoint> get intakeTrend => throw _privateConstructorUsedError;

  /// Serializes this ExecutiveDashboardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExecutiveDashboardModelCopyWith<ExecutiveDashboardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExecutiveDashboardModelCopyWith<$Res> {
  factory $ExecutiveDashboardModelCopyWith(
    ExecutiveDashboardModel value,
    $Res Function(ExecutiveDashboardModel) then,
  ) = _$ExecutiveDashboardModelCopyWithImpl<$Res, ExecutiveDashboardModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'summary_cards') ExecutiveSummaryCards summaryCards,
    @JsonKey(name: 'intake_trend') List<DailyTrendPoint> intakeTrend,
  });

  $ExecutiveSummaryCardsCopyWith<$Res> get summaryCards;
}

/// @nodoc
class _$ExecutiveDashboardModelCopyWithImpl<
  $Res,
  $Val extends ExecutiveDashboardModel
>
    implements $ExecutiveDashboardModelCopyWith<$Res> {
  _$ExecutiveDashboardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summaryCards = null, Object? intakeTrend = null}) {
    return _then(
      _value.copyWith(
            summaryCards: null == summaryCards
                ? _value.summaryCards
                : summaryCards // ignore: cast_nullable_to_non_nullable
                      as ExecutiveSummaryCards,
            intakeTrend: null == intakeTrend
                ? _value.intakeTrend
                : intakeTrend // ignore: cast_nullable_to_non_nullable
                      as List<DailyTrendPoint>,
          )
          as $Val,
    );
  }

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExecutiveSummaryCardsCopyWith<$Res> get summaryCards {
    return $ExecutiveSummaryCardsCopyWith<$Res>(_value.summaryCards, (value) {
      return _then(_value.copyWith(summaryCards: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExecutiveDashboardModelImplCopyWith<$Res>
    implements $ExecutiveDashboardModelCopyWith<$Res> {
  factory _$$ExecutiveDashboardModelImplCopyWith(
    _$ExecutiveDashboardModelImpl value,
    $Res Function(_$ExecutiveDashboardModelImpl) then,
  ) = __$$ExecutiveDashboardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'summary_cards') ExecutiveSummaryCards summaryCards,
    @JsonKey(name: 'intake_trend') List<DailyTrendPoint> intakeTrend,
  });

  @override
  $ExecutiveSummaryCardsCopyWith<$Res> get summaryCards;
}

/// @nodoc
class __$$ExecutiveDashboardModelImplCopyWithImpl<$Res>
    extends
        _$ExecutiveDashboardModelCopyWithImpl<
          $Res,
          _$ExecutiveDashboardModelImpl
        >
    implements _$$ExecutiveDashboardModelImplCopyWith<$Res> {
  __$$ExecutiveDashboardModelImplCopyWithImpl(
    _$ExecutiveDashboardModelImpl _value,
    $Res Function(_$ExecutiveDashboardModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summaryCards = null, Object? intakeTrend = null}) {
    return _then(
      _$ExecutiveDashboardModelImpl(
        summaryCards: null == summaryCards
            ? _value.summaryCards
            : summaryCards // ignore: cast_nullable_to_non_nullable
                  as ExecutiveSummaryCards,
        intakeTrend: null == intakeTrend
            ? _value._intakeTrend
            : intakeTrend // ignore: cast_nullable_to_non_nullable
                  as List<DailyTrendPoint>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExecutiveDashboardModelImpl implements _ExecutiveDashboardModel {
  const _$ExecutiveDashboardModelImpl({
    @JsonKey(name: 'summary_cards') required this.summaryCards,
    @JsonKey(name: 'intake_trend')
    final List<DailyTrendPoint> intakeTrend = const [],
  }) : _intakeTrend = intakeTrend;

  factory _$ExecutiveDashboardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExecutiveDashboardModelImplFromJson(json);

  @override
  @JsonKey(name: 'summary_cards')
  final ExecutiveSummaryCards summaryCards;
  final List<DailyTrendPoint> _intakeTrend;
  @override
  @JsonKey(name: 'intake_trend')
  List<DailyTrendPoint> get intakeTrend {
    if (_intakeTrend is EqualUnmodifiableListView) return _intakeTrend;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_intakeTrend);
  }

  @override
  String toString() {
    return 'ExecutiveDashboardModel(summaryCards: $summaryCards, intakeTrend: $intakeTrend)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExecutiveDashboardModelImpl &&
            (identical(other.summaryCards, summaryCards) ||
                other.summaryCards == summaryCards) &&
            const DeepCollectionEquality().equals(
              other._intakeTrend,
              _intakeTrend,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    summaryCards,
    const DeepCollectionEquality().hash(_intakeTrend),
  );

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExecutiveDashboardModelImplCopyWith<_$ExecutiveDashboardModelImpl>
  get copyWith =>
      __$$ExecutiveDashboardModelImplCopyWithImpl<
        _$ExecutiveDashboardModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExecutiveDashboardModelImplToJson(this);
  }
}

abstract class _ExecutiveDashboardModel implements ExecutiveDashboardModel {
  const factory _ExecutiveDashboardModel({
    @JsonKey(name: 'summary_cards')
    required final ExecutiveSummaryCards summaryCards,
    @JsonKey(name: 'intake_trend') final List<DailyTrendPoint> intakeTrend,
  }) = _$ExecutiveDashboardModelImpl;

  factory _ExecutiveDashboardModel.fromJson(Map<String, dynamic> json) =
      _$ExecutiveDashboardModelImpl.fromJson;

  @override
  @JsonKey(name: 'summary_cards')
  ExecutiveSummaryCards get summaryCards;
  @override
  @JsonKey(name: 'intake_trend')
  List<DailyTrendPoint> get intakeTrend;

  /// Create a copy of ExecutiveDashboardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExecutiveDashboardModelImplCopyWith<_$ExecutiveDashboardModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
