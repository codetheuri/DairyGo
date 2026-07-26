// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RegisterRequestImpl(
  username: json['username'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  password: json['password'] as String,
  passwordConfirmation: json['password_confirmation'] as String,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  roleId: (json['role_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$$RegisterRequestImplToJson(
  _$RegisterRequestImpl instance,
) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'password': instance.password,
  'password_confirmation': instance.passwordConfirmation,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'role_id': instance.roleId,
};
