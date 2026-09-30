import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/breakpoints.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import 'app_destinations.dart';
import 'shell_back_handler.dart';
import 'tab_warm_up.dart';

/// The frame around the main sections. It adapts to the screen width:
/// - phones: a bottom bar with the role's five sections;
/// - tablets and phones in landscape: a side rail with every section;
/// - large tablets and desktops: the rail expands to show labels beside icons.
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _open(AppSection section) {
    navigationShell.goBranch(
      section.branch,
      // Tapping the current section again returns to its first screen.
      initialLocation: section.branch == navigationShell.currentIndex,
    );
  }

  /// The highlighted entry: the current section, or More when the current
  /// section is only reachable from the More page.
  static int _selectedIndex(List<AppSection> items, AppSection current) {
    final i = items.indexOf(current);
    return i >= 0 ? i : items.indexOf(AppSection.more);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authControllerProvider.select((s) => s.valueOrNull?.user),
    );
    final nav = RoleNavigation.of(user);
    final current = AppSection.values[navigationShell.currentIndex];
    final body = TabWarmUp(child: navigationShell);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < Breakpoints.medium;

    // The phone's back button on a section never closes the app by surprise.
    return ShellBackHandler(
      onHome: current == AppSection.home,
      // On a phone, sections missing from the bar are opened from More.
      openedFromMore: compact && !nav.bar.contains(current),
      goHome: () => navigationShell.goBranch(AppSection.home.branch),
      goMore: () => navigationShell.goBranch(AppSection.more.branch),
      child: _frame(nav, current, body, compact, width),
    );
  }

  Widget _frame(
    RoleNavigation nav,
    AppSection current,
    Widget body,
    bool compact,
    double width,
  ) {
    if (compact) {
      return Scaffold(
        body: body,
        // Bar labels stay one line: they barely grow with the phone's font
        // setting (the icons carry the meaning), as Material recommends.
        bottomNavigationBar: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.1,
          child: NavigationBar(
            selectedIndex: _selectedIndex(nav.bar, current),
            onDestinationSelected: (i) => _open(nav.bar[i]),
            indicatorColor: AppColors.accentMint,
            backgroundColor: Colors.white,
            elevation: 8,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final s in nav.bar)
                NavigationDestination(
                  icon: Icon(s.icon),
                  selectedIcon: Icon(s.selectedIcon, color: AppColors.primary),
                  label: s.barLabel,
                  tooltip: s.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = width >= Breakpoints.expanded;
    final items = nav.rail;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Scrolls when the screen is too short for every entry, e.g. a
            // phone in landscape.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 200,
                      backgroundColor: Colors.white,
                      indicatorColor: AppColors.accentMint,
                      labelType: extended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      selectedIndex: _selectedIndex(items, current),
                      onDestinationSelected: (i) => _open(items[i]),
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: extended
                            ? const Text(
                                'DairyGo',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.water_drop_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                      ),
                      destinations: [
                        for (final s in items)
                          NavigationRailDestination(
                            icon: Icon(s.icon),
                            selectedIcon: Icon(
                              s.selectedIcon,
                              color: AppColors.primary,
                            ),
                            label: Text(s.label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.cardBorder,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
