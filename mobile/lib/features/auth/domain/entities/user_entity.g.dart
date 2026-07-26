// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileEntityImpl _$$UserProfileEntityImplFromJson(
  Map<String, dynamic> json,
) => _$UserProfileEntityImpl(
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  bio: json['bio'] as String? ?? '',
);

Map<String, dynamic> _$$UserProfileEntityImplToJson(
  _$UserProfileEntityImpl instance,
) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'avatar': instance.avatar,
  'bio': instance.bio,
};

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      username: json['username'] as String,
      phone: json['phone'] as String?,
      isSuperUser: json['is_super_user'] as bool? ?? false,
      saccoId: json['sacco_id'] as String?,
      roleName: json['role_name'] as String? ?? '',
      profile: json['profile'] == null
          ? null
          : UserProfileEntity.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'phone': instance.phone,
      'is_super_user': instance.isSuperUser,
      'sacco_id': instance.saccoId,
      'role_name': instance.roleName,
      'profile': instance.profile,
    };
