import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_model.freezed.dart';
part 'member_model.g.dart';

@freezed
class MemberModel with _$MemberModel {
  const MemberModel._();

  const factory MemberModel({
    required String id,
    @JsonKey(name: 'sacco_id') @Default('') String saccoId,
    @JsonKey(name: 'membership_number') @Default('') String membershipNumber,
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    @Default('') String phone,
    String? email,
    String? gender,
    String? location,
    @Default('ACTIVE') String status,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') String? bankBranch,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MemberModel;

  String get fullName => '$firstName $lastName'.trim();

  factory MemberModel.fromJson(Map<String, dynamic> json) =>
      _$MemberModelFromJson(json);
}

@freezed
class CreateMemberRequestModel with _$CreateMemberRequestModel {
  const factory CreateMemberRequestModel({
    @JsonKey(name: 'membership_number') String? membershipNumber,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'national_id') String? nationalId,
    required String phone,
    String? email,
    String? gender,
    String? location,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
  }) = _CreateMemberRequestModel;

  factory CreateMemberRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateMemberRequestModelFromJson(json);
}
