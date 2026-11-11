import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/books/presentation/screens/account_ledger_screen.dart';
import '../../features/books/presentation/screens/balance_sheet_screen.dart';
import '../../features/books/presentation/screens/books_screen.dart';
import '../../features/books/presentation/screens/chart_screen.dart';
import '../../features/books/presentation/screens/income_statement_screen.dart';
import '../../features/books/presentation/screens/journal_screen.dart';
import '../../features/books/presentation/screens/journals_screen.dart';
import '../../features/books/presentation/screens/links_screen.dart';
import '../../features/books/presentation/screens/new_journal_screen.dart';
import '../../features/books/presentation/screens/trial_balance_screen.dart';
import '../../features/finance/presentation/screens/cashbook_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/payouts/presentation/screens/deductions_screen.dart';
import '../../features/payouts/presentation/screens/farmer_account_screen.dart';
import '../../features/payouts/presentation/screens/pay_run_detail_screen.dart';
import '../../features/payouts/presentation/screens/pay_runs_screen.dart';
import '../../features/report_downloads/presentation/screens/report_downloads_screen.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/collection/presentation/screens/daily_collection_history_screen.dart';
import '../../features/collection/presentation/screens/record_milk_intake_screen.dart';
import '../../features/customers/data/models/customer_models.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/field_operations/presentation/screens/field_operations_history_screen.dart';
import '../../features/field_operations/presentation/screens/record_field_sale_screen.dart';
import '../../features/field_operations/presentation/screens/record_spoilage_screen.dart';
import '../../features/transfers/presentation/screens/record_transfer_screen.dart';
import '../../features/members/presentation/screens/farmer_directory_screen.dart';
import '../../features/members/presentation/screens/edit_farmer_screen.dart';
import '../../features/members/presentation/screens/farmer_profile_screen.dart';
import '../../features/members/presentation/screens/register_farmer_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/staff_management_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/auth/domain/entities/auth_state.dart';
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
  static const String recordTransfer = '/transfers/record';
  static const String fieldOperations = '/field-operations';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String staff = '/settings/staff';
  static const String customers = '/customers';
  static const String more = '/more';
  static const String reportDownloads = '/report-downloads';
  static const String payouts = '/payouts';
  static const String deductions = '/payouts/deductions';
  static const String finance = '/finance';
  // The accountant's tabs show the same screens as /finance and /payouts.
  static const String money = '/money';
  static const String pay = '/pay';
  // The books: the accountant's tab, and the same screen pushed for others.
  static const String ledger = '/ledger';
  static const String books = '/books';
}

/// The router is created once. Sign-in changes reach it through
/// [GoRouter.refreshListenable], which re-runs the redirect without
/// rebuilding the router, so open screens and tab history survive.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AsyncValue<AuthState>>(
    ref.read(authControllerProvider),
  );
  ref.listen(authControllerProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = auth.value;
      // Splash only while the saved session is checked at start-up; during
      // sign-in the login screen stays up and shows its own spinner.
      if (authState.isLoading && !authState.hasValue) {
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
                builder: (context, state) =>
                    const DailyCollectionHistoryScreen(),
              ),
            ],
          ),
          // Branch 2: Field Sales & Spoilage
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fieldOperations,
                builder: (context, state) =>
                    const FieldOperationsHistoryScreen(),
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
          // Branch 5: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customers,
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),
          // Branch 6: Money (the accountant's tab; others use /finance)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.money,
                builder: (context, state) => const FinanceScreen(),
              ),
            ],
          ),
          // Branch 7: Farmer pay (the accountant's tab; others use /payouts)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pay,
                builder: (context, state) => const PayRunsScreen(),
              ),
            ],
          ),
          // Branch 8: Books (the accountant's tab; others use /books)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ledger,
                builder: (context, state) => const BooksScreen(),
              ),
            ],
          ),
          // Branch 9: More (settings, staff, account)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MoreScreen(),
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
        path: AppRoutes.reportDownloads,
        builder: (context, state) => const ReportDownloadsScreen(),
      ),
      GoRoute(
        path: AppRoutes.payouts,
        builder: (context, state) => const PayRunsScreen(),
      ),
      GoRoute(
        path: AppRoutes.deductions,
        builder: (context, state) => const DeductionsScreen(),
      ),
      GoRoute(
        path: '/payouts/runs/:id',
        builder: (context, state) =>
            PayRunDetailScreen(runId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (context, state) => const FinanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.books,
        builder: (context, state) => const BooksScreen(),
      ),
      GoRoute(
        path: '/books/income-statement',
        builder: (context, state) => const IncomeStatementScreen(),
      ),
      GoRoute(
        path: '/books/balance-sheet',
        builder: (context, state) => const BalanceSheetScreen(),
      ),
      GoRoute(
        path: '/books/trial-balance',
        builder: (context, state) => const TrialBalanceScreen(),
      ),
      GoRoute(
        path: '/books/journals',
        builder: (context, state) => const JournalsScreen(),
      ),
      GoRoute(
        path: '/books/journals/new',
        builder: (context, state) => const NewJournalScreen(),
      ),
      GoRoute(
        path: '/books/journals/:id',
        builder: (context, state) =>
            JournalScreen(journalId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/books/accounts',
        builder: (context, state) => const ChartScreen(),
      ),
      GoRoute(
        path: '/books/accounts/:id',
        builder: (context, state) =>
            AccountLedgerScreen(accountId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/books/links',
        builder: (context, state) => const LinksScreen(),
      ),
      GoRoute(
        path: '/finance/accounts/:id',
        builder: (context, state) =>
            CashbookScreen(accountId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/members/:id/account',
        builder: (context, state) =>
            FarmerAccountScreen(memberId: state.pathParameters['id'] ?? ''),
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
        path: '/members/:id/edit',
        builder: (context, state) =>
            EditFarmerScreen(memberId: state.pathParameters['id'] ?? ''),
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
        builder: (context, state) => RecordFieldSaleScreen(
          initialCustomer: state.extra is CustomerModel
              ? state.extra as CustomerModel
              : null,
        ),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.recordSpoilage,
        builder: (context, state) => const RecordSpoilageScreen(),
      ),
      GoRoute(
        path: AppRoutes.recordTransfer,
        builder: (context, state) => const RecordTransferScreen(),
      ),
    ],
  );
});
