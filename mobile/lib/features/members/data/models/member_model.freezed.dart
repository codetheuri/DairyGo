// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MemberModel _$MemberModelFromJson(Map<String, dynamic> json) {
  return _MemberModel.fromJson(json);
}

/// @nodoc
mixin _$MemberModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sacco_id')
  String get saccoId => throw _privateConstructorUsedError;
  @JsonKey(name: 'membership_number')
  String get membershipNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'national_id')
  String? get nationalId => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'mpesa_name')
  String? get mpesaName => throw _privateConstructorUsedError;
  @JsonKey(name: 'bank_name')
  String? get bankName => throw _privateConstructorUsedError;
  @JsonKey(name: 'bank_account_number')
  String? get bankAccountNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'bank_branch')
  String? get bankBranch => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemberModelCopyWith<MemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemberModelCopyWith<$Res> {
  factory $MemberModelCopyWith(
    MemberModel value,
    $Res Function(MemberModel) then,
  ) = _$MemberModelCopyWithImpl<$Res, MemberModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'membership_number') String membershipNumber,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    String phone,
    String? email,
    String? gender,
    String? location,
    String status,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') String? bankBranch,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$MemberModelCopyWithImpl<$Res, $Val extends MemberModel>
    implements $MemberModelCopyWith<$Res> {
  _$MemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? membershipNumber = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationalId = freezed,
    Object? phone = null,
    Object? email = freezed,
    Object? gender = freezed,
    Object? location = freezed,
    Object? status = null,
    Object? mpesaNumber = freezed,
    Object? mpesaName = freezed,
    Object? bankName = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankBranch = freezed,
    Object? createdAt = freezed,
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
            membershipNumber: null == membershipNumber
                ? _value.membershipNumber
                : membershipNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            nationalId: freezed == nationalId
                ? _value.nationalId
                : nationalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            mpesaNumber: freezed == mpesaNumber
                ? _value.mpesaNumber
                : mpesaNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            mpesaName: freezed == mpesaName
                ? _value.mpesaName
                : mpesaName // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankName: freezed == bankName
                ? _value.bankName
                : bankName // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankAccountNumber: freezed == bankAccountNumber
                ? _value.bankAccountNumber
                : bankAccountNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            bankBranch: freezed == bankBranch
                ? _value.bankBranch
                : bankBranch // ignore: cast_nullable_to_non_nullable
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
abstract class _$$MemberModelImplCopyWith<$Res>
    implements $MemberModelCopyWith<$Res> {
  factory _$$MemberModelImplCopyWith(
    _$MemberModelImpl value,
    $Res Function(_$MemberModelImpl) then,
  ) = __$$MemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sacco_id') String saccoId,
    @JsonKey(name: 'membership_number') String membershipNumber,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    String phone,
    String? email,
    String? gender,
    String? location,
    String status,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') String? bankBranch,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$MemberModelImplCopyWithImpl<$Res>
    extends _$MemberModelCopyWithImpl<$Res, _$MemberModelImpl>
    implements _$$MemberModelImplCopyWith<$Res> {
  __$$MemberModelImplCopyWithImpl(
    _$MemberModelImpl _value,
    $Res Function(_$MemberModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saccoId = null,
    Object? membershipNumber = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationalId = freezed,
    Object? phone = null,
    Object? email = freezed,
    Object? gender = freezed,
    Object? location = freezed,
    Object? status = null,
    Object? mpesaNumber = freezed,
    Object? mpesaName = freezed,
    Object? bankName = freezed,
    Object? bankAccountNumber = freezed,
    Object? bankBranch = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$MemberModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saccoId: null == saccoId
            ? _value.saccoId
            : saccoId // ignore: cast_nullable_to_non_nullable
                  as String,
        membershipNumber: null == membershipNumber
            ? _value.membershipNumber
            : membershipNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        nationalId: freezed == nationalId
            ? _value.nationalId
            : nationalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        mpesaNumber: freezed == mpesaNumber
            ? _value.mpesaNumber
            : mpesaNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        mpesaName: freezed == mpesaName
            ? _value.mpesaName
            : mpesaName // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankName: freezed == bankName
            ? _value.bankName
            : bankName // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankAccountNumber: freezed == bankAccountNumber
            ? _value.bankAccountNumber
            : bankAccountNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        bankBranch: freezed == bankBranch
            ? _value.bankBranch
            : bankBranch // ignore: cast_nullable_to_non_nullable
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
class _$MemberModelImpl extends _MemberModel {
  const _$MemberModelImpl({
    required this.id,
    @JsonKey(name: 'sacco_id') this.saccoId = '',
    @JsonKey(name: 'membership_number') this.membershipNumber = '',
    @JsonKey(name: 'first_name') this.firstName = '',
    @JsonKey(name: 'last_name') this.lastName = '',
    @JsonKey(name: 'national_id') this.nationalId,
    this.phone = '',
    this.email,
    this.gender,
    this.location,
    this.status = 'ACTIVE',
    @JsonKey(name: 'mpesa_number') this.mpesaNumber,
    @JsonKey(name: 'mpesa_name') this.mpesaName,
    @JsonKey(name: 'bank_name') this.bankName,
    @JsonKey(name: 'bank_account_number') this.bankAccountNumber,
    @JsonKey(name: 'bank_branch') this.bankBranch,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$MemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sacco_id')
  final String saccoId;
  @override
  @JsonKey(name: 'membership_number')
  final String membershipNumber;
  @override
  @JsonKey(name: 'first_name')
  final String firstName;
  @override
  @JsonKey(name: 'last_name')
  final String lastName;
  @override
  @JsonKey(name: 'national_id')
  final String? nationalId;
  @override
  @JsonKey()
  final String phone;
  @override
  final String? email;
  @override
  final String? gender;
  @override
  final String? location;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'mpesa_number')
  final String? mpesaNumber;
  @override
  @JsonKey(name: 'mpesa_name')
  final String? mpesaName;
  @override
  @JsonKey(name: 'bank_name')
  final String? bankName;
  @override
  @JsonKey(name: 'bank_account_number')
  final String? bankAccountNumber;
  @override
  @JsonKey(name: 'bank_branch')
  final String? bankBranch;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'MemberModel(id: $id, saccoId: $saccoId, membershipNumber: $membershipNumber, firstName: $firstName, lastName: $lastName, nationalId: $nationalId, phone: $phone, email: $email, gender: $gender, location: $location, status: $status, mpesaNumber: $mpesaNumber, mpesaName: $mpesaName, bankName: $bankName, bankAccountNumber: $bankAccountNumber, bankBranch: $bankBranch, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saccoId, saccoId) || other.saccoId == saccoId) &&
            (identical(other.membershipNumber, membershipNumber) ||
                other.membershipNumber == membershipNumber) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.nationalId, nationalId) ||
                other.nationalId == nationalId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.mpesaNumber, mpesaNumber) ||
                other.mpesaNumber == mpesaNumber) &&
            (identical(other.mpesaName, mpesaName) ||
                other.mpesaName == mpesaName) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.bankAccountNumber, bankAccountNumber) ||
                other.bankAccountNumber == bankAccountNumber) &&
            (identical(other.bankBranch, bankBranch) ||
                other.bankBranch == bankBranch) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    saccoId,
    membershipNumber,
    firstName,
    lastName,
    nationalId,
    phone,
    email,
    gender,
    location,
    status,
    mpesaNumber,
    mpesaName,
    bankName,
    bankAccountNumber,
    bankBranch,
    createdAt,
  );

  /// Create a copy of MemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberModelImplCopyWith<_$MemberModelImpl> get copyWith =>
      __$$MemberModelImplCopyWithImpl<_$MemberModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberModelImplToJson(this);
  }
}

