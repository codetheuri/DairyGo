import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/offline_banner_overlay.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../theme/app_colors.dart';

class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;
    final isExecutive = user?.isExecutive ?? false;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.water_drop_outlined),
        selectedIcon: Icon(Icons.water_drop_rounded, color: AppColors.primary),
        label: 'Intake',
      ),
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
        label: 'Sales & Loss',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
        label: 'Farmers',
      ),
      if (isExecutive)
        const NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
          label: 'Reports',
        ),
    ];

    final currentIndex = navigationShell.currentIndex < destinations.length
        ? navigationShell.currentIndex
        : destinations.length - 1;

    return Scaffold(
      body: OfflineBannerOverlay(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: _onTap,
        indicatorColor: AppColors.accentMint,
        elevation: 8,
        backgroundColor: Colors.white,
        destinations: destinations,
      ),
    );
  }
}
