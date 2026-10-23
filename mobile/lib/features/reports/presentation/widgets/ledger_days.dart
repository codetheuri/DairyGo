import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/balance_badge.dart';
import '../../data/models/report_models.dart';
import '../../domain/stepped_period.dart';
import '../controllers/report_controller.dart';

/// The Ledger's period day by day: what was collected, sold and spoilt, and
/// whether each day balanced. Tapping a day shows that day alone.
class LedgerDays extends ConsumerWidget {
  final List<LedgerDayModel> days;

  const LedgerDays({super.key, required this.days});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (days.isEmpty) return const SizedBox.shrink();
    final toCheck = days.where((d) => d.balanceStatus != 'BALANCED').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day by Day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${days.length} ${days.length == 1 ? 'day' : 'days'} with milk'
          '${toCheck > 0 ? ', $toCheck to check' : ', all balanced'}. '
          'Tap a day to see it alone.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.cardBorder),
                _DayRow(day: days[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayRow extends ConsumerWidget {
  final LedgerDayModel day;

  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.tryParse(day.date);
    final label = date == null
        ? day.date
        : '${LedgerDays._weekdays[date.weekday - 1]} ${date.day} ${LedgerDays._months[date.month - 1]}';
    return InkWell(
      onTap: date == null
          ? null
          : () => ref.read(reportPeriodProvider.notifier).state =
                SteppedPeriod.of(PeriodKind.day, date),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wraps at large text sizes instead of running off.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      BalanceBadge(
                        unaccountedLitres: day.unaccountedLitres,
                        status: day.balanceStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'In ${litres(day.collectedLitres)} • Sold ${litres(day.soldLitres)}'
                    '${day.spoiledLitres > 0 ? ' • Spoilt ${litres(day.spoiledLitres)}' : ''}'
                    ' • ${kes(day.salesKes, cents: false)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
