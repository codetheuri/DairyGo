import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/user_entity.dart';

/// The top-level sections of the app. Each is one branch of the shell route,
/// so it keeps its own navigation stack and scroll position; the order here
/// must match the branch order in app_router.dart.
enum AppSection {
  home('Home', Icons.dashboard_outlined, Icons.dashboard_rounded),
  intake('Intake', Icons.water_drop_outlined, Icons.water_drop_rounded),
  sales('Sales', Icons.storefront_outlined, Icons.storefront_rounded),
  farmers('Farmers', Icons.people_outline_rounded, Icons.people_rounded),
  reports('Reports', Icons.description_outlined, Icons.description_rounded),
  customers(
    'Customers',
    Icons.handshake_outlined,
    Icons.handshake_rounded,
    shortLabel: 'Buyers',
  ),
  more('More', Icons.menu_rounded, Icons.menu_open_rounded);

  /// Short, one-word labels so a phone's bottom bar never wraps.
  final String label;

  /// A shorter label for the phone's bottom bar, where a fifth of a small
  /// screen cannot fit a long word.
  final String? shortLabel;
  String get barLabel => shortLabel ?? label;
  final IconData icon;
  final IconData selectedIcon;

  const AppSection(this.label, this.icon, this.selectedIcon, {this.shortLabel});

  int get branch => index;
}

/// Which sections a user sees, split into the phone's bottom bar (at most five,
/// always ending with More) and the rest, which are listed on the More page.
/// On wide screens the side rail shows every section directly.
class RoleNavigation {
  final List<AppSection> bar;
  final List<AppSection> overflow;

  const RoleNavigation({required this.bar, required this.overflow});

  /// Every section for the side rail: the bar's sections, then the overflow,
  /// with More last.
  List<AppSection> get rail => [
    ...bar.where((s) => s != AppSection.more),
    ...overflow,
    AppSection.more,
  ];

  factory RoleNavigation.of(UserEntity? user) {
    final records = user?.canRecordMilk ?? true;
    final reports = user?.seesReports ?? false;

    if (!records && reports) {
      // Those who oversee rather than record (board members): reports and
      // balances first.
      return const RoleNavigation(
        bar: [
          AppSection.home,
          AppSection.reports,
          AppSection.farmers,
          AppSection.customers,
          AppSection.more,
        ],
        overflow: [AppSection.intake, AppSection.sales],
      );
    }
    return RoleNavigation(
      bar: const [
        AppSection.home,
        AppSection.intake,
        AppSection.sales,
        AppSection.farmers,
        AppSection.more,
      ],
      overflow: [AppSection.customers, if (reports) AppSection.reports],
    );
  }
}