abstract class _MemberModel extends MemberModel {
  const factory _MemberModel({
    required final String id,
    @JsonKey(name: 'sacco_id') final String saccoId,
    @JsonKey(name: 'membership_number') final String membershipNumber,
    @JsonKey(name: 'first_name') final String firstName,
    @JsonKey(name: 'last_name') final String lastName,
    @JsonKey(name: 'national_id') final String? nationalId,
    final String phone,
    final String? email,
    final String? gender,
    final String? location,
    final String status,
    @JsonKey(name: 'mpesa_number') final String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') final String? mpesaName,
    @JsonKey(name: 'bank_name') final String? bankName,
    @JsonKey(name: 'bank_account_number') final String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') final String? bankBranch,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$MemberModelImpl;
  const _MemberModel._() : super._();

  factory _MemberModel.fromJson(Map<String, dynamic> json) =
      _$MemberModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sacco_id')
  String get saccoId;
  @override
  @JsonKey(name: 'membership_number')
  String get membershipNumber;
  @override
  @JsonKey(name: 'first_name')
  String get firstName;
  @override
  @JsonKey(name: 'last_name')
  String get lastName;
  @override
  @JsonKey(name: 'national_id')
  String? get nationalId;
  @override
  String get phone;
  @override
  String? get email;
  @override
  String? get gender;
  @override
  String? get location;
  @override
  String get status;
  @override
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber;
  @override
  @JsonKey(name: 'mpesa_name')
  String? get mpesaName;
  @override
  @JsonKey(name: 'bank_name')
  String? get bankName;
  @override
  @JsonKey(name: 'bank_account_number')
  String? get bankAccountNumber;
  @override
  @JsonKey(name: 'bank_branch')
  String? get bankBranch;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of MemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemberModelImplCopyWith<_$MemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateMemberRequestModel _$CreateMemberRequestModelFromJson(
  Map<String, dynamic> json,
) {
  return _CreateMemberRequestModel.fromJson(json);
}

/// @nodoc
mixin _$CreateMemberRequestModel {
  @JsonKey(name: 'membership_number')
  String? get membershipNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'national_id')
  String? get nationalId => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'mpesa_name')
  String? get mpesaName => throw _privateConstructorUsedError;

  /// Serializes this CreateMemberRequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateMemberRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateMemberRequestModelCopyWith<CreateMemberRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateMemberRequestModelCopyWith<$Res> {
  factory $CreateMemberRequestModelCopyWith(
    CreateMemberRequestModel value,
    $Res Function(CreateMemberRequestModel) then,
  ) = _$CreateMemberRequestModelCopyWithImpl<$Res, CreateMemberRequestModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'membership_number') String? membershipNumber,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    String phone,
    String? email,
    String? gender,
    String? location,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
  });
}

