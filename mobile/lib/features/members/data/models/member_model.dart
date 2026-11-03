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
    // How the farmer is paid: MPESA (M-Pesa number, or the phone) or BANK.
    @JsonKey(name: 'payout_method') @Default('MPESA') String payoutMethod,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') String? bankBranch,
    @JsonKey(name: 'next_of_kin_name') String? nextOfKinName,
    @JsonKey(name: 'next_of_kin_relationship') String? nextOfKinRelationship,
    @JsonKey(name: 'next_of_kin_phone') String? nextOfKinPhone,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MemberModel;

  String get fullName => '$firstName $lastName'.trim();

  /// False for farmers registered before next of kin was collected.
  bool get hasNextOfKin => (nextOfKinName ?? '').trim().isNotEmpty;

  bool get paidByBank => payoutMethod == 'BANK';

  /// The number M-Pesa pay goes to: the M-Pesa number, else the phone.
  String get mpesaPhone {
    final own = (mpesaNumber ?? '').trim();
    return own.isNotEmpty ? own : phone.trim();
  }

  /// Where the farmer's pay goes, or what is missing (as on the payouts
  /// report; backend pkg/payto).
  String get payTo {
    if (paidByBank) {
      final account = (bankAccountNumber ?? '').trim();
      if (account.isEmpty) return 'Bank: account missing';
      return [
        (bankName ?? '').trim().isEmpty ? 'Bank' : bankName!.trim(),
        account,
        (bankBranch ?? '').trim(),
      ].where((s) => s.isNotEmpty).join(' ');
    }
    final number = mpesaPhone;
    return number.replaceAll(RegExp(r'[^0-9]'), '').length >= 10
        ? 'M-Pesa $number'
        : 'M-Pesa: number missing';
  }

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
    @JsonKey(name: 'payout_method') String? payoutMethod,
    @JsonKey(name: 'mpesa_number') String? mpesaNumber,
    @JsonKey(name: 'mpesa_name') String? mpesaName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_account_number') String? bankAccountNumber,
    @JsonKey(name: 'bank_branch') String? bankBranch,
    @JsonKey(name: 'next_of_kin_name') required String nextOfKinName,
    @JsonKey(name: 'next_of_kin_relationship')
    required String nextOfKinRelationship,
    @JsonKey(name: 'next_of_kin_phone') required String nextOfKinPhone,
  }) = _CreateMemberRequestModel;

  factory CreateMemberRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateMemberRequestModelFromJson(json);
}
