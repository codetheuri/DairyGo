import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/shell/app_destinations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../app_update/presentation/widgets/app_update_tile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/presentation/widgets/change_password_dialog.dart';

/// Everything that does not fit in the bottom bar: the role's other sections,
/// settings, staff, the user's account and signing out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _descriptions = {
    AppSection.customers: 'Coolers and buyers, balances and payments',
    AppSection.reports: 'Farmer payouts, Sacco ledger and collector audit',
    AppSection.intake: 'Milk intake records',
    AppSection.sales: 'Sales and spoilage records',
  };

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your password to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authControllerProvider.select((s) => s.valueOrNull?.user),
    );
    final nav = RoleNavigation.of(user);
    final shell = StatefulNavigationShell.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ReadableWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user?.fullName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(user?.displayRole ?? ''),
                ),
                const Divider(),
                for (final section in nav.overflow)
                  ListTile(
                    leading: Icon(section.icon, color: AppColors.primary),
                    title: Text(section.label),
                    subtitle: Text(_descriptions[section] ?? ''),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => shell?.goBranch(section.branch),
                  ),
                if (nav.overflow.isNotEmpty) const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Settings'),
                  subtitle: Text(
                    (user?.canSetPrice ?? false)
                        ? 'Sacco profile, milk prices, tolerance'
                        : 'Sacco profile and milk price',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.settings),
                ),
                if (user?.canManageStaff ?? false)
                  ListTile(
                    leading: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Staff'),
                    subtitle: const Text(
                      'Collectors, admins and board members',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.staff),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Change password'),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const ChangePasswordDialog(),
                  ),
                ),
                const AppUpdateTile(),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
