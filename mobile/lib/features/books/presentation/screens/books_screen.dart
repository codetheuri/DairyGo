import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// The books: whether they agree with the records, and the way to the trial
/// balance, journals, chart of accounts and where records post. Before the
/// books start, the accountant chooses the day they start from.
class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  static final _day = DateFormat('d MMM y');

  Future<DateTime?> _pickDay(BuildContext context, DateTime initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'The first day of the books',
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final day = await _pickDay(context, DateTime(now.year, now.month, 1));
    if (day == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start the books on ${_day.format(day)}?'),
        content: const Text(
          'Every record from that day posts its own journal. Everything '
          'recorded before it is added up into one opening journal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(booksServiceProvider).start(day);
      refreshBooks(ref);
      if (context.mounted) {
        showBooksDone(context, 'The books start on ${_day.format(day)}');
      }
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final day = await _pickDay(context, current);
    if (day == null || day == current || !context.mounted) return;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start on ${_day.format(day)} instead?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The journals from records are made again from the new day. '
                'Your own journals stay.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(booksServiceProvider).start(day, reason: reason.text);
      refreshBooks(ref);
      if (context.mounted) {
        showBooksDone(context, 'The books now start on ${_day.format(day)}');
      }
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  Future<void> _bringUpToDate(BuildContext context, WidgetRef ref) async {
    try {
      final (_, made) = await ref.read(booksServiceProvider).bringUpToDate();
      refreshBooks(ref);
      if (context.mounted) {
        showBooksDone(
          context,
          made == 0
              ? 'The books were already up to date'
              : made == 1
              ? '1 journal posted'
              : '$made journals posted',
        );
      }
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(booksStatusProvider);
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    final st = status.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Books',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canManage && (st?.started ?? false))
            PopupMenuButton<String>(
              tooltip: 'More about the books',
              onSelected: (v) => v == 'sync'
                  ? _bringUpToDate(context, ref)
                  : _move(context, ref, st!.startDate!),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'sync', child: Text('Bring up to date')),
                PopupMenuItem(value: 'move', child: Text('Move the start')),
              ],
            ),
        ],
      ),
      floatingActionButton: canManage && (st?.started ?? false)
          ? FloatingActionButton.extended(
              heroTag: 'new-journal',
              onPressed: () => context.push('/books/journals/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Journal'),
            )
          : null,
      body: status.when(
        loading: () => const ListSkeleton(rows: 5),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(booksStatusProvider),
        ),
        data: (st) => RefreshIndicator(
          onRefresh: () => ref.refresh(booksStatusProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              ReadableWidth(
                child: st.started
                    ? _Started(
                        status: st,
                        canManage: canManage,
                        onBringUpToDate: () => _bringUpToDate(context, ref),
                      )
                    : _NotStarted(
                        canManage: canManage,
                        onStart: () => _start(context, ref),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotStarted extends StatelessWidget {
  final bool canManage;
  final VoidCallback onStart;

  const _NotStarted({required this.canManage, required this.onStart});

  @override
  Widget build(BuildContext context) => BooksCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const Text(
            'The books have not started',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'The books are kept from what staff already record: every sale, '
            'payment, expense, advance and pay run posts its own journal. '
            'Choose the day they start; everything before it becomes one '
            'opening journal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (canManage)
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start the books'),
            )
          else
            const Text(
              'The accountant or a Sacco admin starts them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
        ],
      ),
    ),
  );
}

class _Started extends StatelessWidget {
  final BooksStatus status;
  final bool canManage;
  final VoidCallback onBringUpToDate;

  const _Started({
    required this.status,
    required this.canManage,
    required this.onBringUpToDate,
  });

  @override
  Widget build(BuildContext context) {
    final good = status.agrees && status.balanced;
    final wrong = status.controls.where((c) => !c.ok).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BooksCard(
          border: good ? AppColors.successContainer : AppColors.error,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      good
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      color: good ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        good
                            ? 'The books agree with the records'
                            : 'The books differ from the records',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  good
                      ? 'Debits equal credits, and customers, farmers, pay due '
                            'and every cash account match their records.'
                      : !status.balanced
                      ? 'Debits and credits are not equal.'
                      : 'A journal is missing or a record changed without one.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final c in wrong)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${c.name}: books ${thousands(c.books)}, '
                      'records ${thousands(c.records)} '
                      '(${c.difference > 0 ? '+' : ''}${thousands(c.difference)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (!good && canManage) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: onBringUpToDate,
                      child: const Text('Bring up to date'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (status.notInAccount.abs() >= 0.005) ...[
          const SizedBox(height: 10),
          BooksCard(
            child: ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.warning,
              ),
              title: Text(
                '${kes(status.notInAccount.abs(), cents: false)} not in any account',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Money recorded without naming the cash, bank or M-Pesa '
                'account. It sits in "Money not in an account".',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        BooksCard(
          child: Column(
            children: [
              _Tile(
                icon: Icons.trending_up_rounded,
                title: 'Income statement',
                subtitle: 'Income less expenses for a month or a year',
                path: '/books/income-statement',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.account_balance_outlined,
                title: 'Balance sheet',
                subtitle: 'What the Sacco owns and owes',
                path: '/books/balance-sheet',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.balance_rounded,
                title: 'Trial balance',
                subtitle: 'Every account\'s balance on a day',
                path: '/books/trial-balance',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.receipt_long_rounded,
                title: 'Journals',
                subtitle: 'Every entry, month by month',
                path: '/books/journals',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.account_tree_outlined,
                title: 'Chart of accounts',
                subtitle: 'Accounts and their balances',
                path: '/books/accounts',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.alt_route_rounded,
                title: 'Where records post',
                subtitle: 'The account each kind of record uses',
                path: '/books/links',
              ),
              const Divider(height: 1),
              _Tile(
                icon: Icons.download_rounded,
                title: 'Download',
                subtitle:
                    'Statements as PDF or Excel; journals and ledgers as Excel or CSV for other software',
                path: '/report-downloads',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          [
            'The books start on ${BooksScreen._day.format(status.startDate!)}',
            '${status.journals} journals',
            if (status.checkedAt != null)
              'checked ${DateFormat('d MMM, HH:mm').format(status.checkedAt!)}',
          ].join(' · '),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String path;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(path),
  );
}
