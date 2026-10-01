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

    /// What the user's role may do, as the server lists it with the profile.
    /// Empty for a profile saved by an older version of the app.
    @Default(<String>[]) List<String> permissions,
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
    return lower.contains('board') ||
        lower.contains('executive') ||
        lower.contains('admin');
  }

  bool get isSaccoAdmin {
    if (isSuperUser) return true;
    final lower = roleName.toLowerCase();
    return lower.contains('admin');
  }

  /// The Sacco role as the server numbers it: 1 administrator, 2 collector,
  /// 3 board member.
  int get saccoRoleId {
    if (isSaccoAdmin) return 1;
    if (isExecutive) return 3;
    return 2;
  }

  /// Whether the user's role holds [permission]. The screens ask this, not
  /// the role's name, so what a role may do can change on the server without
  /// a new app version. [whenUnknown] is used only for a profile saved
  /// before permissions were sent with it.
  bool can(String permission, {required bool whenUnknown}) {
    if (isSuperUser) return true;
    if (permissions.isEmpty) return whenUnknown;
    return permissions.contains(permission);
  }

  bool get _records => isSaccoAdmin || !isExecutive;

  /// Sees every collector's records, not only their own.
  bool get seesAllRecords =>
      can('milk.records.read_all', whenUnknown: isExecutive);
  bool get seesExecutiveDashboard =>
      can('dashboard.executive.read', whenUnknown: isExecutive);
  bool get seesCollectorAudit =>
      can('reports.collector.read', whenUnknown: isExecutive);
  bool get seesLedger =>
      can('reports.reconciliation.read', whenUnknown: isExecutive);
  bool get seesPayouts => can('reports.payout.read', whenUnknown: isExecutive);
  bool get seesReports => seesCollectorAudit || seesLedger || seesPayouts;

  bool get canRecordMilk =>
      can('milk.collections.create', whenUnknown: _records);
  bool get canManageCollections =>
      can('milk.collections.manage', whenUnknown: isSaccoAdmin);
  bool get canSell => can('milk.sales.create', whenUnknown: _records);
  bool get canManageSales =>
      can('milk.sales.manage', whenUnknown: isSaccoAdmin);
  bool get canTransfer => can('milk.transfers.create', whenUnknown: _records);
  bool get canManageTransfers =>
      can('milk.transfers.manage', whenUnknown: isSaccoAdmin);

  bool get canRegisterFarmers => can('members.create', whenUnknown: _records);
  bool get canEditFarmers => can('members.update', whenUnknown: isSaccoAdmin);

  /// Change the Sacco's settings (milk balance tolerance, farmer inactivity).
  bool get canManageSettings =>
      can('sacco.settings.manage', whenUnknown: isSaccoAdmin);

  /// Make farmers active, inactive or suspended.
  bool get canChangeFarmerStatus =>
      can('members.update_status', whenUnknown: isSaccoAdmin);

  bool get canAddCustomers => can('customers.create', whenUnknown: _records);
  bool get canEditCustomers =>
      can('customers.update', whenUnknown: isSaccoAdmin);
  bool get seesCustomerBalances =>
      can('customers.statement.read', whenUnknown: isExecutive);
  bool get canRecordPayments =>
      can('customers.payments.manage', whenUnknown: isSaccoAdmin);

  bool get canManageStaff => can('users.read', whenUnknown: isSaccoAdmin);

  // Farmer pay: pay runs, accounts, advances, deductions.
  bool get seesPayRuns => can('payouts.read', whenUnknown: false);
  bool get canManageDeductions =>
      can('payouts.deductions.manage', whenUnknown: false);
  bool get canGiveAdvances =>
      can('payouts.advances.manage', whenUnknown: false);
  bool get canRecordCharges =>
      can('payouts.charges.manage', whenUnknown: false);
  bool get canPreparePayRuns => can('payouts.runs.manage', whenUnknown: false);
  bool get canApprovePayRuns => can('payouts.runs.approve', whenUnknown: false);
  bool get canPayFarmers => can('payouts.runs.pay', whenUnknown: false);

  // The Sacco's own money: accounts, expenses, income and expenditure.
  bool get seesFinance => can('finance.read', whenUnknown: false);
  bool get canRecordExpenses =>
      can('finance.expenses.manage', whenUnknown: false);
  bool get canManageAccounts =>
      can('finance.accounts.manage', whenUnknown: false);
  bool get canSetPrice => can('milk.prices.manage', whenUnknown: isSaccoAdmin);

  String get displayRole {
    if (isSuperUser) return 'Platform Administrator';
    if (roleName.isNotEmpty) return roleName;
    return 'Field Milk Collector';
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}
