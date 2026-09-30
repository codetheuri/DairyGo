import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/cache/keep_fresh.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../transfer_controller.dart';
import 'transfer_detail_sheet.dart';
import 'transfer_tile.dart';

/// The day's transfers on the Sales screen: a "Transfer milk" button, what
/// the collector received and gave, and each transfer with its time.
class TransfersTab extends ConsumerWidget {
  final String dateLabel;

  const TransfersTab({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final userId = user?.id ?? 0;
    final canTransfer = user?.canTransfer ?? false;
    final async = ref.watch(dayTransfersProvider);

    Widget header(double received, double given, bool mine) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canTransfer)
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.recordTransfer),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transfer milk to a collector'),
            ),
          if (mine) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Received',
                    value: '+${litresText(received)}',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Figure(
                    label: 'Given',
                    value: '−${litresText(given)}',
                    color: AppColors.accentAmber,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return async.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorView(
        message: e.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.refresh(dayTransfersProvider.future),
      ),
      data: (transfers) {
        double received = 0, given = 0;
        for (final t in transfers.where((t) => !t.isCancelled)) {
          if (t.toCollectorId == userId) received += t.quantityLitres;
          if (t.fromCollectorId == userId) given += t.quantityLitres;
        }
        // Collectors see their own figures; admins and board members see
        // everyone's transfers, where "mine" means little.
        final mine = !(user?.seesAllRecords ?? false);

        return RefreshIndicator(
          onRefresh: () => ref.refreshFromServer([dayTransfersProvider.future]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              header(received, given, mine),
              if (transfers.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No milk transferred $dateLabel.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'When you hand milk to another collector, record it '
                        'here so both of your balances are right.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final t in transfers)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TransferTile(
                    transfer: t,
                    viewerId: userId,
                    onTap: () => TransferDetailSheet.show(context, t),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
