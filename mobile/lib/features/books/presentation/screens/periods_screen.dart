import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// Closing the books month by month, and the year end. A closed month's
/// figures never change: a record changed there later posts its correction
/// on the first open day. Reopening needs a reason, kept in the history.
class PeriodsScreen extends ConsumerWidget {
  const PeriodsScreen({super.key});

  static final _month = DateFormat('MMMM y');
  static final _day = DateFormat('d MMM y');

  static String yearName(DateTime from, DateTime to) => from.month == 1
      ? '${from.year}'
      : '${DateFormat('MMM y').format(from)} – ${DateFormat('MMM y').format(to)}';

  Future<void> _do(
    BuildContext context,
    WidgetRef ref,
    Future<Periods> Function() action,
    String done,
  ) async {
    try {
      await action();
      refreshBooks(ref);
      if (context.mounted) showBooksDone(context, done);
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
    String action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _close(
    BuildContext context,
    WidgetRef ref,
    PeriodMonth m,
  ) async {
    final ok = await _confirm(
      context,
      'Close the books through ${_month.format(m.from)}?',
      'The books are brought up to date first and must agree with the records. '
          'Afterwards nothing can be dated on or before ${_day.format(m.to)}: a record '
          'changed there posts its correction on the first open day, so the figures '
          'of closed months never change. You can reopen with a reason.',
      'Close',
    );
    if (!ok || !context.mounted) return;
    await _do(
      context,
      ref,
      () => ref.read(booksServiceProvider).close(m.to),
      'Closed through ${_month.format(m.from)}',
    );
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref, Periods p) async {
    final closed = [
      for (final m in p.months)
        if (m.closed) m,
    ];
    final result = await showDialog<(DateTime?, String)>(
      context: context,
      builder: (_) => _ReopenDialog(closed: closed),
    );
    if (result == null || !context.mounted) return;
    await _do(
      context,
      ref,
      () => ref.read(booksServiceProvider).reopen(result.$1, result.$2),
      'Reopened',
    );
  }

  Future<void> _yearEnd(
    BuildContext context,
    WidgetRef ref,
    PeriodYear y,
  ) async {
    final word = y.surplus < 0 ? 'deficit' : 'surplus';
    final ok = await _confirm(
      context,
      'Close the financial year ${yearName(y.from, y.to)}?',
      'Its $word of ${kes(y.surplus.abs())} moves to Retained surplus in one journal on '
          '${_day.format(y.to)}, so the next year\'s income statement starts from nothing. '
          'Every month of the year is closed with it. The year\'s own income statement '
          'still shows the year.',
      'Close the year',
    );
    if (!ok || !context.mounted) return;
    await _do(
      context,
      ref,
      () => ref.read(booksServiceProvider).yearEnd(y.to),
      'Financial year closed',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(periodsProvider);
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Months and years',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: periods.when(
        loading: () => const ListSkeleton(rows: 6),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(periodsProvider),
        ),
        data: (p) {
          // The next month to close: the oldest open month that is over.
          final open = [
            for (final m in p.months)
              if (!m.closed && m.ended) m,
          ];
          final next = open.isEmpty ? null : open.last;
          // The next year to close: the oldest ended year not closed.
          final years = [
            for (final y in p.years)
              if (y.ended && !y.closed) y,
          ];
          final nextYear = years.isEmpty ? null : years.last;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(periodsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                ReadableWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BooksCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                p.closedThrough == null
                                    ? 'No month is closed'
                                    : 'Closed through ${_day.format(p.closedThrough!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.yearClosedThrough == null
                                    ? 'No financial year closed yet.'
                                    : 'Financial years closed through ${_day.format(p.yearClosedThrough!)}.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (canManage) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (next != null)
                                      FilledButton.icon(
                                        onPressed: () =>
                                            _close(context, ref, next),
                                        icon: const Icon(Icons.lock_rounded),
                                        label: Text(
                                          'Close ${_month.format(next.from)}',
                                        ),
                                      ),
                                    if (p.closedThrough != null)
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _reopen(context, ref, p),
                                        icon: const Icon(
                                          Icons.lock_open_rounded,
                                        ),
                                        label: const Text('Reopen'),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const _Heading('Financial years'),
                      BooksCard(
                        child: Column(
                          children: [
                            for (final y in p.years) ...[
                              ListTile(
                                leading: Icon(
                                  y.closed
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  color: y.closed
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                                title: Text(yearName(y.from, y.to)),
                                subtitle: Text(
                                  [
                                    '${y.surplus < 0 ? 'Deficit' : 'Surplus'} ${kes(y.surplus.abs(), cents: false)}',
                                    y.closed
                                        ? 'closed'
                                        : y.ended
                                        ? 'over, not closed'
                                        : 'running',
                                  ].join(' · '),
                                ),
                                trailing: canManage && identical(y, nextYear)
                                    ? TextButton(
                                        onPressed: () =>
                                            _yearEnd(context, ref, y),
                                        child: const Text('Close'),
                                      )
                                    : null,
                              ),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                      const _Heading('Months'),
                      BooksCard(
                        child: Column(
                          children: [
                            for (final m in p.months) ...[
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  m.closed
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  size: 20,
                                  color: m.closed
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                                title: Text(_month.format(m.from)),
                                trailing: Text(
                                  m.closed
                                      ? 'Closed'
                                      : m.ended
                                      ? 'Open'
                                      : 'This month',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                      const _Heading('History'),
                      if (p.history.isEmpty)
                        const Text(
                          'Nothing closed or reopened yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      for (final e in p.history)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_eventTitle(e)),
                          subtitle: Text(
                            [
                              DateFormat('d MMM y, HH:mm').format(e.at),
                              if ((e.by ?? '').isNotEmpty) e.by!,
                              if ((e.reason ?? '').isNotEmpty) e.reason!,
                            ].join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _eventTitle(PeriodEvent e) => switch (e.action) {
    'CLOSE' => 'Closed through ${_day.format(e.through!)}',
    'YEAR_END' =>
      'Year closed on ${_day.format(e.through!)}'
          '${e.amount == null ? '' : ': ${kes(e.amount!, cents: false)} to retained surplus'}',
    _ =>
      e.through == null
          ? 'Every month reopened'
          : 'Reopened after ${_day.format(e.through!)}',
  };
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

/// Chooses how far back to reopen, and why.
class _ReopenDialog extends StatefulWidget {
  final List<PeriodMonth> closed; // newest first

  const _ReopenDialog({required this.closed});

  @override
  State<_ReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<_ReopenDialog> {
  late PeriodMonth _from = widget.closed.first;
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reopen months'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<PeriodMonth>(
            initialValue: _from,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Reopen from'),
            items: [
              for (final m in widget.closed)
                DropdownMenuItem(
                  value: m,
                  child: Text(PeriodsScreen._month.format(m.from)),
                ),
            ],
            onChanged: (v) => setState(() => _from = v ?? _from),
          ),
          const SizedBox(height: 6),
          const Text(
            'That month and every month after it open again. A financial year whose last '
            'month reopens has its year-end journal reversed.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'Why (kept in the history)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final reason = _reason.text.trim();
          if (reason.length < 3) {
            setState(() => _error = 'Give the reason.');
            return;
          }
          // Closed through the day before the first month reopened.
          final through = _from.from.subtract(const Duration(days: 1));
          final keep = widget.closed.any((m) => !m.from.isAfter(through));
          Navigator.pop(context, (keep ? through : null, reason));
        },
        child: const Text('Reopen'),
      ),
    ],
  );
}
