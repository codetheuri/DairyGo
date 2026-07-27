import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
class UserProfileEntity with _$UserProfileEntity {
  const factory UserProfileEntity({
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @Default('') String avatar,
    @Default('') String bio,
  }) = _UserProfileEntity;

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$UserProfileEntityFromJson(json);
}

@freezed
class UserEntity with _$UserEntity {
  const UserEntity._();

  const factory UserEntity({
    required int id,
    required String email,
    required String username,
    String? phone,
    @JsonKey(name: 'is_super_user') @Default(false) bool isSuperUser,
    @JsonKey(name: 'sacco_id') String? saccoId,
    @JsonKey(name: 'role_name') @Default('') String roleName,
    UserProfileEntity? profile,
  }) = _UserEntity;

  String get fullName {
    if (profile != null) {
      final name = '${profile!.firstName} ${profile!.lastName}'.trim();
      if (name.isNotEmpty) return name;
    }
    return username;
  }

  bool get isExecutive {
    if (isSuperUser) return true;
    final lower = roleName.toLowerCase();
    return lower.contains('board') || lower.contains('executive') || lower.contains('admin');
  }

  bool get isSaccoAdmin {
    if (isSuperUser) return true;
    final lower = roleName.toLowerCase();
    return lower.contains('admin');
  }

  bool get canManageStaff => isSaccoAdmin || isSuperUser;
  bool get canSetPrice => isSaccoAdmin || isSuperUser;

  String get displayRole {
    if (isSuperUser) return 'Sacco Administrator';
    if (roleName.isNotEmpty) return roleName;
    return 'Field Milk Collector';
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}
