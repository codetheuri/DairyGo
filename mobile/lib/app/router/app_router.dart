import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/collection/presentation/screens/daily_collection_history_screen.dart';
import '../../features/collection/presentation/screens/record_milk_intake_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/field_operations/presentation/screens/field_operations_history_screen.dart';
import '../../features/field_operations/presentation/screens/record_field_sale_screen.dart';
import '../../features/field_operations/presentation/screens/record_spoilage_screen.dart';
import '../../features/members/presentation/screens/farmer_directory_screen.dart';
import '../../features/members/presentation/screens/farmer_profile_screen.dart';
import '../../features/members/presentation/screens/register_farmer_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/staff_management_screen.dart';
import '../shell/main_shell_screen.dart';

abstract class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String members = '/members';
  static const String registerMember = '/members/register';
  static const String collections = '/collections';
  static const String recordCollection = '/collections/record';
  static const String recordSale = '/field-sales/record';
  static const String recordSpoilage = '/spoilage/record';
  static const String fieldOperations = '/field-operations';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String staff = '/settings/staff';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      if (authState.isLoading) {
        return AppRoutes.splash;
      }

      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplashing = state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      if (isLoggedIn && (isLoggingIn || isSplashing)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Intake & Collections
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.collections,
                builder: (context, state) => const DailyCollectionHistoryScreen(),
              ),
            ],
          ),
          // Branch 2: Field Sales & Spoilage
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fieldOperations,
                builder: (context, state) => const FieldOperationsHistoryScreen(),
              ),
            ],
          ),
          // Branch 3: Farmers Directory
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.members,
                builder: (context, state) => const FarmerDirectoryScreen(),
              ),
            ],
          ),
          // Branch 4: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Stacked Sub-Routes (Pushed over Shell)
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerMember,
        builder: (context, state) => const RegisterFarmerScreen(),
      ),
      GoRoute(
        path: '/members/:id',
        builder: (context, state) {
          final memberId = state.pathParameters['id'] ?? '';
          return FarmerProfileScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: AppRoutes.recordCollection,
        builder: (context, state) {
          final memberId = state.uri.queryParameters['memberId'];
          return RecordMilkIntakeScreen(initialMemberId: memberId);
        },
      ),
      GoRoute(
        path: AppRoutes.recordSale,
        builder: (context, state) => const RecordFieldSaleScreen(),
      ),
      GoRoute(
        path: AppRoutes.recordSpoilage,
        builder: (context, state) => const RecordSpoilageScreen(),
      ),
    ],
  );
});
