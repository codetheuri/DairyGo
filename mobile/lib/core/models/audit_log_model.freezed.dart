// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuditLogModel _$AuditLogModelFromJson(Map<String, dynamic> json) {
  return _AuditLogModel.fromJson(json);
}

/// @nodoc
mixin _$AuditLogModel {
  String get id => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  @JsonKey(name: 'actor_name')
  String? get actorName => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'old_values')
  String? get oldValues => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_values')
  String? get newValues => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AuditLogModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuditLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditLogModelCopyWith<AuditLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditLogModelCopyWith<$Res> {
  factory $AuditLogModelCopyWith(
    AuditLogModel value,
    $Res Function(AuditLogModel) then,
  ) = _$AuditLogModelCopyWithImpl<$Res, AuditLogModel>;
  @useResult
  $Res call({
    String id,
    String action,
    @JsonKey(name: 'actor_name') String? actorName,
    String? reason,
    @JsonKey(name: 'old_values') String? oldValues,
    @JsonKey(name: 'new_values') String? newValues,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$AuditLogModelCopyWithImpl<$Res, $Val extends AuditLogModel>
    implements $AuditLogModelCopyWith<$Res> {
  _$AuditLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? action = null,
    Object? actorName = freezed,
    Object? reason = freezed,
    Object? oldValues = freezed,
    Object? newValues = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            actorName: freezed == actorName
                ? _value.actorName
                : actorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            oldValues: freezed == oldValues
                ? _value.oldValues
                : oldValues // ignore: cast_nullable_to_non_nullable
                      as String?,
            newValues: freezed == newValues
                ? _value.newValues
                : newValues // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$AuditLogModelImplCopyWith<$Res>
    implements $AuditLogModelCopyWith<$Res> {
  factory _$$AuditLogModelImplCopyWith(
    _$AuditLogModelImpl value,
    $Res Function(_$AuditLogModelImpl) then,
  ) = __$$AuditLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String action,
    @JsonKey(name: 'actor_name') String? actorName,
    String? reason,
    @JsonKey(name: 'old_values') String? oldValues,
    @JsonKey(name: 'new_values') String? newValues,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$AuditLogModelImplCopyWithImpl<$Res>
    extends _$AuditLogModelCopyWithImpl<$Res, _$AuditLogModelImpl>
    implements _$$AuditLogModelImplCopyWith<$Res> {
  __$$AuditLogModelImplCopyWithImpl(
    _$AuditLogModelImpl _value,
    $Res Function(_$AuditLogModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuditLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? action = null,
    Object? actorName = freezed,
    Object? reason = freezed,
    Object? oldValues = freezed,
    Object? newValues = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$AuditLogModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        actorName: freezed == actorName
            ? _value.actorName
            : actorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        oldValues: freezed == oldValues
            ? _value.oldValues
            : oldValues // ignore: cast_nullable_to_non_nullable
                  as String?,
        newValues: freezed == newValues
            ? _value.newValues
            : newValues // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$AuditLogModelImpl implements _AuditLogModel {
  const _$AuditLogModelImpl({
    required this.id,
    this.action = '',
    @JsonKey(name: 'actor_name') this.actorName,
    this.reason,
    @JsonKey(name: 'old_values') this.oldValues,
    @JsonKey(name: 'new_values') this.newValues,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$AuditLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditLogModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String action;
  @override
  @JsonKey(name: 'actor_name')
  final String? actorName;
  @override
  final String? reason;
  @override
  @JsonKey(name: 'old_values')
  final String? oldValues;
  @override
  @JsonKey(name: 'new_values')
  final String? newValues;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'AuditLogModel(id: $id, action: $action, actorName: $actorName, reason: $reason, oldValues: $oldValues, newValues: $newValues, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.actorName, actorName) ||
                other.actorName == actorName) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.oldValues, oldValues) ||
                other.oldValues == oldValues) &&
            (identical(other.newValues, newValues) ||
                other.newValues == newValues) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    action,
    actorName,
    reason,
    oldValues,
    newValues,
    createdAt,
  );

  /// Create a copy of AuditLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditLogModelImplCopyWith<_$AuditLogModelImpl> get copyWith =>
      __$$AuditLogModelImplCopyWithImpl<_$AuditLogModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditLogModelImplToJson(this);
  }
}

abstract class _AuditLogModel implements AuditLogModel {
  const factory _AuditLogModel({
    required final String id,
    final String action,
    @JsonKey(name: 'actor_name') final String? actorName,
    final String? reason,
    @JsonKey(name: 'old_values') final String? oldValues,
    @JsonKey(name: 'new_values') final String? newValues,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$AuditLogModelImpl;

  factory _AuditLogModel.fromJson(Map<String, dynamic> json) =
      _$AuditLogModelImpl.fromJson;

  @override
  String get id;
  @override
  String get action;
  @override
  @JsonKey(name: 'actor_name')
  String? get actorName;
  @override
  String? get reason;
  @override
  @JsonKey(name: 'old_values')
  String? get oldValues;
  @override
  @JsonKey(name: 'new_values')
  String? get newValues;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of AuditLogModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditLogModelImplCopyWith<_$AuditLogModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