/// @nodoc
class _$CreateMemberRequestModelCopyWithImpl<
  $Res,
  $Val extends CreateMemberRequestModel
>
    implements $CreateMemberRequestModelCopyWith<$Res> {
  _$CreateMemberRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateMemberRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membershipNumber = freezed,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationalId = freezed,
    Object? phone = null,
    Object? email = freezed,
    Object? gender = freezed,
    Object? location = freezed,
    Object? mpesaNumber = freezed,
    Object? mpesaName = freezed,
  }) {
    return _then(
      _value.copyWith(
            membershipNumber: freezed == membershipNumber
                ? _value.membershipNumber
                : membershipNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            nationalId: freezed == nationalId
                ? _value.nationalId
                : nationalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            mpesaNumber: freezed == mpesaNumber
                ? _value.mpesaNumber
                : mpesaNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            mpesaName: freezed == mpesaName
                ? _value.mpesaName
                : mpesaName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateMemberRequestModelImplCopyWith<$Res>
    implements $CreateMemberRequestModelCopyWith<$Res> {
  factory _$$CreateMemberRequestModelImplCopyWith(
    _$CreateMemberRequestModelImpl value,
    $Res Function(_$CreateMemberRequestModelImpl) then,
  ) = __$$CreateMemberRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'membership_number') String? membershipNumber,
    @JsonKey(name: 'first_name') String firstName,
    @JsonKey(name: 'last_name') String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    String phone,
    String? email,
    String? gender,
    String? location,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
  });
}

