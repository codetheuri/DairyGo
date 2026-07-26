// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemberModelImpl _$$MemberModelImplFromJson(Map<String, dynamic> json) =>
    _$MemberModelImpl(
      id: json['id'] as String,
      saccoId: json['sacco_id'] as String? ?? '',
      membershipNumber: json['membership_number'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      nationalId: json['national_id'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      mpesaNumber: json['mpesa_number'] as String?,
      mpesaName: json['mpesa_name'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankBranch: json['bank_branch'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$MemberModelImplToJson(_$MemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sacco_id': instance.saccoId,
      'membership_number': instance.membershipNumber,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'national_id': instance.nationalId,
      'phone': instance.phone,
      'email': instance.email,
      'gender': instance.gender,
      'location': instance.location,
      'status': instance.status,
      'mpesa_number': instance.mpesaNumber,
      'mpesa_name': instance.mpesaName,
      'bank_name': instance.bankName,
      'bank_account_number': instance.bankAccountNumber,
      'bank_branch': instance.bankBranch,
      'created_at': instance.createdAt,
    };

_$CreateMemberRequestModelImpl _$$CreateMemberRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$CreateMemberRequestModelImpl(
  membershipNumber: json['membership_number'] as String?,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  nationalId: json['national_id'] as String?,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  gender: json['gender'] as String?,
  location: json['location'] as String?,
  mpesaNumber: json['mpesa_number'] as String?,
  mpesaName: json['mpesa_name'] as String?,
);

Map<String, dynamic> _$$CreateMemberRequestModelImplToJson(
  _$CreateMemberRequestModelImpl instance,
) => <String, dynamic>{
  'membership_number': instance.membershipNumber,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'national_id': instance.nationalId,
  'phone': instance.phone,
  'email': instance.email,
  'gender': instance.gender,
  'location': instance.location,
  'mpesa_number': instance.mpesaNumber,
  'mpesa_name': instance.mpesaName,
};
