import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/collection/presentation/controllers/collection_controller.dart';
import '../../features/customers/presentation/controllers/customer_controller.dart';
import '../../features/field_operations/presentation/controllers/field_ops_controller.dart';
import '../../features/members/presentation/controllers/member_controller.dart';
import '../../features/reports/presentation/controllers/report_controller.dart';
import 'app_destinations.dart';

/// Loads the data behind the role's bottom-bar tabs shortly after the app
/// opens, so the first tap on each tab shows data at once instead of a
/// spinner. It waits a moment so the home screen loads first, and only
/// fetches what that role's tabs show.
class TabWarmUp extends ConsumerStatefulWidget {
  final Widget child;

  const TabWarmUp({super.key, required this.child});

  @override
  ConsumerState<TabWarmUp> createState() => _TabWarmUpState();
}

class _TabWarmUpState extends ConsumerState<TabWarmUp> {
  static const _delay = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    Future.delayed(_delay, _warmUp);
  }

  void _warmUp() {
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) return;
    for (final section in RoleNavigation.of(user).bar) {
      final futures = switch (section) {
        AppSection.intake => [ref.read(milkCollectionsListProvider.future)],
        AppSection.sales => [
          ref.read(salesListProvider.future),
          ref.read(spoilageListProvider.future),
        ],
        AppSection.farmers => [ref.read(membersListProvider.future)],
        AppSection.customers => [
          ref.read(customersListProvider.future),
          ref.read(customerBalancesProvider.future),
        ],
        AppSection.reports => [ref.read(farmerPayoutReportProvider.future)],
        _ => const <Future<Object?>>[],
      };
      // Errors show when the tab is opened; here they are not needed.
      for (final f in futures) {
        f.ignore();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
