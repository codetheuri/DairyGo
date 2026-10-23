import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/stepped_period.dart';
import '../controllers/report_controller.dart';

/// Chooses the Reports period: Day, Week, Month or Dates, then steps through
/// it with the arrows. Tapping the dates opens a calendar. Every tab follows.
class PeriodBar extends ConsumerWidget {
  const PeriodBar({super.key});

  static Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    SteppedPeriod p,
  ) async {
    final today = DateTime.now();
    final first = DateTime(today.year - 5);
    final set = ref.read(reportPeriodProvider.notifier);
    if (p.kind == PeriodKind.range) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: first,
        lastDate: today,
        initialDateRange: DateTimeRange(
          start: p.from,
          end: p.to.isAfter(today) ? today : p.to,
        ),
        helpText: 'Choose the dates',
      );
      if (range != null) {
        set.state = SteppedPeriod.range(range.start, range.end);
      }
      return;
    }
    final day = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDate: p.from.isAfter(today) ? today : p.from,
      helpText: p.kind == PeriodKind.day
          ? 'Choose the day'
          : 'Choose a day in the ${p.kind.label.toLowerCase()}',
    );
    if (day != null) set.state = SteppedPeriod.of(p.kind, day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final set = ref.read(reportPeriodProvider.notifier);

    void choose(PeriodKind kind) {
      if (kind == period.kind) return;
      if (kind == PeriodKind.range) {
        // Start from what is showing, then let them pick.
        set.state = SteppedPeriod.range(period.from, period.to);
        _pick(context, ref, set.state);
        return;
      }
      // Keep the day in view: today when the period holds it, else its start.
      final today = DateTime.now();
      final anchor = !today.isBefore(period.from) && !today.isAfter(period.to)
          ? today
          : period.from;
      set.state = SteppedPeriod.of(kind, anchor);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Four equal parts: always fits, never scrolls sideways.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                for (final kind in PeriodKind.values)
                  Expanded(
                    child: Semantics(
                      selected: kind == period.kind,
                      button: true,
                      child: Material(
                        color: kind == period.kind
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => choose(kind),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                kind.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kind == period.kind
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Earlier',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => set.state = period.step(-1),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pick(context, ref, period),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            period.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Later',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: period.canStepForward()
                    ? () => set.state = period.step(1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
