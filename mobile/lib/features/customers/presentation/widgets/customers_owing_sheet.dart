import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/skeleton.dart';
import '../controllers/customer_controller.dart';

/// The customers who owe the Sacco money now, largest debt first. Tapping
/// one opens their statement.
class CustomersOwingSheet extends ConsumerWidget {
  const CustomersOwingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const CustomersOwingSheet(),
    );
  }

  static String _kes(double amount) => 'KES ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerBalancesProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: async.when(
          loading: () => const ListSkeleton(rows: 4),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (data) {
            final owing = data.balances.where((b) => b.balance > 0).toList()
              ..sort((a, b) => b.balance.compareTo(a.balance));
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customers who owe you',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  owing.isEmpty
                      ? 'Nobody owes the Sacco anything now.'
                      : '${owing.length} '
                            '${owing.length == 1 ? 'customer owes' : 'customers owe'} '
                            '${_kes(data.totalOwed)} in total. '
                            'Tap one to see their statement.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: owing.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = owing[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push('/customers/${c.customerId}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _kes(c.balance),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      if (c.phone != null &&
                                          c.phone!.isNotEmpty)
                                        Text(
                                          c.phone!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
