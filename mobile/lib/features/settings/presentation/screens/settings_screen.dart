import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/keep_fresh.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/register_staff_dialog.dart';
import '../widgets/set_price_dialog.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../collection/data/datasources/milk_collection_remote_data_source.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool _isFuture(String? dateStr) {
    final parsed = DateTime.tryParse(dateStr ?? '')?.toLocal();
    return parsed != null && parsed.isAfter(DateTime.now());
  }

  /// The price in force today: the latest non-voided price already in effect.
  String? _currentPriceId(List<MilkPriceModel> prices) {
    final inEffect =
        prices.where((p) => p.isActive && !_isFuture(p.effectiveDate)).toList()
          ..sort(
            (a, b) => (b.effectiveDate ?? '').compareTo(a.effectiveDate ?? ''),
          );
    return inEffect.isEmpty ? null : inEffect.first.id;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr.split('T').first;
    final day = parsed.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[parsed.month - 1];
    final year = parsed.year;
    return '$day $month $year';
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saccoProfileAsync = ref.watch(saccoProfileProvider);
    final activePriceAsync = ref.watch(activeMilkPriceProvider);
    final priceHistoryAsync = ref.watch(milkPriceHistoryProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.user;

    final canSetPrice = user?.canSetPrice ?? false;
    final canManageStaff = user?.canManageStaff ?? false;
    final canManageSettings = user?.canManageSettings ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Sacco Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refreshFromServer([
            saccoProfileProvider.future,
            activeMilkPriceProvider.future,
            milkPriceHistoryProvider.future,
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sacco Profile Details Card
                Text(
                  'Dairy Sacco Organization Profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                saccoProfileAsync.when(
                  data: (sacco) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.accentMint,
                                foregroundColor: AppColors.primary,
                                child: const Icon(
                                  Icons.store_rounded,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sacco.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Code: ${sacco.code}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusPill.fromStatusString(sacco.status),
                            ],
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.cardBorder,
                          ),

                          _buildInfoRow(
                            Icons.calendar_today_rounded,
                            'Registration Date',
                            _formatDate(sacco.createdAt),
                          ),
                          if (sacco.email != null &&
                              sacco.email!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.email_outlined,
                              'Email Address',
                              sacco.email!,
                            ),
                          ],
                          if (sacco.phone != null &&
                              sacco.phone!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              'Contact Phone',
                              sacco.phone!,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      _buildLoadingCard('Loading organization profile...'),
                  error: (err, stack) => ErrorView(
                    message: err.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.refresh(saccoProfileProvider.future),
                  ),
                ),
                const SizedBox(height: 22),

                // 2. Active Milk Buying Price & Price History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Milk Buying Price Configuration',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (canSetPrice)
                      activePriceAsync.when(
                        data: (activePrice) => TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'Change Rate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => SetPriceDialog(
                                currentPrice: activePrice.pricePerLitre,
                              ),
                            );
                          },
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Active Buying Rate Card / Setup Banner
                activePriceAsync.when(
                  data: (activePrice) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Intake Price Rate:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'KES ${activePrice.pricePerLitre.toStringAsFixed(2)} / Litre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const StatusPill(
                            status: 'ACTIVE RATE',
                            type: StatusType.success,
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      _buildLoadingCard('Loading milk price configuration...'),
                  error: (err, stack) {
                    final msg = err.toString().replaceAll('Exception: ', '');
                    final isNoPriceConfigured = err is NoMilkPriceException;

                    if (isNoPriceConfigured) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.amber,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No milk price set for today',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              canSetPrice
                                  ? 'Set the milk buying price per litre. Milk cannot be recorded until a price is in force.'
                                  : 'Milk cannot be recorded until a price is set. Ask your Sacco admin to set it.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (canSetPrice) ...[
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Set Initial Buying Price'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const SetPriceDialog(
                                      currentPrice: null,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ErrorView(
                      message: msg,
                      onRetry: () =>
                          ref.refresh(activeMilkPriceProvider.future),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Price History Log
                Text(
                  'Price Rate History Log',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                priceHistoryAsync.when(
                  data: (prices) {
                    if (prices.isEmpty) {
                      return const Text(
                        'No price history entries recorded.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      );
                    }
                    final currentPriceId = _currentPriceId(prices);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prices.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppColors.cardBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = prices[index];
                          // Prices form a schedule: the current one is the latest already in effect.
                          final isCurrentActive = item.id == currentPriceId;
                          final isScheduled = _isFuture(item.effectiveDate);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isCurrentActive
                                  ? AppColors.accentMint
                                  : AppColors.background,
                              foregroundColor: isCurrentActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              child: const Icon(
                                Icons.payments_rounded,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              'KES ${item.pricePerLitre.toStringAsFixed(2)} / Litre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCurrentActive
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Effective Date: ${_formatDate(item.effectiveDate)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            trailing: isCurrentActive
                                ? const StatusPill(
                                    status: 'CURRENT',
                                    type: StatusType.success,
                                  )
                                : isScheduled
                                ? const StatusPill(
                                    status: 'SCHEDULED',
                                    type: StatusType.info,
                                  )
                                : const Text(
                                    'HISTORICAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      _buildLoadingCard('Loading price rate history...'),
                  error: (err, stack) => const Text(
                    'No historical rates recorded.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 24),

                // Sacco rules (admins): milk balance tolerance and when
                // farmers become inactive.
                if (canManageSettings) ...[
                  const _ToleranceCard(),
                  const SizedBox(height: 12),
                  const _InactivityCard(),
                  const SizedBox(height: 24),
                ],

                // 3. Sacco Staff & User Management (Hiddne silently for non-Admins)
                if (canManageStaff) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Sacco Staff & User Management',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Add Staff',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const RegisterStaffDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Registration & Role Assignment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add and provision user accounts for Milk Collectors, Board Members, Executives, and Sacco Admins.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.people_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('All Staff'),
                                onPressed: () => context.push(AppRoutes.staff),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 18,
                                ),
                                label: const Text('Add Staff'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const RegisterStaffDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. User Session & Logout Card
                Text(
                  'User Session & Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  child: Text(
                                    user?.fullName.isNotEmpty == true
                                        ? user!.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.fullName ?? 'Authenticated User',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        user?.email ?? 'User Account',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                            ),
                            tooltip: 'Sign Out',
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.lock_reset_rounded, size: 18),
                          label: const Text('Change My Password / PIN'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const ChangePasswordDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows and edits the Sacco's milk balance tolerance.
class _ToleranceCard extends ConsumerWidget {
  const _ToleranceCard();

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Milk balance tolerance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Litres of measuring difference allowed per collector per day before milk is flagged as missing or oversold.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Litres',
                suffixText: 'L',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v >= 0) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      await ref.read(settingsRepositoryProvider).updateTolerance(value);
      ref.invalidate(saccoSettingsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(saccoSettingsProvider);
    final tolerance = settings.valueOrNull?.reconciliationToleranceLitres ?? 0;
    // A Material (not a decorated Container) so the tap ripple is visible.
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.balance_rounded, color: AppColors.primary),
        title: const Text(
          'Milk balance tolerance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          settings.isLoading
              ? 'Loading…'
              : '${tolerance.toStringAsFixed(1)} L per collector per day',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: settings.hasValue ? () => _edit(context, ref, tolerance) : null,
      ),
    );
  }
}

/// Shows and edits after how many days without milk an active farmer becomes
/// inactive (0 = never). The server checks every farmer daily.
class _InactivityCard extends ConsumerWidget {
  const _InactivityCard();

  static String describe(int days) => days == 0
      ? 'Never: farmers stay active until changed by hand'
      : 'After $days days without milk';

  Future<void> _edit(BuildContext context, WidgetRef ref, int current) async {
    final controller = TextEditingController(text: '$current');
    String? error;
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Mark farmers inactive'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'An active farmer who brings no milk for this many days '
                  'becomes inactive. Their milk is still taken, and taking '
                  'it makes them active again. Enter 0 to never do this.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Days without milk',
                    suffixText: 'days',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                if (v == null || v < 0 || v > 365) {
                  setState(() => error = 'Enter 0 to 365 days');
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (value == null || value == current) return;
    try {
      await ref.read(settingsRepositoryProvider).updateInactiveAfterDays(value);
      ref.invalidate(saccoSettingsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(saccoSettingsProvider);
    final days = settings.valueOrNull?.inactiveAfterDays ?? 60;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(
          Icons.pause_circle_outline_rounded,
          color: AppColors.primary,
        ),
        title: const Text(
          'Mark farmers inactive',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          settings.isLoading ? 'Loading…' : describe(days),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: settings.hasValue ? () => _edit(context, ref, days) : null,
      ),
    );
  }
}
