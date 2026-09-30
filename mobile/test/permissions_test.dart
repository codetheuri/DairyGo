// What the app shows follows the permissions sent with the user's profile,
// not the name of their role, so an operator can change what a role may do
// without a new app version.

import 'package:dairy_sacco_mobile/app/shell/app_destinations.dart';
import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(String role, [List<String> permissions = const []]) =>
    UserEntity(
      id: 1,
      email: 'a@b.c',
      username: 'u',
      roleName: role,
      permissions: permissions,
    );

void main() {
  group('with permissions from the server', () {
    test('a collector given a report sees Reports', () {
      final collector = _user('Milk Collector', [
        'milk.collections.create',
        'reports.collector.read',
      ]);
      expect(collector.seesReports, isTrue);
      expect(collector.seesCollectorAudit, isTrue);
      expect(collector.seesLedger, isFalse);
      expect(
        RoleNavigation.of(collector).overflow,
        contains(AppSection.reports),
      );
      // Still a recorder: intake stays on the bar.
      expect(RoleNavigation.of(collector).bar, contains(AppSection.intake));
    });

    test('an administrator loses what is taken away', () {
      final admin = _user('Sacco Administrator', [
        'milk.collections.create',
        'users.read',
      ]);
      expect(admin.canManageStaff, isTrue);
      expect(admin.canSetPrice, isFalse);
      expect(admin.canManageSales, isFalse);
      expect(admin.seesAllRecords, isFalse);
      expect(admin.seesReports, isFalse);
    });

    test('a board member allowed to record gets the recorder layout', () {
      final board = _user('Board Member / Executive', [
        'milk.collections.create',
        'milk.records.read_all',
        'reports.payout.read',
      ]);
      expect(board.canRecordMilk, isTrue);
      expect(RoleNavigation.of(board).bar, contains(AppSection.intake));
      expect(RoleNavigation.of(board).overflow, contains(AppSection.reports));
    });

    test('the usual board member oversees', () {
      final board = _user('Board Member / Executive', [
        'milk.records.read_all',
        'dashboard.executive.read',
        'reports.payout.read',
        'customers.statement.read',
      ]);
      expect(board.canRecordMilk, isFalse);
      expect(board.canTransfer, isFalse);
      expect(board.seesCustomerBalances, isTrue);
      expect(RoleNavigation.of(board).bar, contains(AppSection.reports));
      expect(RoleNavigation.of(board).overflow, contains(AppSection.intake));
    });

    test('a platform operator may do everything', () {
      final operator = _user('').copyWith(isSuperUser: true);
      expect(operator.canManageStaff, isTrue);
      expect(operator.seesAllRecords, isTrue);
      expect(operator.can('anything.at.all', whenUnknown: false), isTrue);
    });
  });

  group('a profile saved before permissions were sent', () {
    test('falls back to the role name, as older versions did', () {
      final admin = _user('Sacco Administrator');
      expect(admin.canManageStaff, isTrue);
      expect(admin.canSetPrice, isTrue);
      expect(admin.seesAllRecords, isTrue);
      expect(admin.canRecordMilk, isTrue);

      final collector = _user('Milk Collector');
      expect(collector.canRecordMilk, isTrue);
      expect(collector.canTransfer, isTrue);
      expect(collector.seesReports, isFalse);
      expect(collector.seesAllRecords, isFalse);
      expect(collector.canManageStaff, isFalse);

      final board = _user('Board Member / Executive');
      expect(board.canRecordMilk, isFalse);
      expect(board.seesReports, isTrue);
      expect(board.seesAllRecords, isTrue);
      expect(board.canRecordPayments, isFalse);
    });
  });
}