/// @nodoc
class __$$CreateMemberRequestModelImplCopyWithImpl<$Res>
    extends
        _$CreateMemberRequestModelCopyWithImpl<
          $Res,
          _$CreateMemberRequestModelImpl
        >
    implements _$$CreateMemberRequestModelImplCopyWith<$Res> {
  __$$CreateMemberRequestModelImplCopyWithImpl(
    _$CreateMemberRequestModelImpl _value,
    $Res Function(_$CreateMemberRequestModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateMemberRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? membershipNumber = freezed,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationalId = freezed,
    Object? phone = null,
    Object? email = freezed,
    Object? gender = freezed,
    Object? location = freezed,
    Object? mpesaNumber = freezed,
    Object? mpesaName = freezed,
  }) {
    return _then(
      _$CreateMemberRequestModelImpl(
        membershipNumber: freezed == membershipNumber
            ? _value.membershipNumber
            : membershipNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        nationalId: freezed == nationalId
            ? _value.nationalId
            : nationalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        mpesaNumber: freezed == mpesaNumber
            ? _value.mpesaNumber
            : mpesaNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        mpesaName: freezed == mpesaName
            ? _value.mpesaName
            : mpesaName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateMemberRequestModelImpl implements _CreateMemberRequestModel {
  const _$CreateMemberRequestModelImpl({
    @JsonKey(name: 'membership_number') this.membershipNumber,
    @JsonKey(name: 'first_name') required this.firstName,
    @JsonKey(name: 'last_name') required this.lastName,
    @JsonKey(name: 'national_id') this.nationalId,
    required this.phone,
    this.email,
    this.gender,
    this.location,
    @JsonKey(name: 'mpesa_number') this.mpesaNumber,
    @JsonKey(name: 'mpesa_name') this.mpesaName,
  });

  factory _$CreateMemberRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateMemberRequestModelImplFromJson(json);

  @override
  @JsonKey(name: 'membership_number')
  final String? membershipNumber;
  @override
  @JsonKey(name: 'first_name')
  final String firstName;
  @override
  @JsonKey(name: 'last_name')
  final String lastName;
  @override
  @JsonKey(name: 'national_id')
  final String? nationalId;
  @override
  final String phone;
  @override
  final String? email;
  @override
  final String? gender;
  @override
  final String? location;
  @override
  @JsonKey(name: 'mpesa_number')
  final String? mpesaNumber;
  @override
  @JsonKey(name: 'mpesa_name')
  final String? mpesaName;

  @override
  String toString() {
    return 'CreateMemberRequestModel(membershipNumber: $membershipNumber, firstName: $firstName, lastName: $lastName, nationalId: $nationalId, phone: $phone, email: $email, gender: $gender, location: $location, mpesaNumber: $mpesaNumber, mpesaName: $mpesaName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateMemberRequestModelImpl &&
            (identical(other.membershipNumber, membershipNumber) ||
                other.membershipNumber == membershipNumber) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.nationalId, nationalId) ||
                other.nationalId == nationalId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.mpesaNumber, mpesaNumber) ||
                other.mpesaNumber == mpesaNumber) &&
            (identical(other.mpesaName, mpesaName) ||
                other.mpesaName == mpesaName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    membershipNumber,
    firstName,
    lastName,
    nationalId,
    phone,
    email,
    gender,
    location,
    mpesaNumber,
    mpesaName,
  );

  /// Create a copy of CreateMemberRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateMemberRequestModelImplCopyWith<_$CreateMemberRequestModelImpl>
  get copyWith =>
      __$$CreateMemberRequestModelImplCopyWithImpl<
        _$CreateMemberRequestModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateMemberRequestModelImplToJson(this);
  }
}

abstract class _CreateMemberRequestModel implements CreateMemberRequestModel {
  const factory _CreateMemberRequestModel({
    @JsonKey(name: 'membership_number') final String? membershipNumber,
    @JsonKey(name: 'first_name') required final String firstName,
    @JsonKey(name: 'last_name') required final String lastName,
    @JsonKey(name: 'national_id') final String? nationalId,
    required final String phone,
    final String? email,
    final String? gender,
    final String? location,
    @JsonKey(name: 'mpesa_number') final String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') final String? mpesaName,
  }) = _$CreateMemberRequestModelImpl;

  factory _CreateMemberRequestModel.fromJson(Map<String, dynamic> json) =
      _$CreateMemberRequestModelImpl.fromJson;

  @override
  @JsonKey(name: 'membership_number')
  String? get membershipNumber;
  @override
  @JsonKey(name: 'first_name')
  String get firstName;
  @override
  @JsonKey(name: 'last_name')
  String get lastName;
  @override
  @JsonKey(name: 'national_id')
  String? get nationalId;
  @override
  String get phone;
  @override
  String? get email;
  @override
  String? get gender;
  @override
  String? get location;
  @override
  @JsonKey(name: 'mpesa_number')
  String? get mpesaNumber;
  @override
  @JsonKey(name: 'mpesa_name')
  String? get mpesaName;

  /// Create a copy of CreateMemberRequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateMemberRequestModelImplCopyWith<_$CreateMemberRequestModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
